import type { Plugin } from "@opencode-ai/plugin"

/**
 * Plugin that:
 * - Updates the tmux @opencode_state user option with a styled indicator on every session state change
 * - Sends desktop notifications for idle / question / permission events
 */
export const NotifyIdlePlugin: Plugin = async ({ $ }) => {
  // $TMUX_PANE is inherited from the shell that launched opencode (e.g. "%3").
  // set-option -w scopes the value to that specific window, so multiple windows
  // each track their own opencode instance independently.
  const tmuxPane = process.env.TMUX_PANE ?? ""

  // Wipe out any stale global @opencode_state left by old plugin versions
  // (old code used `set -g` which all windows inherit). Doing this on startup
  // ensures new windows always get an empty fallback without needing a tmux reload.
  try { await $`tmux set -g @opencode_state ""` } catch {}

  const setTmuxRaw = (value: string) => {
    if (!tmuxPane) return
    try {
      const { execSync } = require("node:child_process")
      // Single subprocess: both commands in one shell invocation
      execSync(`tmux set-option -w -t '${tmuxPane}' @opencode_state '${value}' ; tmux refresh-client -S`)
    } catch {}
  }

  // Spinner animation for the busy state (ora-style braille dots, ~200ms per frame)
  const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  let spinnerFrame = 0
  let spinnerTimer: ReturnType<typeof setInterval> | null = null

  const startSpinner = () => {
    if (spinnerTimer) return
    spinnerTimer = setInterval(() => {
      const frame = spinnerFrames[spinnerFrame % spinnerFrames.length]
      spinnerFrame++
      setTmuxRaw(`#[fg=yellow]${frame} #[fg=default]`)
    }, 200)
  }

  const stopSpinner = () => {
    if (!spinnerTimer) return
    clearInterval(spinnerTimer)
    spinnerTimer = null
    spinnerFrame = 0
  }

  // Static tmux inline-style strings for non-animated states.
  const tmuxStates: Record<string, string> = {
    idle:       "#[fg=green] #[fg=default]",
    retry:      "#[fg=colour208] #[fg=default]",
    permission: "#[fg=red] #[fg=default]",
  }

  const setAppState = (state: string) => {
    if (state === "busy") {
      startSpinner()
    } else {
      stopSpinner()
      setTmuxRaw(tmuxStates[state] ?? "")
    }
  }

  // Clear the window option when this opencode process exits so windows that
  // are no longer running opencode show an empty state in the tab label.
  const clearTmuxState = () => {
    stopSpinner()
    if (!tmuxPane) return
    try {
      const { execSync } = require("child_process")
      execSync(`tmux set-option -w -t ${tmuxPane} -u @opencode_state`)
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
