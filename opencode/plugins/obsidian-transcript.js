import { createHash } from "node:crypto"
import { existsSync } from "node:fs"
import { mkdir, readFile, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { basename, dirname, join } from "node:path"

const VAULT_DIR = process.env.OBSIDIAN_VAULT || join(homedir(), "Documents", "Lab Notebook")
const TRANSCRIPTS_SUBDIR = process.env.OPENCODE_TRANSCRIPT_SUBDIR || "Transcripts"
const WEEKLY_SUBDIR = process.env.OPENCODE_WEEKLY_SUBDIR || "Lab Notebook"

const inflight = new Set()
const sessionState = new Map()

const MIN_WRITE_INTERVAL_MS = 2000

const unwrap = (response) => response?.data ?? response

function cleanSessionID(value) {
  return String(value || "")
    .replace(/[^a-zA-Z0-9_-]/g, "")
    .slice(0, 16)
}

function isoWeek(date = new Date()) {
  const utc = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
  const day = utc.getUTCDay() || 7
  utc.setUTCDate(utc.getUTCDate() + 4 - day)
  const yearStart = new Date(Date.UTC(utc.getUTCFullYear(), 0, 1))
  const week = Math.ceil((((utc - yearStart) / 86400000) + 1) / 7)
  return { year: utc.getUTCFullYear(), week }
}

function currentWeekFilename(now = new Date()) {
  const { year, week } = isoWeek(now)
  return `${year}-W${String(week).padStart(2, "0")}.md`
}

function hhmm(now = new Date()) {
  const hours = String(now.getHours()).padStart(2, "0")
  const minutes = String(now.getMinutes()).padStart(2, "0")
  return `${hours}:${minutes}`
}

function getSessionID(event) {
  return event?.properties?.sessionID || event?.properties?.id || ""
}

function getBaseName(sessionID) {
  const existing = sessionState.get(sessionID)
  if (existing?.baseName) return existing.baseName

  const day = new Date().toISOString().slice(0, 10)
  const shortID = cleanSessionID(sessionID) || "unknown"
  const baseName = `${day}-session-${shortID}`
  sessionState.set(sessionID, { ...existing, baseName })
  return baseName
}

function messageRole(message) {
  return String(message?.info?.role || message?.info?.type || "unknown").toLowerCase()
}

function partToMarkdown(part) {
  if (!part || typeof part !== "object") return String(part || "")
  if (typeof part.text === "string" && part.text.trim()) return part.text.trim()

  if (part.type === "tool") {
    const title = part.title || part.name || "tool"
    const payload = {
      callID: part.callID,
      args: part.args,
      output: part.output,
      metadata: part.metadata,
    }
    return `**Tool: ${title}**\n\n\`\`\`json\n${JSON.stringify(payload, null, 2)}\n\`\`\``
  }

  return `\`\`\`json\n${JSON.stringify(part, null, 2)}\n\`\`\``
}

function renderMessage(message) {
  const role = messageRole(message)
  const parts = Array.isArray(message?.parts) ? message.parts : []
  const body = parts.map(partToMarkdown).filter(Boolean).join("\n\n").trim()

  if (!body) return ""

  if (role === "user") return `## User\n\n${body}`
  if (role === "assistant") return `## Assistant\n\n${body}`
  return `## ${role}\n\n${body}`
}

function renderMarkdown(messages, sessionID, jsonlName) {
  const sections = []
  for (const message of messages) {
    const section = renderMessage(message)
    if (section) sections.push(section)
  }

  const front = [
    "# Session Transcript",
    "",
    `*Exported: ${new Date().toISOString().replace("T", " ").slice(0, 16)}*`,
    "",
    `Session ID: \`${sessionID}\``,
    "",
    `Raw transcript: [[${TRANSCRIPTS_SUBDIR}/${jsonlName}]]`,
    "",
    "---",
    "",
  ].join("\n")

  if (sections.length === 0) return `${front}_(No transcript content yet)_\n`
  return `${front}${sections.join("\n\n---\n\n")}\n`
}

function insertSessionLink(content, linkLine) {
  const lines = content.split("\n")
  const sessionsIndex = lines.findIndex((line) => line.trim() === "## Sessions")

  if (sessionsIndex < 0) {
    const trimmed = content.replace(/\s*$/, "")
    return `${trimmed}\n\n## Sessions\n\n${linkLine}\n`
  }

  let insertAt = lines.length
  for (let i = sessionsIndex + 1; i < lines.length; i += 1) {
    if (/^##\s+/.test(lines[i])) {
      insertAt = i
      break
    }
  }

  const updated = [...lines.slice(0, insertAt), linkLine, ...lines.slice(insertAt)]
  return `${updated.join("\n").replace(/\s*$/, "")}\n`
}

async function appendWeeklyLink(sessionID, baseName) {
  const weeklyPath = join(VAULT_DIR, WEEKLY_SUBDIR, currentWeekFilename())
  const marker = `(opencode:${sessionID})`
  const linkLine = `- [[${TRANSCRIPTS_SUBDIR}/${baseName}]] - ${hhmm()} ${marker}`

  await mkdir(dirname(weeklyPath), { recursive: true })

  if (!existsSync(weeklyPath)) {
    const initial = `# ${basename(weeklyPath, ".md")}\n\n## Sessions\n\n${linkLine}\n`
    await writeFile(weeklyPath, initial, "utf8")
    return
  }

  const content = await readFile(weeklyPath, "utf8")
  if (content.includes(marker) || content.includes(`[[${TRANSCRIPTS_SUBDIR}/${baseName}]]`)) return

  const updated = insertSessionLink(content, linkLine)
  await writeFile(weeklyPath, updated, "utf8")
}

function shouldSkipWrite(sessionID) {
  const state = sessionState.get(sessionID)
  if (!state?.lastSavedAt) return false
  return Date.now() - state.lastSavedAt < MIN_WRITE_INTERVAL_MS
}

function updateSessionState(sessionID, next) {
  const current = sessionState.get(sessionID) || {}
  sessionState.set(sessionID, { ...current, ...next })
}

async function saveTranscript({ client, project, directory, sessionID }) {
  const result = unwrap(await client.session.messages({ path: { id: sessionID } }))
  const messages = Array.isArray(result) ? result : []
  if (messages.length === 0) return

  const baseName = getBaseName(sessionID)
  const jsonlName = `${baseName}.jsonl`
  const mdName = `${baseName}.md`

  const transcriptsDir = join(VAULT_DIR, TRANSCRIPTS_SUBDIR)
  await mkdir(transcriptsDir, { recursive: true })

  const rawDump = messages.map((entry) => JSON.stringify(entry)).join("\n") + "\n"
  const digest = createHash("sha1").update(rawDump).digest("hex")
  const previousDigest = sessionState.get(sessionID)?.digest
  const linked = sessionState.get(sessionID)?.weeklyLinked

  if (digest === previousDigest && linked) return

  const markdown = renderMarkdown(messages, sessionID, jsonlName)
  await writeFile(join(transcriptsDir, jsonlName), rawDump, "utf8")
  await writeFile(join(transcriptsDir, mdName), markdown, "utf8")
  await appendWeeklyLink(sessionID, baseName)

  updateSessionState(sessionID, {
    digest,
    weeklyLinked: true,
    lastSavedAt: Date.now(),
    projectName: project?.name,
    directory,
  })
}

export const ObsidianTranscriptPlugin = async ({ client, project, directory }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle" && event.type !== "session.compacted") return

    const sessionID = getSessionID(event)
    if (!sessionID) return
    if (inflight.has(sessionID)) return
    if (shouldSkipWrite(sessionID)) return

    inflight.add(sessionID)
    try {
      await saveTranscript({ client, project, directory, sessionID })
    } catch (error) {
      try {
        await client.app.log({
          body: {
            service: "obsidian-transcript",
            level: "warn",
            message: "failed to save transcript",
            extra: {
              sessionID,
              error: error instanceof Error ? error.message : String(error),
            },
          },
        })
      } catch {
        // ignore logging failures
      }
    } finally {
      inflight.delete(sessionID)
    }
  },
})

export default ObsidianTranscriptPlugin
