import { existsSync } from "node:fs"
import { spawn } from "node:child_process"
import { homedir } from "node:os"

const encoder = new TextEncoder()
const debounceByKey = new Map()

const TMUX_NOTIFY_PATH = process.env.OPENCODE_TMUX_NOTIFY || `${process.env.HOME || homedir()}/bin/tmux-notify`

const DEFAULT_DEBOUNCE_MS = 1200

function shouldDebounce(key, windowMs = DEFAULT_DEBOUNCE_MS) {
  const now = Date.now()
  const last = debounceByKey.get(key)

  if (typeof last === "number" && now - last < windowMs) {
    return true
  }

  debounceByKey.set(key, now)

  if (debounceByKey.size > 200) {
    const cutoff = now - 10 * 60 * 1000
    for (const [entryKey, timestamp] of debounceByKey.entries()) {
      if (timestamp < cutoff) debounceByKey.delete(entryKey)
    }
  }

  return false
}

async function tmuxNotify(payload, args = ["--type", "notify"]) {
  if (!TMUX_NOTIFY_PATH || !existsSync(TMUX_NOTIFY_PATH)) return

  await new Promise((resolve) => {
    try {
      const child = spawn(TMUX_NOTIFY_PATH, args, {
        stdio: ["pipe", "ignore", "ignore"],
      })

      child.on("error", () => resolve())
      child.on("close", () => resolve())

      if (child.stdin) {
        child.stdin.write(encoder.encode(JSON.stringify(payload)))
        child.stdin.end()
      }
    } catch {
      resolve()
    }
  })
}

function messageFromError(error) {
  if (!error) return "session error"
  if (typeof error?.data?.message === "string" && error.data.message.length > 0) {
    return error.data.message
  }
  if (typeof error?.name === "string" && error.name.length > 0) {
    return error.name
  }
  return "session error"
}

export const TmuxNotifyPlugin = async ({ directory }) => {
  const cwd = directory || process.cwd()
  const tmuxPane = process.env.TMUX_PANE || ""

  return {
    event: async ({ event }) => {
      if (event.type === "session.status" && event.properties.status.type === "busy") {
        if (shouldDebounce(`busy:${event.properties.sessionID}`, 500)) return
        await tmuxNotify({ cwd, tmux_pane: tmuxPane }, ["--clear"])
        return
      }

      if (event.type === "session.idle") {
        if (shouldDebounce(`idle:${event.properties.sessionID}`, 1500)) return
        await tmuxNotify({
          cwd,
          tmux_pane: tmuxPane,
          title: "OpenCode",
          message: "response complete",
          notification_type: "session_complete",
        })
        return
      }

      if (event.type === "session.error") {
        if (shouldDebounce(`error:${event.properties.sessionID || "unknown"}`, 1500)) return
        await tmuxNotify({
          cwd,
          tmux_pane: tmuxPane,
          title: "OpenCode Error",
          message: messageFromError(event.properties.error),
          notification_type: "session_error",
        })
        return
      }

      if (event.type === "permission.asked") {
        if (shouldDebounce(`permission:event:${event.properties.sessionID}:${event.properties.type}`, 1200)) return

        const pattern = Array.isArray(event.properties.pattern)
          ? event.properties.pattern.join(", ")
          : event.properties.pattern
        const base = event.properties.title || "permission requested"
        const message = pattern ? `${base}: ${pattern}` : base

        await tmuxNotify({
          cwd,
          tmux_pane: tmuxPane,
          title: "Approval Needed",
          message,
          notification_type: "permission_prompt",
        })
      }
    },

    "permission.ask": async (input) => {
      if (shouldDebounce(`permission:${input.sessionID}:${input.type}`, 1200)) return

      const pattern = Array.isArray(input.pattern) ? input.pattern.join(", ") : input.pattern
      const base = input.title || "permission requested"
      const message = pattern ? `${base}: ${pattern}` : base

      await tmuxNotify({
        cwd,
        tmux_pane: tmuxPane,
        title: "Approval Needed",
        message,
        notification_type: "permission_prompt",
      })
    },

    "tool.execute.before": async (input) => {
      if (input.tool !== "question") return
      if (shouldDebounce(`question:${input.sessionID}`, 1500)) return

      await tmuxNotify({
        cwd,
        tmux_pane: tmuxPane,
        title: "OpenCode Question",
        message: "agent is waiting for your input",
        notification_type: "elicitation_dialog",
      })
    },
  }
}

export default TmuxNotifyPlugin
