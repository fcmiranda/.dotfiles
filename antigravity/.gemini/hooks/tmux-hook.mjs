import { spawnSync } from 'node:child_process';

async function sendAcpState(paneId, state, message = null) {
  if (!paneId) return;
  try {
    await fetch('http://127.0.0.1:4040/api/status', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pane_id: paneId, state, message }),
    });
  } catch (e) { 
    // Ignore errors so the agent doesn't crash if the acpd daemon is down
  }
}

async function main() {
  const eventType = process.argv[2];
  let tmuxPane = process.env.TMUX_PANE || '';
  if (!tmuxPane) {
    tmuxPane = spawnSync('tmux', ['display-message', '-p', '#{pane_id}']).stdout?.toString().trim() || '';
  }

  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const inputStr = Buffer.concat(chunks).toString('utf-8');
  const ctx = inputStr.trim() ? JSON.parse(inputStr) : {};

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
  if (!['SessionStart', 'PreInvocation'].includes(eventType)) {
    console.log(JSON.stringify(ctx));
  }
  process.exit(0);
}

main();
