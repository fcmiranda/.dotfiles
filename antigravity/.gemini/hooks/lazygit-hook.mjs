#!/usr/bin/env node
import { execSync } from 'node:child_process';
import { writeFileSync, readFileSync } from 'node:fs';
import { log, readCtx, getActiveTmuxPane, notifyTmux } from './hook-lib.mjs';

const LOG_FILE = '/tmp/lazygit-hook.log';

function saveTmuxPane(tmuxPane, workspacePath) {
  if (tmuxPane && workspacePath) {
    try {
      // Create a safe filename based on the workspace path to isolate sessions
      const safePath = workspacePath.replace(/[^a-zA-Z0-9]/g, '_');
      writeFileSync(`/tmp/agy-active-pane-${safePath}.txt`, tmuxPane);
    } catch (e) { }
  }
}

async function registerLazygitrs(conversationId, tmuxPane, initialPort, workspacePath) {
  log(LOG_FILE, `Starting registerLazygitrs for session ${conversationId} pane ${tmuxPane} in cwd ${process.cwd()}`);
  if (!conversationId) {
    log(LOG_FILE, `No conversationId, aborting`);
    return;
  }

  // Fast path: if we already registered this conversation for this workspace
  // in a previous hook invocation, skip the HTTP scan entirely. agy fires
  // this hook on every tool invocation, so this avoids N redundant scans.
  const safePath = (workspacePath || '').replace(/[^a-zA-Z0-9]/g, '_');
  const sentinel = `/tmp/agy-registered-${safePath}.sentinel`;
  try {
    const stored = readFileSync(sentinel, 'utf-8').trim();
    if (stored === conversationId) {
      log(LOG_FILE, `Already registered (sentinel hit), skipping scan`);
      return;
    }
  } catch (e) { /* no sentinel yet */ }

  let bridgeStatus = '✅ Lazygit SSE Bridge online';
  let fallbackWarning = '';
  let port = initialPort;
  let isAlreadyRegistered = false;
  let foundTarget = false;
  let API_BASE_URL = '';

  try {
    for (let i = 0; i < 100; i++) {
      API_BASE_URL = `http://127.0.0.1:${port}/session-api`;
      log(LOG_FILE, `Checking port and URL: ${API_BASE_URL}`);
      let checkRes;
      try {
        checkRes = await fetch(`${API_BASE_URL}/session`);
      } catch (netErr) {
        // Dead port — no point scanning further (ports past the last
        // lazygitrs instance aren't filled in). Stop the scan cleanly.
        log(LOG_FILE, `Port ${port} not reachable: ${netErr.message}`);
        break;
      }
      log(LOG_FILE, `Check session response status: ${checkRes.status}`);

      if (checkRes.ok) {
        const currentSessionData = await checkRes.json();
        log(LOG_FILE, `Current session data: ${JSON.stringify(currentSessionData)}`);
        if (currentSessionData) {
          if (currentSessionData.workspacePath && currentSessionData.workspacePath !== workspacePath) {
            log(LOG_FILE, `Lazygitrs on ${API_BASE_URL} belongs to a different workspace (${currentSessionData.workspacePath}). Trying next port...`);
            port++;
            continue;
          }
          if (currentSessionData.sessionId === conversationId) {
            isAlreadyRegistered = true;
          }
          foundTarget = true;
          break; // Found the correct workspace
        }
      } else {
        // Non-200 from a reachable server — stop scanning.
        break;
      }
    }

    if (!foundTarget) {
      throw new Error(`Could not find a lazygitrs instance for workspace ${workspacePath}`);
    }

    if (!isAlreadyRegistered) {
      log(LOG_FILE, `Registering session...`);
      const res = await fetch(API_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'register',
          sessionId: conversationId,
          cli: 'antigravity',
          force: true,
          notifyCommand: `/home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-tmux-injector.sh {{workspace_path}} {{prompt}}`
        }),
      });

      log(LOG_FILE, `Register response status: ${res.status}`);

      if (!res.ok) {
        bridgeStatus = '⚠️ Lazygitrs registration rejected';
        fallbackWarning = ' (Fallback active)';
        log(LOG_FILE, `Registration failed: ${res.statusText}`);
      } else {
        bridgeStatus = '✅ Registered Lazygitrs session';
        notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning} - conversation id: ${conversationId}`);
        log(LOG_FILE, `Registration successful`);
      }
    } else {
      bridgeStatus = '✅ Lazygitrs session already registered';
      log(LOG_FILE, `Session already registered`);
    }

    // Persist registration so subsequent hook invocations skip the scan.
    try { writeFileSync(sentinel, conversationId); } catch (e) {}

  } catch (e) {
    log(LOG_FILE, `Error in registerLazygitrs: ${e.message}`);
    // lazygitrs is not running — don't auto-spawn a detached instance,
    // as that risks racing the user's main GUI for the port. Just notify.
    bridgeStatus = '⚠️ Lazygitrs offline';
    fallbackWarning = ' (Start lazygitrs to integrate)';
    notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning}`);
  }
}


async function main() {
  const { inputStr, ctx } = await readCtx();

  log(LOG_FILE, `Hook main called. ctx: ${JSON.stringify(ctx)} PWD: ${process.env.PWD}`);

  const tmuxPane = getActiveTmuxPane();

  const conversationId = ctx.session_id || process.env.ANTIGRAVITY_CONVERSATION_ID;
  
  let workspacePath = process.cwd();
  if (ctx && ctx.workspacePaths && ctx.workspacePaths.length > 0) {
    workspacePath = ctx.workspacePaths[0];
  }

  // Save the tmux pane isolated by workspace path
  saveTmuxPane(tmuxPane, workspacePath);

  let port = 47657;
  try {
    const portFile = `${workspacePath}/.lazygitrs.port`;
    port = parseInt(readFileSync(portFile, 'utf-8').trim(), 10) || 47657;
  } catch (e) {}

  await registerLazygitrs(conversationId, tmuxPane, port, workspacePath);


  // Echo the context back so we don't break the hook pipeline
  if (inputStr.trim()) {
    console.log(JSON.stringify(ctx));
  }

  process.exit(0);
}

main();