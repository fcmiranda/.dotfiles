import { spawnSync, spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

/**
 * We wait for a short period before actually sending the 'idle' state.
 * If the AI invokes another tool immediately after the previous one finishes,
 * this delay prevents the tmux status icon from flickering between "working" and "idle".
 * A new "working" state will update the timestamp in the state file and cancel this pending idle.
 */
function sendDelayedIdleState(paneId, stateFile, message) {
  const now = Date.now().toString();
  writeFileSync(stateFile, now);

  const payload = JSON.stringify({ pane_id: paneId, state: 'idle', message });

  const code = `
    setTimeout(async () => {
      try {
        const fs = require('fs');
        const ts = fs.readFileSync(process.env.STATE_FILE, 'utf8');
        if (ts === process.env.NOW) {
          await fetch('http://127.0.0.1:4040/api/status', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: process.env.PAYLOAD
          });
        }
      } catch (e) {}
    }, 650);
  `;

  const child = spawn(process.execPath, ['-e', code], {
    detached: true,
    stdio: 'ignore',
    env: {
      ...process.env,
      STATE_FILE: stateFile,
      NOW: now,
      PAYLOAD: payload
    }
  });
  child.unref();
}

async function sendAcpState(paneId, state, message = null) {
  if (!paneId) return;

  try {
    const stateFile = join(tmpdir(), `acpd-tmux-state-${paneId.replace('%', '')}.txt`);

    if (state === 'idle') {
      sendDelayedIdleState(paneId, stateFile, message);
      return;
    } else {
      writeFileSync(stateFile, Date.now().toString());
    }
  } catch (e) { }

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

