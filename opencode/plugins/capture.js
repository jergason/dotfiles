// ai-sessions capture plugin for opencode.
//
// Replaces obsidian-transcript.js. The old plugin wrote THREE things per session — a raw
// .jsonl, a rendered .md, and a link line in the Obsidian weekly note — duplicating the
// claude-side python exporter and drifting from it (see PLAN.md §1). This slimmed version
// is capture-only: on session.idle / session.compacted it fetches the session's messages
// and writes ONE raw .jsonl dump into the shared archive dir. No markdown, no weekly note.
//
// The markdown projection now lives in the database query layer (`ai-sessions show`), so the
// plugin's sole job is to land raw truth on disk — opencode keeps nothing parseable itself
// (its messages live behind the running server's `client.session.messages` API), so this is
// the only thing that materializes them for long-term history.
//
// Output: <dataDir>/raw/opencode/<session-id>.<capture-ts>.jsonl
//   - dataDir resolves exactly like src/paths.ts:
//       process.env.AI_SESSIONS_DIR || ~/.local/share/ai-sessions
//   - versioned filename (capture timestamp in the name) → non-destructive, matching the
//     claude side. Ingest dedups on `uid`, so multiple capture files for one session
//     converge to one event set rather than clobbering each other.
//   - each line is a message object EXACTLY as returned by client.session.messages
//     ({ info: {...}, parts: [...] }), written verbatim — the opencode adapter
//     (src/adapters/opencode.ts) reads that shape directly, so do NOT reshape it.
//
// Dependency-free: Node/Bun builtins only (fs, path, os, crypto). Same plugin export/hook
// signature as the file it replaces.
//
// Ingest: intentionally NOT fired from here. The plugin runs inside opencode's runtime;
// shelling out to `bun ai-sessions ingest` from that context is fragile (cwd, PATH, bun
// resolution). Ingest is left to the periodic launchd/cron job (see docs/deploy.md, PLAN.md
// §9 Q3). Capture stays a dumb, never-failing copy; ingest is a separate idempotent rescan.

import { createHash } from "node:crypto"
import { mkdir, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

// Mirror src/paths.ts so capture and ingest agree on the layout without reimplementing it.
const DATA_DIR = process.env.AI_SESSIONS_DIR || join(homedir(), ".local", "share", "ai-sessions")
const RAW_OPENCODE_DIR = join(DATA_DIR, "raw", "opencode")

// Guard against concurrent saves of the same session, and remember the last digest written
// so an unchanged session (idle fired again with no new messages) isn't rewritten.
const inflight = new Set()
const lastDigest = new Map()

const unwrap = (response) => response?.data ?? response

function getSessionID(event) {
  return event?.properties?.sessionID || event?.properties?.id || ""
}

// Versioned capture filename: <session-id>.<capture-ts>.jsonl. Colons/dots in the ISO stamp
// are illegal-ish in filenames, so strip them — matches src/paths.ts captureFilename().
function captureFilename(sessionID, captureTs = new Date()) {
  const stamp = captureTs.toISOString().replace(/[:.]/g, "-")
  return `${sessionID}.${stamp}.jsonl`
}

async function saveTranscript({ client, sessionID }) {
  const result = unwrap(await client.session.messages({ path: { id: sessionID } }))
  const messages = Array.isArray(result) ? result : []
  if (messages.length === 0) return

  // Write each message object verbatim, one JSON per line — exactly the shape the opencode
  // adapter expects. No projection, no field reshaping.
  const rawDump = messages.map((entry) => JSON.stringify(entry)).join("\n") + "\n"

  // Digest-based skip: if the serialized messages are byte-identical to the last write for
  // this session, there is nothing new to capture. (sha1 is fine here — collision-resistance
  // isn't the property we need, change-detection is.)
  const digest = createHash("sha1").update(rawDump).digest("hex")
  if (lastDigest.get(sessionID) === digest) return

  await mkdir(RAW_OPENCODE_DIR, { recursive: true })
  await writeFile(join(RAW_OPENCODE_DIR, captureFilename(sessionID)), rawDump, "utf8")

  lastDigest.set(sessionID, digest)
}

export const AiSessionsCapturePlugin = async ({ client }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle" && event.type !== "session.compacted") return

    const sessionID = getSessionID(event)
    if (!sessionID) return
    if (inflight.has(sessionID)) return

    inflight.add(sessionID)
    try {
      await saveTranscript({ client, sessionID })
    } catch (error) {
      // A capture failure must never break the user's opencode session. Log best-effort.
      try {
        await client.app.log({
          body: {
            service: "ai-sessions-capture",
            level: "warn",
            message: "failed to capture transcript",
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

export default AiSessionsCapturePlugin
