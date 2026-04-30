
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

  // ── Watchdog process ──────────────────────────────────────────────────────
  // Spawns a detached shell that polls until this plugin PID dies, then clears
  // the tmux state. Catches all exit types including SIGKILL (which Node.js
  // process.on() handlers cannot intercept).
  if (tmuxPane) {
    const { spawn } = require("node:child_process")
    const watchdog = spawn("sh", [
      "-c",
      `while kill -0 ${process.pid} 2>/dev/null; do sleep 1; done; tmux set-option -w -t '${tmuxPane}' -u @opencode_state 2>/dev/null; tmux set-option -w -t '${tmuxPane}' -u @opencode_state_raw 2>/dev/null; tmux refresh-client -S 2>/dev/null`,
    ], { detached: true, stdio: "ignore" })
    watchdog.unref()
  }
  // ─────────────────────────────────────────────────────────────────────────

  const setWindowState = (value: string, raw: string) => {
    if (!tmuxPane) return
    // set-option + refresh-client in a single tmux process via ";" separator
    // @opencode_state      — styled tmux format string for the status bar
    // @opencode_state_raw  — plain word (busy/idle/question/permission) for scripts
    tmux("set-option", "-w", "-t", tmuxPane, "@opencode_state", value,
         ";", "set-option", "-w", "-t", tmuxPane, "@opencode_state_raw", raw,
         ";", "refresh-client", "-S")
  }

  // ── Spinner catalogue ────────────────────────────────────────────────────
  const SPINNERS: Record<string, { frames: string[]; interval: number }> = {
    minidot:   { frames: ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"], interval: 83  },
    dot:       { frames: ["⣾ ","⣽ ","⣻ ","⢿ ","⡿ ","⣟ ","⣯ ","⣷ "],  interval: 100 },
    line:      { frames: ["|","/","-","\\"],                            interval: 100 },
    jump:      { frames: ["⢄","⢂","⢁","⡁","⡈","⡐","⡠"],              interval: 100 },
    pulse:     { frames: ["█","▓","▒","░"],                              interval: 125 },
    points:    { frames: ["∙∙∙","●∙∙","∙●∙","∙∙●"],                    interval: 143 },
    meter:     { frames: ["▱▱▱","▰▱▱","▰▰▱","▰▰▰","▰▰▱","▰▱▱","▱▱▱"], interval: 143 },
    hamburger: { frames: ["☱","☲","☴","☲"],                             interval: 333 },
    ellipsis:  { frames: ["",".","..","."],                              interval: 333 },
    globe:     { frames: ["🌍","🌎","🌏"],                               interval: 250 },
    moon:      { frames: ["🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"],     interval: 125 },
    monkey:    { frames: ["🙈","🙉","🙊"],                               interval: 333 },
    arc:       { frames: ["◜","◠","◝","◞","◡","◟"],                     interval: 150 },
    nerd:      { frames: ["","","","","",""],                  interval: 100 },
    nerdarc:   { frames: ["◜","","◝","◞","◡","◟",""],  interval: 120 },
  }

  // ── Spinner resolution: env var > config file > default ─────────────────
  // Set at launch:          OPENCODE_SPINNER=moon opencode
  // Or in config file:      ~/.config/opencode/hooker-config.json
  //   { "spinner": "moon" }
  //   { "spinner": "minidot", "interval": 80 }
  const DEFAULT_SPINNER = "arc"
  let spinnerName = process.env.OPENCODE_SPINNER ?? DEFAULT_SPINNER
  let intervalOverride: number | null = null

  try {
    const fs = require("node:fs")
    const configPath = `${process.env.HOME}/.config/opencode/hooker-config.json`
    if (fs.existsSync(configPath)) {
      const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"))
      if (!process.env.OPENCODE_SPINNER && cfg.spinner) spinnerName = cfg.spinner
      if (typeof cfg.interval === "number") intervalOverride = cfg.interval
    }
  } catch {}

  const chosen = SPINNERS[spinnerName] ?? SPINNERS[DEFAULT_SPINNER]
  const SPINNER = chosen.frames
  const SPINNER_INTERVAL = intervalOverride ?? chosen.interval
  // ─────────────────────────────────────────────────────────────────────────
  let spinnerFrame = 0
  let spinnerTimer: ReturnType<typeof setInterval> | null = null
  let waitingPermission = false

  const startSpinner = () => {
    if (spinnerTimer) return
    spinnerTimer = setInterval(() => {
      const frame = SPINNER[spinnerFrame++ % SPINNER.length]
      setWindowState(`#[fg=yellow]${frame} #[fg=default]`, "busy")
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
      setWindowState(STATES[state] ?? "", state)
    }
  }

  // Resolve session and window name for this pane once at startup
  const tmuxSession = tmuxPane
    ? (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#S"], { encoding: "utf8" }).stdout ?? "").trim()
    : ""
  const tmuxWindow = tmuxPane
    ? (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#W"], { encoding: "utf8" }).stdout ?? "").trim()
    : ""
  const tmuxWindowIndex = tmuxPane
    ? (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#I"], { encoding: "utf8" }).stdout ?? "").trim()
    : ""
  const tmuxWindowId = tmuxPane
    ? (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#{window_id}"], { encoding: "utf8" }).stdout ?? "").trim()
    : ""

  // Updates the tmux status-right bell segment without stealing focus.
  // Stores the source pane in @opencode_last_bell so prefix+i can jump to it.
  // Clears automatically after 7 seconds via a detached background process.
  // Only fires for clients NOT already viewing the opencode window.
  const bell = (action: string, force = false) => {
    if (!tmuxPane) return
    if (!force) {
      const anyOtherClient = (spawnSync("tmux", ["list-clients", "-F", "#{client_session} #{window_id}"], { encoding: "utf8" }).stdout ?? "")
        .trim().split("\n").filter(Boolean)
        .some(line => {
          const [cs, wid] = line.split(" ")
          return !(cs === tmuxSession && wid === tmuxWindowId)
        })
      if (!anyOtherClient) return
    }

    // Store the source pane so prefix+i can navigate to it
    tmux("set", "-g", "@opencode_last_bell", tmuxPane)
    // Write the bell message to the status-right segment variable
    const msg = `  #[fg=cyan]${tmuxWindowIndex}:${tmuxWindow} › ${action} #[fg=yellow](i)#[fg=default]`
    tmux("set", "-g", "@opencode_bell", msg, ";", "refresh-client", "-S")
    // Clear after 7 seconds via a detached background process
    const { spawn } = require("node:child_process")
    const cleaner = spawn("sh", ["-c",
      `sleep 7 && tmux set -g @opencode_bell '' && tmux refresh-client -S`
    ], { detached: true, stdio: "ignore" })
    cleaner.unref()
  }

  const clearTmuxState = () => {
    stopSpinner()
    if (!tmuxPane) return
    tmux("set-option", "-w", "-t", tmuxPane, "-u", "@opencode_state",
         ";", "set-option", "-w", "-t", tmuxPane, "-u", "@opencode_state_raw",
         ";", "refresh-client", "-S")
  }
  process.on("exit",   clearTmuxState)
  process.on("SIGINT",  () => { clearTmuxState(); process.exit(0) })
  process.on("SIGTERM", () => { clearTmuxState(); process.exit(0) })
  process.on("SIGHUP",  () => { clearTmuxState(); process.exit(0) })

  return {
    "event": async ({ event }) => {
      // Debug: capture all event types and key fields so we can map permission prompts reliably.
      try {
        const fs = await import("node:fs")
        const evtType = (event as any)?.type ?? "unknown"
        const statusType = (event as any)?.properties?.status?.type ?? ""
        fs.appendFileSync(
          "/tmp/opencode-plugin-debug.log",
          `event: ${evtType}${statusType ? ` status=${statusType}` : ""}\n`,
        )
      } catch {}

      const evtType = (event as any)?.type ?? "unknown"

      if (evtType === "permission.asked") {
        waitingPermission = true
        setAppState("permission")
        bell("󱅭 permission", true)
        return
      }

      if (evtType === "permission.replied") {
        waitingPermission = false
        return
      }

      if (evtType !== "session.status") return

      const properties = (event as any)?.properties
      const statusType: string = properties?.status?.type ?? "unknown"

      // Write to a debug file to confirm callback runs
      try {
        const fs = await import("node:fs")
        fs.appendFileSync("/tmp/opencode-plugin-debug.log", `session.status: ${statusType}\n`)
      } catch {}

      // Reflect state in tmux status bar
      // Keep permission indicator visible while waiting for user reply.
      if (waitingPermission && statusType === "busy") return
      setAppState(statusType)

      if (statusType === "idle") bell("󱥂 finished")

      // Desktop notifications
      // SessionStatus.type values: "idle" | "busy" | "retry"
      const statusMessages: Record<string, { title: string; body: string; urgency: string }> = {
        idle: { title: "OpenCode Finished", body: "The AI has finished processing your prompt", urgency: "normal" },
      }

      const msg = statusMessages[statusType]
      if (msg) {
        try {
          // Note: do NOT wrap template expressions in quotes — bun's $ handles escaping
         // await $`notify-send ${msg.title} ${msg.body} -u ${msg.urgency}`
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
      try {
        const fs = await import("node:fs")
        fs.appendFileSync("/tmp/opencode-plugin-debug.log", `tool.execute.before: ${toolName}\n`)
      } catch {}
      if (toolName === "question") {
        // Switch to the question icon so the tab signals it needs attention
        setAppState("question")
        bell("󱜻 question", true)
        try {
         // await $`notify-send "OpenCode Needs Attention" "The AI has a question for you" -u critical`
        } catch (err) {
          console.error("NotifyIdlePlugin: notify-send for question failed", err)
        }
      } else {
        setAppState("busy")
      }
    },

    "permission.ask": async (input) => {
      const tool = (input as Record<string, any>)?.tool ?? "unknown tool"
      try {
        const fs = await import("node:fs")
        fs.appendFileSync("/tmp/opencode-plugin-debug.log", `permission.ask: ${tool}\n`)
      } catch {}
      // Use the permission style (red alert) so it's visible in the status bar
      setAppState("permission")
      bell("󱅭 permission", true)
      try {
        // await $`notify-send "OpenCode Needs Attention" ${`Permission needed for tool: ${tool}`} -u critical`
      } catch (err) {
        console.error("NotifyIdlePlugin: notify-send for permission failed", err)
      }
    },

    // Newer OpenCode builds emit permission.asked (not permission.ask)
    "permission.asked": async (input) => {
      const tool = (input as Record<string, any>)?.tool ?? "unknown tool"
      try {
        const fs = await import("node:fs")
        fs.appendFileSync("/tmp/opencode-plugin-debug.log", `permission.asked: ${tool}\n`)
      } catch {}
      // Use the permission style (red alert) so it's visible in the status bar
      setAppState("permission")
      bell("󱅭 permission", true)
      try {
        // await $`notify-send "OpenCode Needs Attention" ${`Permission needed for tool: ${tool}`} -u critical`
      } catch (err) {
        console.error("NotifyIdlePlugin: notify-send for permission failed", err)
      }
    },
  }
}
