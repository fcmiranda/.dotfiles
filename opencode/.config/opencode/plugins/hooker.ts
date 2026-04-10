import type { Plugin } from "@opencode-ai/plugin"

/**
 * Plugin that:
 * - Updates the tmux @opencode_state user option with a styled indicator on every session state change
 * - Sends desktop notifications for idle / question / permission events
 */
export const NotifyIdlePlugin: Plugin = async ({ $ }) => {
  // $TMUX_PANE is inherited from the shell that launched opencode (e.g. "%3").
  const tmuxPane = process.env.TMUX_PANE ?? ""

  // Resolve the window ID once at startup so the state file is window-scoped.
  // tmux window options (set -w) inherit across new windows; a plain file keyed
  // by window_id does not — each window gets its own clean slate.
  let stateFile = ""
  if (tmuxPane) {
    try {
      const { execSync } = require("node:child_process")
      const windowId = execSync(`tmux display-message -p -t '${tmuxPane}' '#{window_id}'`).toString().trim()
      stateFile = `/tmp/opencode-state-${windowId.replace(/[^a-zA-Z0-9@_-]/g, "")}`
      // Wipe any stale global @opencode_state from old plugin versions
      execSync(`tmux set -g @opencode_state "" 2>/dev/null || true`)
    } catch {}
  }

  const writeState = (state: string) => {
    if (!stateFile) return
    try {
      require("node:fs").writeFileSync(stateFile, state)
      // One refresh so non-busy state changes (idle, permission) appear immediately
      require("node:child_process").execSync("tmux refresh-client -S")
    } catch {}
  }

  const setAppState = (state: string) => writeState(state)

  const clearTmuxState = () => {
    if (!stateFile) return
    try {
      require("node:fs").unlinkSync(stateFile)
      require("node:child_process").execSync("tmux refresh-client -S")
    } catch {}
  }
  process.on("exit", clearTmuxState)
  process.on("SIGINT",  () => { clearTmuxState(); process.exit(0) })
  process.on("SIGTERM", () => { clearTmuxState(); process.exit(0) })

  return {
    "event": async ({ event }) => {
      if ((event as any).type !== "session.status") return

      const properties = (event as any)?.properties
      const statusType: string = properties?.status?.type ?? "unknown"

      // Write to a debug file to confirm callback runs
      try {
        const fs = await import("node:fs")
        fs.appendFileSync("/tmp/opencode-plugin-debug.log", `session.status: ${statusType}\n`)
      } catch {}

      // Reflect state in tmux status bar
      setAppState(statusType)

      // Desktop notifications
      // SessionStatus.type values: "idle" | "busy" | "retry"
      const statusMessages: Record<string, { title: string; body: string; urgency: string }> = {
        idle: { title: "OpenCode Finished", body: "The AI has finished processing your prompt", urgency: "normal" },
      }

      const msg = statusMessages[statusType]
      if (msg) {
        try {
          // Note: do NOT wrap template expressions in quotes — bun's $ handles escaping
          await $`notify-send ${msg.title} ${msg.body} -u ${msg.urgency}`
        } catch (err) {
          try {
            const fs = await import("node:fs")
            fs.appendFileSync("/tmp/opencode-plugin-debug.log", `notify-send error: ${err}\n`)
          } catch {}
        }
      }
    },

    "tool.execute.before": async (input) => {
      const toolName = (input as Record<string, any>)?.tool ?? "tool"
      // Mark as busy whenever a tool runs
      setAppState("busy")
      if (toolName === "question") {
        try {
          await $`notify-send "OpenCode Needs Attention" "The AI has a question for you" -u critical`
        } catch (err) {
          console.error("NotifyIdlePlugin: notify-send for question failed", err)
        }
      }
    },

    "permission.ask": async (input) => {
      const tool = (input as Record<string, any>)?.tool ?? "unknown tool"
      // Use the permission style (red alert) so it's visible in the status bar
      setAppState("permission")
      try {
        await $`notify-send "OpenCode Needs Attention" ${`Permission needed for tool: ${tool}`} -u critical`
      } catch (err) {
        console.error("NotifyIdlePlugin: notify-send for permission failed", err)
      }
    },
  }
}
