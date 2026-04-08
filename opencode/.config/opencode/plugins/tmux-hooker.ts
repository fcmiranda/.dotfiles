import type { Plugin } from "@opencode-ai/plugin"

/**
 * opencode-tmux-hooker
 *
 * Sends OpenCode events to the active tmux pane via display-message and
 * optional visual/audible alerts so you always know what the AI is doing.
 *
 * Configurable via environment variables:
 *   OPENCODE_TMUX_HOOK_PANE        - target pane (default: current pane "")
 *   OPENCODE_TMUX_HOOK_BELL        - send tmux bell on attention events (default: "1")
 *   OPENCODE_TMUX_HOOK_STATUS_BAR  - update tmux status-right with current state (default: "1")
 *   OPENCODE_TMUX_HOOK_DURATION    - how long (ms) display-message stays (default: "3000")
 */

// ─── helpers ──────────────────────────────────────────────────────────────────

const PANE = process.env.OPENCODE_TMUX_HOOK_PANE ?? ""
const BELL = (process.env.OPENCODE_TMUX_HOOK_BELL ?? "1") !== "0"
const STATUS_BAR = (process.env.OPENCODE_TMUX_HOOK_STATUS_BAR ?? "1") !== "0"
const DURATION = process.env.OPENCODE_TMUX_HOOK_DURATION ?? "3000"

// Detect whether we are actually inside a tmux session at plugin-load time.
const INSIDE_TMUX = Boolean(process.env.TMUX)

type Level = "info" | "warn" | "attention" | "error" | "ok"

const ICONS: Record<Level, string> = {
  info: "·",
  warn: "⚠",
  attention: "?",
  error: "✖",
  ok: "✔",
}

// Colour codes understood by tmux's display-message (#[fg=colour])
const COLOURS: Record<Level, string> = {
  info: "colour250",
  warn: "colour220",
  attention: "colour214",
  error: "colour196",
  ok: "colour82",
}

/**
 * Show a tmux display-message in the target pane.
 * Falls back to a no-op when not running inside tmux.
 */
async function notify(
  $: (strings: TemplateStringsArray, ...values: unknown[]) => Promise<unknown>,
  level: Level,
  msg: string,
): Promise<void> {
  if (!INSIDE_TMUX) return

  const icon = ICONS[level]
  const colour = COLOURS[level]
  const text = `#[fg=${colour}]${icon} opencode | ${msg}#[default]`
  const paneArg = PANE ? ["-t", PANE] : []

  try {
    if (paneArg.length) {
      await $`tmux display-message -d ${DURATION} -t ${PANE} ${text}`
    } else {
      await $`tmux display-message -d ${DURATION} ${text}`
    }
  } catch {
    // swallow — tmux may not be available in all environments
  }
}

/** Ring the terminal bell in the target pane (draws attention). */
async function bell(
  $: (strings: TemplateStringsArray, ...values: unknown[]) => Promise<unknown>,
): Promise<void> {
  if (!INSIDE_TMUX || !BELL) return
  try {
    const paneArg = PANE ? PANE : ""
    if (paneArg) {
      await $`tmux send-keys -t ${paneArg} ""`
    }
    // tmux bell via set-option approach
    await $`tmux run-shell "printf '\\a'"`
  } catch {
    // swallow
  }
}

/** Update tmux status-right with the current OpenCode state. */
async function setStatus(
  $: (strings: TemplateStringsArray, ...values: unknown[]) => Promise<unknown>,
  state: string,
): Promise<void> {
  if (!INSIDE_TMUX || !STATUS_BAR) return
  try {
    // We store our state in a tmux user-option @opencode_state and let the
    // user reference it in their status-right via #{@opencode_state}.
    await $`tmux set-option -g @opencode_state ${state}`
  } catch {
    // swallow
  }
}

// ─── plugin ───────────────────────────────────────────────────────────────────

