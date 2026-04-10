import type { Plugin } from "@opencode-ai/plugin"

/**
 * Plugin that:
 * - Updates the tmux @opencode_state user option with a styled indicator on every session state change
 * - Sends desktop notifications for idle / question / permission events
 */
export const NotifyIdlePlugin: Plugin = async ({ $ }) => {
  // $TMUX_PANE is inherited from the shell that launched opencode (e.g. "%3").
  const tmuxPane = process.env.TMUX_PANE ?? ""

  // spawnSync calls the tmux binary directly — no shell fork, no string parsing overhead.
  // Two tmux commands are chained with ";" in one process invocation.
  const { spawnSync } = require("node:child_process")
  const tmux = (...args: string[]) => spawnSync("tmux", args, { stdio: "ignore" })

  // Wipe stale global @opencode_state from old plugin versions once at startup
  if (tmuxPane) tmux("set", "-g", "@opencode_state", "")

  const setWindowState = (value: string) => {
    if (!tmuxPane) return
    // set-option + refresh-client in a single tmux process via ";" separator
    tmux("set-option", "-w", "-t", tmuxPane, "@opencode_state", value,
         ";", "refresh-client", "-S")
  }

  // ── Spinner sets (uncomment one) ──────────────────────────────────────────
  // Braille dots  — 10 frames, classic feel
  // const SPINNER = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]

  // Arc sweep     — 6 frames, smooth
  // const SPINNER = ["◜","◠","◝","◞","◡","◟"] 
  const SPINNER = ["","","","","",""]
  

  // Quarter fills — 4 frames, bold, good at any speed
  // const SPINNER = ["◐","◓","◑","◒"]

  // Box corners   — 4 frames, minimal
  // const SPINNER = ["▖","▘","▝","▗"]

  // Vertical bars — 8 frames
  // const SPINNER = ["▁","▂","▃","▄","▅","▆","▇","█"]
  // ─────────────────────────────────────────────────────────────────────────

  const SPINNER_INTERVAL = 150  // ms — adjust if too fast/slow
  let spinnerFrame = 0
  let spinnerTimer: ReturnType<typeof setInterval> | null = null

  const startSpinner = () => {
    if (spinnerTimer) return
    spinnerTimer = setInterval(() => {
      const frame = SPINNER[spinnerFrame++ % SPINNER.length]
      setWindowState(`#[fg=yellow]${frame} #[fg=default]`)
    }, SPINNER_INTERVAL)
  }

  const stopSpinner = () => {
    if (!spinnerTimer) return
    clearInterval(spinnerTimer)
    spinnerTimer = null
    spinnerFrame = 0
  }

  const STATES: Record<string, string> = {
    idle:       "#[fg=green]󱥂 #[fg=default]",   // done — green robot answered
    question:   "#[fg=cyan]󱜻 #[fg=default]",   // waiting for answer — cyan bell
    retry:      "#[fg=colour208]󰨄 #[fg=default]",  // retrying — orange refresh
    permission: "#[fg=red]󱅭 #[fg=default]",    // needs permission — red alert
  }

  const setAppState = (state: string) => {
    if (state === "busy") {
      startSpinner()
    } else {
      stopSpinner()
      setWindowState(STATES[state] ?? "")
    }
  }

  const clearTmuxState = () => {
    stopSpinner()
    if (!tmuxPane) return
    tmux("set-option", "-w", "-t", tmuxPane, "-u", "@opencode_state",
         ";", "refresh-client", "-S")
  }
  process.on("exit",   clearTmuxState)
  process.on("SIGINT",  () => { clearTmuxState(); process.exit(0) })
  process.on("SIGTERM", () => { clearTmuxState(); process.exit(0) })
  process.on("SIGHUP",  () => { clearTmuxState(); process.exit(0) })

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
      if (toolName === "question") {
        // Switch to the question icon so the tab signals it needs attention
        setAppState("question")
        try {
          await $`notify-send "OpenCode Needs Attention" "The AI has a question for you" -u critical`
        } catch (err) {
          console.error("NotifyIdlePlugin: notify-send for question failed", err)
        }
      } else {
        setAppState("busy")
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
