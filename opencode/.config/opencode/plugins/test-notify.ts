import type { Plugin } from "@opencode-ai/plugin"

/**
 * Simple plugin to send a desktop notification when the session is idle.
 */
export const NotifyIdlePlugin: Plugin = async ({ $ }) => {
  // Using console.log to ensure it's captured in the main opencode log file as INFO
  console.log("NotifyIdlePlugin: loading...")
  // await $`notify-send "OpenCode" "Task completed - Session is idle" -u critical`

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

      // SessionStatus.type values: "idle" | "busy" | "retry"
      const statusMessages: Record<string, { title: string; body: string; urgency: string }> = {
        idle:  { title: "OpenCode Finished",  body: "The AI has finished processing your prompt", urgency: "normal" },
        busy:  { title: "OpenCode Thinking",  body: "The AI is processing your request...",       urgency: "low" },
        retry: { title: "OpenCode Retrying",  body: "The AI is retrying...",                      urgency: "low" },
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
        try {
          await $`notify-send "OpenCode Needs Attention" "The AI has a question for you" -u critical`
        } catch (err) {
          console.error("NotifyIdlePlugin: notify-send for question failed", err)
        }
      }
    },

    "permission.ask": async (input) => {
      const tool = (input as Record<string, any>)?.tool ?? "unknown tool"
      try {
        await $`notify-send "OpenCode Needs Attention" ${`Permission needed for tool: ${tool}`} -u critical`
      } catch (err) {
        console.error("NotifyIdlePlugin: notify-send for permission failed", err)
      }
    },
  }
}
