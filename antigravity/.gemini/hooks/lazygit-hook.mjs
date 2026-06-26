#!/usr/bin/env node
import { execSync, spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';

async function main() {
  const eventType = process.argv[2];

  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const inputStr = Buffer.concat(chunks).toString('utf-8');
  let ctx = {};
  try {
    ctx = inputStr.trim() ? JSON.parse(inputStr) : {};
  } catch (e) { }

  const conversationId = ctx.session_id || process.env.ANTIGRAVITY_CONVERSATION_ID;

  let bridgeStatus = '✅ Lazygit SSE Bridge online';
  let fallbackWarning = '';

  if (conversationId) {
    try {
      // Check if already registered
      const checkRes = await fetch('http://127.0.0.1:47657/session-api/session');
      let isAlreadyRegistered = false;

      if (checkRes.ok) {
        const currentSessionData = await checkRes.json();
        if (currentSessionData && currentSessionData.sessionId === conversationId) {
          isAlreadyRegistered = true;
        }
      }

      if (!isAlreadyRegistered) {
        const res = await fetch('http://127.0.0.1:47657/session-api', {
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
          try { execSync('notify-send "Antigravity" "Lazygitrs session successfully registered"'); } catch (e) { }
        }
      } else {
        bridgeStatus = '✅ Lazygitrs session already registered';
      }
    } catch (e) {
      // lazygitrs is probably not running
      bridgeStatus = '⚠️ Lazygitrs offline';
      fallbackWarning = ' (Start lazygitrs to integrate)';
    }
  }

  // Ensure SSE bridge is running
  try {
    execSync('pgrep -f lazygit-sse-bridge.sh');
  } catch (e) {
    // pgrep exits with 1 if no process matches
    try {
      const sseProcess = spawn('bash', ['/home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-sse-bridge.sh'], {
        detached: true,
        stdio: 'ignore'
      });
      sseProcess.unref();
    } catch (err) {
      bridgeStatus = '❌ SSE Bridge Error';
      fallbackWarning = ' (Using subprocess fallback)';
    }
  }

  // Stdin parsing moved to the top of main()

  // Save the active tmux pane so the SSE bridge knows where to inject keys
  let tmuxPane = process.env.TMUX_PANE || '';
  if (!tmuxPane) {
    try {
      tmuxPane = execSync('tmux display-message -p "#{pane_id}"').toString().trim();
    } catch (e) { }
  }
  if (!tmuxPane) {
    try {
      const panes = execSync('tmux list-panes -a -F "#{pane_id} #{pane_current_command}"').toString();
      const agyPaneLine = panes.split('\n').find(line => line.includes('agy') || line.includes('node'));
      if (agyPaneLine) {
        tmuxPane = agyPaneLine.split(' ')[0];
      }
    } catch (e) { }
  }
  if (tmuxPane) {
    try {
      writeFileSync('/tmp/agy-active-pane.txt', tmuxPane);
    } catch (e) { }
  }

  if (tmuxPane) {
    try {
      // We don't want to spam tmux either, but we can do it on the first run of the hook.
      // Wait, let's only do it if we just registered it to avoid spam.
      if (bridgeStatus === '✅ Registered Lazygitrs session' || bridgeStatus === '⚠️ Lazygitrs offline') {
        execSync(`tmux display-message -t "${tmuxPane}" "[AGY] ${bridgeStatus}${fallbackWarning}"`);
      }
    } catch (e) { }
  }

  // Echo the context back so we don't break the hook pipeline
  if (inputStr.trim()) {
    console.log(JSON.stringify(ctx));
  }

  process.exit(0);
}

main();
