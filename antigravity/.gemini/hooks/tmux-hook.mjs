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

function getPaneCapture(paneId) {
  if (!paneId) return '';
  try {
    return execSync(`tmux capture-pane -p -t "${paneId}"`, { stdio: 'pipe' }).toString();
  } catch (e) {
    return '';
  }
}

async function runWatchdog(paneId) {
  // Sleep 2.5 seconds before first check
  await new Promise(r => setTimeout(r, 2500));

  const stateInfo = readPaneState(paneId);
  if (!stateInfo || ['idle', 'closed'].includes(stateInfo.state)) {
    return;
  }

  // If a newer event updated the timestamp in the last 2 seconds, let that cycle handle it
  if (Date.now() - stateInfo.timestamp < 2000) {
    return;
  }

  log(LOG_FILE, `[Watchdog] checking pane=${paneId} state=${stateInfo.state} silenceMs=${Date.now() - stateInfo.timestamp}`);

  // Sample pane content twice over 800ms to see if output is actively streaming
  const cap1 = getPaneCapture(paneId);
  await new Promise(r => setTimeout(r, 800));
  const cap2 = getPaneCapture(paneId);

  const currentState = readPaneState(paneId);
  if (!currentState || ['idle', 'closed'].includes(currentState.state)) {
    return;
  }

  // If pane content is unchanged (or failed to capture), output is not streaming (e.g. interrupted or at prompt)
  if (!cap1 || !cap2 || cap1 === cap2) {
    log(LOG_FILE, `[Watchdog] pane ${paneId} is static -> resetting to idle`);
    await sendAcpState(paneId, 'idle');
  } else {
    // Content was streaming, schedule one more check in 2 seconds
    await new Promise(r => setTimeout(r, 2000));
    const finalState = readPaneState(paneId);
    if (finalState && !['idle', 'closed'].includes(finalState.state)) {
      log(LOG_FILE, `[Watchdog] second check for pane ${paneId} -> resetting to idle`);
      await sendAcpState(paneId, 'idle');
    }
  }
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

  process.stdout.write(JSON.stringify(ctx) + '\n');
}

await main();