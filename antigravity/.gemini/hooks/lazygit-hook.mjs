#!/usr/bin/env node
import { execSync, spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const API_BASE_URL = 'http://127.0.0.1:47657/session-api';

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const inputStr = Buffer.concat(chunks).toString('utf-8');
  let ctx = {};
  if (inputStr.trim()) {
    try {
      ctx = JSON.parse(inputStr);
    } catch (e) {
      // Ignore parse error, return empty object
    }
  }
  return { inputStr, ctx };
}

function getActiveTmuxPane() {
  let tmuxPane = process.env.TMUX_PANE || '';
  if (!tmuxPane) {
    try {
      tmuxPane = execSync('tmux display-message -p "#{pane_id}"', { stdio: 'pipe' }).toString().trim();
    } catch (e) { }
  }
  if (!tmuxPane) {
    try {
      const panes = execSync('tmux list-panes -a -F "#{pane_id} #{pane_current_command}"', { stdio: 'pipe' }).toString();
      const agyPaneLine = panes.split('\n').find(line => line.includes('agy') || line.includes('node'));
      if (agyPaneLine) {
        tmuxPane = agyPaneLine.split(' ')[0];
      }
    } catch (e) { }
  }
  return tmuxPane;
}

function saveTmuxPane(tmuxPane) {
  if (tmuxPane) {
    try {
      writeFileSync('/tmp/agy-active-pane.txt', tmuxPane);
    } catch (e) { }
  }
}

function notifyTmux(pane, message) {
  if (!pane) return;
  try {
    execSync(`tmux display-message -t "${pane}" "${message}"`, { stdio: 'pipe' });
  } catch (e) { }
}

async function registerLazygitrs(conversationId, tmuxPane) {
  if (!conversationId) return;

  let bridgeStatus = '✅ Lazygit SSE Bridge online';
  let fallbackWarning = '';

  try {
    const checkRes = await fetch(`${API_BASE_URL}/session`);
    let isAlreadyRegistered = false;

    if (checkRes.ok) {
      const currentSessionData = await checkRes.json();
      if (currentSessionData && currentSessionData.sessionId === conversationId) {
        isAlreadyRegistered = true;
      }
    }

    if (!isAlreadyRegistered) {
      const res = await fetch(API_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'register',
          sessionId: conversationId,
          cli: 'antigravity',
          notifyCommand: 'agy --conversation {{session_id}} --print {{prompt}}',
          force: true
        }),
      });

      if (!res.ok) {
        bridgeStatus = '⚠️ Lazygitrs registration rejected';
        fallbackWarning = ' (Fallback active)';
      } else {
        bridgeStatus = '✅ Registered Lazygitrs session';
        notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning} - conversation id: ${conversationId}`);
      }
    } else {
      bridgeStatus = '✅ Lazygitrs session already registered';
    }

  } catch (e) {
    // lazygitrs is probably not running
    bridgeStatus = '⚠️ Lazygitrs offline';
    fallbackWarning = ' (Start lazygitrs to integrate)';
    notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning}`);
  }
}

function ensureSseBridge() {
  try {
    execSync('pgrep -f lazygit-sse-bridge.sh', { stdio: 'pipe' });
  } catch (e) {
    // pgrep exits with 1 if no process matches
    try {
      const sseProcess = spawn('bash', ['/home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-sse-bridge.sh'], {
        detached: true,
        stdio: 'ignore'
      });
      sseProcess.unref();
    } catch (err) { }
  }
}

async function main() {
  const { inputStr, ctx } = await readStdin();

  const tmuxPane = getActiveTmuxPane();
  saveTmuxPane(tmuxPane);

  const conversationId = ctx.session_id || process.env.ANTIGRAVITY_CONVERSATION_ID;
  await registerLazygitrs(conversationId, tmuxPane);

  ensureSseBridge();

  // Echo the context back so we don't break the hook pipeline
  if (inputStr.trim()) {
    console.log(JSON.stringify(ctx));
  }

  process.exit(0);
}

main();
