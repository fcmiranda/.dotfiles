#!/usr/bin/env node
import { execSync } from 'node:child_process';
import { writeFileSync, readFileSync, unlinkSync } from 'node:fs';
import { basename } from 'node:path';
import { log, readCtx, getActiveTmuxPane, notifyTmux, setLazygitrsIcon } from './hook-lib.mjs';

const LOG_FILE = '/tmp/lazygit-hook.log';
const CANDIDATE_PORTS = Array.from({ length: 100 }, (_, i) => 47657 + i);
const AUTO_START_RETRIES = 10;
const AUTO_START_DELAY_MS = 500;

function saveTmuxPane(tmuxPane, workspacePath) {
  if (tmuxPane && workspacePath) {
    try {
      const safePath = workspacePath.replace(/[^a-zA-Z0-9]/g, '_');
      writeFileSync(`/tmp/agy-active-pane-${safePath}.txt`, tmuxPane);
    } catch (e) { }
  }
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function registerLazygitrs(conversationId, tmuxPane, initialPort, workspacePath) {
  log(LOG_FILE, `Starting registerLazygitrs for session ${conversationId} pane ${tmuxPane} in cwd ${process.cwd()}`);
  if (!conversationId) {
    log(LOG_FILE, `No conversationId, aborting`);
    return;
  }

  // Fast path: verify if we already registered this conversation and if server is still up.
  const safePath = (workspacePath || '').replace(/[^a-zA-Z0-9]/g, '_');
  const sentinel = `/tmp/agy-registered-${safePath}.sentinel`;
  try {
    const stored = readFileSync(sentinel, 'utf-8').trim();
    if (stored === conversationId) {
      try {
        const checkRes = await fetch(`http://127.0.0.1:${initialPort}/session-api/session`);
        if (checkRes.ok) {
          const currentSessionData = await checkRes.json();
          if (currentSessionData && currentSessionData.sessionId === conversationId) {
            log(LOG_FILE, `Already registered (sentinel hit & verified), keeping icon`);
            setLazygitrsIcon(tmuxPane, '#[fg=#a6e3a1]#[fg=default]');
            return;
          }
        }
      } catch (e) {
        log(LOG_FILE, `Sentinel hit but server unverified: ${e.message}`);
      }
      // Server is no longer reachable or session changed - clear stale sentinel!
      try { unlinkSync(sentinel); } catch (e) {}
    }
  } catch (e) { /* no sentinel yet */ }

  let bridgeStatus = '✅ Lazygit SSE Bridge online';
  let fallbackWarning = '';
  let isAlreadyRegistered = false;
  let foundTarget = false;
  let API_BASE_URL = '';
  let port = initialPort;

  // Phase 1: Scan candidate ports. Try the port from .lazygitrs.port
  // first, then the sequential range 47657-47756.
  const portsToScan = [...new Set([initialPort, ...CANDIDATE_PORTS])];
  for (const p of portsToScan) {
    API_BASE_URL = `http://127.0.0.1:${p}/session-api`;
    log(LOG_FILE, `Checking port and URL: ${API_BASE_URL}`);
    let checkRes;
    try {
      checkRes = await fetch(`${API_BASE_URL}/session`);
    } catch (netErr) {
      log(LOG_FILE, `Port ${p} not reachable: ${netErr.message}`);
      continue;
    }
    if (!checkRes.ok) {
      log(LOG_FILE, `Port ${p} responded non-200: ${checkRes.status}`);
      continue;
    }

    const currentSessionData = await checkRes.json();
    log(LOG_FILE, `Current session data: ${JSON.stringify(currentSessionData)}`);
    if (currentSessionData && currentSessionData.workspacePath &&
        currentSessionData.workspacePath !== workspacePath) {
      log(LOG_FILE, `Port ${p} belongs to a different workspace (${currentSessionData.workspacePath})`);
      continue;
    }

    port = p;
    if (currentSessionData && currentSessionData.sessionId === conversationId) {
      isAlreadyRegistered = true;
    }
    foundTarget = true;
    break;
  }

  // Phase 2: If no lazygitrs instance was found anywhere, auto-start one
  // in a detached tmux session or window. This is the restored behaviour (removed in
  // commit 22c13d0, now improved to scan ALL ports before spawning).
  if (!foundTarget) {
    log(LOG_FILE, `No lazygitrs found on any port — auto-starting`);
    try {
      const wsPath = workspacePath || process.cwd();
      const sessionName = '_lazygitrs-' + basename(wsPath);
      execSync(`tmux new-session -d -s "${sessionName}" -c "${wsPath}" "lazygitrs"`);
      const spawnTarget = sessionName;
      log(LOG_FILE, `Started background tmux session: ${spawnTarget}`);

      bridgeStatus = '✅ Lazygitrs auto-started';
      fallbackWarning = ` (${spawnTarget})`;

      // Wait for the HTTP server to bind, then retry the scan.
      for (let retry = 0; retry < AUTO_START_RETRIES; retry++) {
        await sleep(AUTO_START_DELAY_MS);
        let newPort;
        try {
          newPort = parseInt(readFileSync(`${wsPath}/.lazygitrs.port`, 'utf-8').trim(), 10) || 47657;
        } catch (e) { continue; }

        API_BASE_URL = `http://127.0.0.1:${newPort}/session-api`;
        try {
          const checkRes = await fetch(`${API_BASE_URL}/session`);
          if (checkRes.ok) {
            const data = await checkRes.json();
            if (!data.workspacePath || data.workspacePath === wsPath) {
              port = newPort;
              foundTarget = true;
              log(LOG_FILE, `Auto-started lazygitrs is up on port ${newPort}`);
              break;
            }
          }
        } catch (e) { /* still booting */ }
      }
    } catch (err) {
      log(LOG_FILE, `Auto-start failed: ${err.message}`);
    }
  }

  if (!foundTarget) {
    log(LOG_FILE, `Could not find or start lazygitrs for workspace ${workspacePath}`);
    bridgeStatus = '⚠️ Lazygitrs offline';
    fallbackWarning = ' (Start lazygitrs to integrate)';
    setLazygitrsIcon(tmuxPane, '');
    notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning}`);
    return;
  }

  // Phase 3: Register the conversation with the found/started instance.
  try {
    if (!isAlreadyRegistered) {
      log(LOG_FILE, `Registering session on port ${port}...`);
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
        setLazygitrsIcon(tmuxPane, '');
        log(LOG_FILE, `Registration failed: ${res.statusText}`);
      } else {
        if (!bridgeStatus.startsWith('✅ Lazygitrs auto-started')) {
          bridgeStatus = '✅ Registered Lazygitrs session';
        }
        setLazygitrsIcon(tmuxPane, '#[fg=#a6e3a1]#[fg=default]');
        notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning} - conversation id: ${conversationId}`);
        log(LOG_FILE, `Registration successful`);
      }
    } else {
      bridgeStatus = '✅ Lazygitrs session already registered';
      setLazygitrsIcon(tmuxPane, '#[fg=#a6e3a1]#[fg=default]');
      log(LOG_FILE, `Session already registered`);
    }

    // Persist registration so subsequent hook invocations skip the scan.
    try { writeFileSync(sentinel, conversationId); } catch (e) {}
  } catch (e) {
    log(LOG_FILE, `Error during registration: ${e.message}`);
    notifyTmux(tmuxPane, `[AGY] ⚠️ Registration error: ${e.message}`);
  }
}


