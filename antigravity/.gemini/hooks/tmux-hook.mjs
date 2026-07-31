#!/usr/bin/env node
import { readCtx, getActiveTmuxPane, getAcpdHeaders, log } from './hook-lib.mjs';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { spawn, execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const LOG_FILE = '/tmp/tmux-hook.log';
const __filename = fileURLToPath(import.meta.url);

function getParamFile(paneId) {
  const safePane = (paneId || 'default').replace(/[^a-zA-Z0-9]/g, '_');
  return join(tmpdir(), `acpd-pane-state-${safePane}.json`);
}

function readPaneState(paneId) {
  try {
    const file = getParamFile(paneId);
    if (existsSync(file)) {
      return JSON.parse(readFileSync(file, 'utf8'));
    }
  } catch (e) {}
  return null;
}

function writePaneState(paneId, state, message = null) {
  try {
    const file = getParamFile(paneId);
    const data = { paneId, state, message, timestamp: Date.now() };
    writeFileSync(file, JSON.stringify(data), 'utf8');
  } catch (e) {}
}

async function sendAcpState(paneId, state, message = null) {
  if (!paneId) return;

  writePaneState(paneId, state, message);

  try {
    const res = await fetch('http://127.0.0.1:4040/api/status', {
      method: 'POST',
      headers: getAcpdHeaders(),
      body: JSON.stringify({
        pane_id: paneId,
        state,
        message,
        timestamp: Date.now()
      }),
    });
    log(LOG_FILE, `sendAcpState(${paneId}, ${state}) → HTTP ${res.status}`);
  } catch (e) {
    log(LOG_FILE, `sendAcpState(${paneId}, ${state}) error: ${e.message}`);
  }

  // Spawn watchdog if transition to an active state
  if (['working', 'permission', 'awaiting_input'].includes(state)) {
    try {
      const child = spawn(process.execPath, [__filename, 'Watchdog', paneId], {
        detached: true,
        stdio: 'ignore',
        env: process.env
      });
      child.unref();
    } catch (e) {}
  }
}

async function getPaneCapture(paneId) {
  if (!paneId) return '';
  try {
    const res = await fetch('http://127.0.0.1:4040/rpc', {
      method: 'POST',
      headers: getAcpdHeaders(),
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'tmux.capture_pane',
        params: { pane_id: paneId },
        id: Date.now()
      })
    });
    if (res.ok) {
      const json = await res.json();
      if (json?.result?.content !== undefined) {
        return json.result.content;
      }
    }
  } catch (e) {
    log(LOG_FILE, `[Watchdog] rpc fetch error: ${e.message}`);
  }

  try {
    return execSync(`tmux capture-pane -p -t "${paneId}"`, { stdio: 'pipe', env: process.env }).toString();
  } catch (e) {
    log(LOG_FILE, `[Watchdog] getPaneCapture(${paneId}) error: ${e.message}`);
    return '';
  }
}

async function runWatchdog(paneId) {
  log(LOG_FILE, `[Watchdog] started for pane=${paneId}`);
  for (let i = 0; i < 60; i++) {
    await new Promise(r => setTimeout(r, 2000));

    const currentState = readPaneState(paneId);
    if (!currentState || ['idle', 'closed', 'awaiting_input', 'permission'].includes(currentState.state)) {
      log(LOG_FILE, `[Watchdog] pane ${paneId} state is now ${currentState?.state} -> exiting watchdog`);
      return;
    }

    const cap = await getPaneCapture(paneId);
    const lines = (cap || '').trim().split('\n').filter(l => l.trim().length > 0);
    const lastLine = lines[lines.length - 1] || '';

    // AGY CLI status bar indicator:
    // "esc to cancel" -> actively thinking / working
    // "? for shortcuts" -> idle / prompt waiting for user input
    const isThinking = /esc to cancel/i.test(lastLine);
    const atIdlePrompt = /\? for shortcuts/i.test(lastLine) || /[❯$#%>?]\s*$/i.test(lastLine) || /\^C|cancelled|interrupted/i.test(lastLine);

    log(LOG_FILE, `[Watchdog] loop ${i} isThinking=${isThinking} atIdlePrompt=${atIdlePrompt} lastLine="${lastLine.substring(0, 40)}..."`);

    if (!isThinking && atIdlePrompt) {
      log(LOG_FILE, `[Watchdog] pane ${paneId} AGY returned to idle prompt -> resetting state to idle`);
      await sendAcpState(paneId, 'idle');
      return;
    }
  }
  log(LOG_FILE, `[Watchdog] pane ${paneId} timeout reached after 120s`);
}

async function main() {
  const eventType = process.argv[2];

  if (eventType === 'Watchdog') {
    const targetPane = process.argv[3];
    await runWatchdog(targetPane);
    return;
  }

  const tmuxPane = getActiveTmuxPane();
  const { ctx } = await readCtx();

  log(LOG_FILE, `event=${eventType} pane=${tmuxPane} fullyIdle=${ctx.fullyIdle ?? 'n/a'}`);

  if (['SessionStart', 'PreInvocation'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'working');
  }
  else if (eventType === 'PreToolUse') {
    const toolCall = ctx.toolCall || {};
    const toolName = toolCall.name || ctx.tool_name || ctx.tool || '';

    if (toolName.includes('question') || toolName.includes('ask_user')) {
      await sendAcpState(tmuxPane, 'awaiting_input');
    } else if (toolName.includes('permission')) {
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

  process.stdout.write(JSON.stringify(ctx) + '\n');
}

await main();