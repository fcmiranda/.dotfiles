#!/usr/bin/env node
import { readCtx, getActiveTmuxPane } from './hook-lib.mjs';

/**
 * We wait for a short period before actually sending the 'idle' state.
 * If the AI invokes another tool immediately after the previous one finishes,
 * this delay prevents the tmux status icon from flickering between "working" and "idle".
 * A new "working" state will update the timestamp in the state file and cancel this pending idle.
 */
async function sendAcpState(paneId, state, message = null) {
  if (!paneId) return;

  try {
    await fetch('http://127.0.0.1:4040/api/status', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        pane_id: paneId,
        state,
        message,
        timestamp: Date.now()
      }),
    });
  } catch (e) {
    // Ignore errors so the agent doesn't crash if the acpd daemon is down
  }
}

async function main() {
  const eventType = process.argv[2];
  const tmuxPane = getActiveTmuxPane();

  const { ctx } = await readCtx();

  if (['SessionStart', 'PreInvocation'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'working');
  }
  else if (eventType === 'PreToolUse') {
    const toolCall = ctx.toolCall || {};
    const toolName = toolCall.name || ctx.tool_name || ctx.tool || '';

    if (['ask_user', 'question', 'ask_question'].includes(toolName)) {
      await sendAcpState(tmuxPane, 'awaiting_input');
    } else if (['request_permission', 'ask_permission'].includes(toolName)) {
      await sendAcpState(tmuxPane, 'permission');
    } else {
      await sendAcpState(tmuxPane, 'working');
    }
  }
  else if (['Stop', 'PostInvocation'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'idle');
  }
  else if (['SessionEnd', 'Exit'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'closed');
  }

  // Echo the context back so we don't break the pipeline
  console.log(JSON.stringify(ctx));
  process.exit(0);
}

main();