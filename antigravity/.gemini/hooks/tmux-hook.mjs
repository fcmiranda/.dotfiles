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
    // Fallback: trigger sound notification directly if ACPD is unreachable
    if (state === 'idle') {
      try {
        const soundChild = spawn('ai-sound-notify', ['response'], {
          detached: true,
          stdio: 'ignore',
          env: process.env
        });
        soundChild.unref();
      } catch (err) {}
    }
  }
}

async function main() {
  const eventType = process.argv[2];

  const tmuxPane = getActiveTmuxPane();
  const { ctx } = await readCtx();

  log(LOG_FILE, `event=${eventType} pane=${tmuxPane} fullyIdle=${ctx.fullyIdle ?? 'n/a'}`);

  if (['SessionStart', 'PreInvocation'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'working');
  }
  else if (eventType === 'PreToolUse') {
    const toolCall = ctx.toolCall || {};
    const toolName = (toolCall.name || ctx.tool_name || ctx.tool || '').toLowerCase();

    if (toolName.includes('question') || toolName.includes('ask')) {
      await sendAcpState(tmuxPane, 'awaiting_input');
    } else if (toolName.includes('permission')) {
      await sendAcpState(tmuxPane, 'permission');
    } else {
      await sendAcpState(tmuxPane, 'working');
    }
  }
  else if (eventType === 'Stop') {
    // Only transition to idle when the entire agent turn terminates (Stop event)
    await sendAcpState(tmuxPane, 'idle');
  }
  else if (['SessionEnd', 'Exit'].includes(eventType)) {
    await sendAcpState(tmuxPane, 'closed');
  }

  // Output a clean minimal JSON response so CLI protojson unmarshaler doesn't fail on extra fields
  if (eventType === 'PreToolUse') {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
  } else {
    process.stdout.write('{}\n');
  }
}

await main();