export const TmuxHookerPlugin: Plugin = async ({ $, project }) => {
  const projectName = project?.path?.split("/").pop() ?? "opencode"

  // Set initial state
  await setStatus($, `#[fg=colour250]· ${projectName}: idle#[default]`)

  return {
    // ── Session lifecycle ────────────────────────────────────────────────────

    /**
     * Fires when OpenCode transitions to idle — the AI has finished processing
     * and is waiting for the next user message.
     */
    "session.idle": async ({ session }) => {
      const sid = session.id.slice(0, 8)
      await setStatus($, `#[fg=colour82]✔ ${projectName}: idle#[default]`)
      await notify($, "ok", `session ${sid} complete — ready for input`)
      await bell($)
    },

    /**
     * Fires when a session changes status (running, idle, error…).
     * We use this to keep the tmux status bar in sync.
     */
    "session.status": async ({ session }) => {
      const status: string = (session as Record<string, unknown>).status as string ?? "unknown"
      const sid = session.id.slice(0, 8)

      switch (status) {
        case "running":
          await setStatus($, `#[fg=colour39]⟳ ${projectName}: thinking…#[default]`)
          await notify($, "info", `session ${sid} — thinking…`)
          break
        case "idle":
          // handled by session.idle
          break
        case "error":
          await setStatus($, `#[fg=colour196]✖ ${projectName}: error#[default]`)
          await notify($, "error", `session ${sid} — error`)
          await bell($)
          break
        default:
          await setStatus($, `#[fg=colour250]· ${projectName}: ${status}#[default]`)
      }
    },

    /**
     * Fires when a session encounters an error.
     */
    "session.error": async ({ session }) => {
      const sid = session.id.slice(0, 8)
      await setStatus($, `#[fg=colour196]✖ ${projectName}: error#[default]`)
      await notify($, "error", `session ${sid} crashed — check logs`)
      await bell($)
    },

    /**
     * Fires when a new session is created.
     */
    "session.created": async ({ session }) => {
      const sid = session.id.slice(0, 8)
      await setStatus($, `#[fg=colour39]⟳ ${projectName}: starting…#[default]`)
      await notify($, "info", `new session started (${sid})`)
    },

    // ── Permission / question tool ───────────────────────────────────────────

    /**
     * Fires when OpenCode's permission system needs the user to decide
     * something (e.g. allow a shell command, approve a file write).
     * This is the "question tool waiting for your response" event.
     */
    "permission.asked": async ({ permission }) => {
      const tool = (permission as Record<string, unknown>).tool as string ?? "unknown"
      await setStatus($, `#[fg=colour214 bold]? ${projectName}: needs your input!#[default]`)
      await notify($, "attention", `WAITING FOR YOU — permission needed for tool: ${tool}`)
      await bell($)
      // Ring the bell a second time after a short delay for extra attention
      await new Promise((r) => setTimeout(r, 800))
      await bell($)
    },

    /**
     * Fires after the user replies to a permission prompt.
     */
    "permission.replied": async ({ permission }) => {
      const granted = (permission as Record<string, unknown>).granted
      const tool = (permission as Record<string, unknown>).tool as string ?? "unknown"
      const word = granted ? "granted" : "denied"
      await notify($, granted ? "ok" : "warn", `permission ${word} for ${tool}`)
      await setStatus($, `#[fg=colour39]⟳ ${projectName}: thinking…#[default]`)
    },

    // ── Tool activity ────────────────────────────────────────────────────────

    /**
     * Fires just before a tool is executed. Useful for seeing what the AI is
     * about to do in real time.
     */
    "tool.execute.before": async (input) => {
      const toolName = (input as Record<string, unknown>).tool as string ?? "tool"
      await setStatus($, `#[fg=colour39]⟳ ${projectName}: running ${toolName}…#[default]`)
      // Only notify for "heavy" or interesting tools to avoid notification spam
      const notableTools = new Set(["bash", "write", "edit", "delete", "web_search"])
      if (notableTools.has(toolName)) {
        await notify($, "info", `running tool: ${toolName}`)
      }
    },

    /**
     * Fires after a tool finishes. We use this to go back to "thinking" state.
     */
    "tool.execute.after": async (input) => {
      const toolName = (input as Record<string, unknown>).tool as string ?? "tool"
      const notableTools = new Set(["bash", "write", "edit", "delete"])
      if (notableTools.has(toolName)) {
        await notify($, "info", `tool done: ${toolName}`)
      }
      await setStatus($, `#[fg=colour39]⟳ ${projectName}: thinking…#[default]`)
    },

    // ── Session compaction ───────────────────────────────────────────────────

    /**
     * Fires when the session context is compacted (context window management).
     */
    "session.compacted": async ({ session }) => {
      const sid = session.id.slice(0, 8)
      await notify($, "warn", `session ${sid} context compacted`)
    },

    // ── Todo updates (agent task list) ───────────────────────────────────────

    /**
     * Fires when the AI's internal todo list changes — gives a sense of
     * what task the agent is currently working on.
     */
    "todo.updated": async ({ todos }) => {
      const inProgress = (todos as Array<Record<string, unknown>>).filter(
        (t) => t.status === "in_progress",
      )
      if (inProgress.length > 0) {
        const current = inProgress[0]
        const title = (current.content as string ?? "").slice(0, 40)
        await setStatus(
          $,
          `#[fg=colour39]⟳ ${projectName}: ${title}${title.length === 40 ? "…" : ""}#[default]`,
        )
      }
    },
  }
}