async function unregisterLazygitrs(conversationId, tmuxPane, initialPort, workspacePath) {
  log(LOG_FILE, `Unregistering lazygitrs session ${conversationId} pane ${tmuxPane}...`);
  const safePath = (workspacePath || '').replace(/[^a-zA-Z0-9]/g, '_');
  const sentinel = `/tmp/agy-registered-${safePath}.sentinel`;
  try { unlinkSync(sentinel); } catch (e) {}

  setLazygitrsIcon(tmuxPane, '');

  if (!conversationId) return;

  let port = initialPort;
  try {
    const portFile = `${workspacePath}/.lazygitrs.port`;
    port = parseInt(readFileSync(portFile, 'utf-8').trim(), 10) || initialPort;
  } catch (e) {}

  try {
    await fetch(`http://127.0.0.1:${port}/session-api`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'unregister', sessionId: conversationId }),
    });
    log(LOG_FILE, `Unregistered session ${conversationId} from port ${port}`);
  } catch (e) {
    log(LOG_FILE, `Unregister call failed: ${e.message}`);
  }
}


async function main() {
  const eventType = process.argv[2] || 'PreInvocation';
  const { inputStr, ctx } = await readCtx();

  log(LOG_FILE, `Hook main called [${eventType}]. ctx: ${JSON.stringify(ctx)} PWD: ${process.env.PWD}`);

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

  if (['SessionEnd', 'Exit', 'Unregister'].includes(eventType)) {
    await unregisterLazygitrs(conversationId, tmuxPane, port, workspacePath);
  } else {
    await registerLazygitrs(conversationId, tmuxPane, port, workspacePath);
  }

  // Echo the context back so we don't break the hook pipeline
  if (inputStr.trim()) {
    console.log(JSON.stringify(ctx));
  }

  process.exit(0);
}

main();