import type { Plugin } from "@opencode-ai/plugin"
import { execSync } from "child_process"

/**
 * Thin Client Plugin that:
 * - Forwards OpenCode state events to the ACP daemon (acpd) running on port 4040.
 */
export const NotifyIdlePlugin: Plugin = async ({ $ }) => {
  const tmuxPane = process.env.TMUX_PANE ?? ""

  if (tmuxPane) {
    process.on("exit", () => {
      try {
        execSync(`curl -s -X POST http://127.0.0.1:4040/api/status -H "Content-Type: application/json" -d '{"pane_id":"${tmuxPane}","state":"closed"}'`);
      } catch {
        // Ignore errors on exit
      }
    });

    // Handle Ctrl+C properly to trigger exit
    process.on("SIGINT", () => {
      process.exit(0);
    });
  }

  const sendAcpState = async (state: string, message: string | null = null) => {
    if (!tmuxPane) return;
    try {
      await fetch("http://127.0.0.1:4040/api/status", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pane_id: tmuxPane, state, message }),
      })
    } catch {
      // Ignore failures if the acpd daemon is not running
    }
  }

  let waitingPermission = false

  return {
    "event": async ({ event }) => {
      const evtType = (event as any)?.type ?? "unknown"

      if (evtType === "permission.asked") {
        waitingPermission = true
        await sendAcpState("permission")
        return
      }

      if (evtType === "permission.replied") {
        waitingPermission = false
        return
      }

      if (evtType !== "session.status") return

      const properties = (event as any)?.properties
      const statusType: string = properties?.status?.type ?? "unknown"

      // Keep permission indicator visible while waiting for user reply.
      if (waitingPermission && statusType === "busy") return
      
      if (statusType === "idle") {
        await sendAcpState("idle")
      } else if (statusType === "busy") {
        await sendAcpState("working")
      } else if (statusType === "retry") {
        await sendAcpState("error")
      }
    },

    "tool.execute.before": async (input) => {
      const toolName = (input as Record<string, any>)?.tool ?? "tool"
      if (toolName === "question") {
        await sendAcpState("awaiting_input")
      } else {
        await sendAcpState("working")
      }
    },

    "permission.ask": async (input) => {
      await sendAcpState("permission")
    },

    "permission.asked": async (input) => {
      await sendAcpState("permission")
    },
  }
}
