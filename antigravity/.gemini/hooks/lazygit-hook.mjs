#!/usr/bin/env node
import { execSync } from 'node:child_process';
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
    } catch (e) {}
  }
  if (tmuxPane) {
    try {
      writeFileSync('/tmp/agy-active-pane.txt', tmuxPane);
    } catch (e) {}
  }

  // Automatically register the active Antigravity session with lazygitrs!
  if (eventType === 'SessionStart' || eventType === 'PreInvocation') {
    // Look for the conversation ID in the context payload or environment
    const conversationId = ctx.conversationId || ctx.conversation_id || process.env.AGY_CONVERSATION_ID || ctx.id;

    if (conversationId) {
      try {
        await fetch('http://127.0.0.1:47657/session-api', {
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
      } catch (e) {
        // lazygitrs is probably not running, fail silently
      }
    }
  }

  // Echo the context back so we don't break the hook pipeline
  if (!['SessionStart', 'PreInvocation'].includes(eventType)) {
    if (inputStr.trim()) {
      console.log(JSON.stringify(ctx));
    }
  }

  process.exit(0);
}

main();
