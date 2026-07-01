#!/usr/bin/env node
import { execSync } from 'node:child_process';
import { writeFileSync, readFileSync, appendFileSync } from 'node:fs';


function log(msg) {
  try {
    appendFileSync('/tmp/lazygit-hook.log', `[${new Date().toISOString()}] ${msg}\n`);
  } catch (e) {}
}

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

function saveTmuxPane(tmuxPane, workspacePath) {
  if (tmuxPane && workspacePath) {
    try {
      // Create a safe filename based on the workspace path to isolate sessions
      const safePath = workspacePath.replace(/[^a-zA-Z0-9]/g, '_');
      writeFileSync(`/tmp/agy-active-pane-${safePath}.txt`, tmuxPane);
    } catch (e) { }
  }
}

function notifyTmux(pane, message) {
  if (!pane) return;
  try {
    execSync(`tmux display-message -t "${pane}" "${message}"`, { stdio: 'pipe' });
  } catch (e) { }
}

async function registerLazygitrs(conversationId, tmuxPane, initialPort, workspacePath) {
  log(`Starting registerLazygitrs for session ${conversationId} pane ${tmuxPane} in cwd ${process.cwd()}`);
  if (!conversationId) {
    log(`No conversationId, aborting`);
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
      log(`Already registered (sentinel hit), skipping scan`);
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
      log(`Checking port and URL: ${API_BASE_URL}`);
      let checkRes;
      try {
        checkRes = await fetch(`${API_BASE_URL}/session`);
      } catch (netErr) {
        // Dead port — no point scanning further (ports past the last
        // lazygitrs instance aren't filled in). Stop the scan cleanly.
        log(`Port ${port} not reachable: ${netErr.message}`);
        break;
      }
      log(`Check session response status: ${checkRes.status}`);

      if (checkRes.ok) {
        const currentSessionData = await checkRes.json();
        log(`Current session data: ${JSON.stringify(currentSessionData)}`);
        if (currentSessionData) {
          if (currentSessionData.workspacePath && currentSessionData.workspacePath !== workspacePath) {
            log(`Lazygitrs on ${API_BASE_URL} belongs to a different workspace (${currentSessionData.workspacePath}). Trying next port...`);
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
      log(`Registering session...`);
      const res = await fetch(API_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'register',
          sessionId: conversationId,
          cli: 'antigravity',
          force: true,
          notifyCommand: `/home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-tmux-injector.sh "${workspacePath}" {{prompt}}`
        }),
      });

      log(`Register response status: ${res.status}`);

      if (!res.ok) {
        bridgeStatus = '⚠️ Lazygitrs registration rejected';
        fallbackWarning = ' (Fallback active)';
        log(`Registration failed: ${res.statusText}`);
      } else {
        bridgeStatus = '✅ Registered Lazygitrs session';
        notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning} - conversation id: ${conversationId}`);
        log(`Registration successful`);
      }
    } else {
      bridgeStatus = '✅ Lazygitrs session already registered';
      log(`Session already registered`);
    }

    // Persist registration so subsequent hook invocations skip the scan.
    try { writeFileSync(sentinel, conversationId); } catch (e) {}

  } catch (e) {
    log(`Error in registerLazygitrs: ${e.message}`);
    // lazygitrs is not running — don't auto-spawn a detached instance,
    // as that risks racing the user's main GUI for the port. Just notify.
    bridgeStatus = '⚠️ Lazygitrs offline';
    fallbackWarning = ' (Start lazygitrs to integrate)';
    notifyTmux(tmuxPane, `[AGY] ${bridgeStatus}${fallbackWarning}`);
  }
}


async function main() {
  const { inputStr, ctx } = await readStdin();

  log(`Hook main called. ctx: ${JSON.stringify(ctx)} PWD: ${process.env.PWD}`);

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
