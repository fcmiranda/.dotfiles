// Shared helpers for the antigravity tmux/lazygit hooks.
// Keeps stdin parsing, tmux pane discovery, logging and tmux notify
// in one place so the two hook scripts can't drift.

import { execSync } from 'node:child_process';
import { appendFileSync } from 'node:fs';

/** Append a timestamped line to a /tmp log file. Never throws. */
export function log(file, msg) {
  try {
    appendFileSync(file, `[${new Date().toISOString()}] ${msg}\n`);
  } catch (e) {}
}

/**
 * Read all of stdin, parse it as JSON if non-empty, and return both the
 * raw string and the parsed context. Hooks echo the raw string back so
 * the agy hook pipeline keeps flowing.
 */
export async function readCtx() {
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

/**
 * Discover the active tmux pane id. Falls back to scanning all panes
 * for one running agy/node so we can still target the right window
 * when TMUX_PANE isn't exported (e.g. when the hook runs detached).
 */
export function getActiveTmuxPane() {
  let tmuxPane = process.env.TMUX_PANE || '';
  if (!tmuxPane) {
    try {
      tmuxPane = execSync('tmux display-message -p "#{pane_id}"', { stdio: 'pipe' }).toString().trim();
    } catch (e) {}
  }
  if (!tmuxPane) {
    try {
      const panes = execSync('tmux list-panes -a -F "#{pane_id} #{pane_current_command}"', { stdio: 'pipe' }).toString();
      const agyPaneLine = panes.split('\n').find(line => line.includes('agy') || line.includes('node'));
      if (agyPaneLine) {
        tmuxPane = agyPaneLine.split(' ')[0];
      }
    } catch (e) {}
  }
  return tmuxPane;
}

/** Show a transient tmux display-message in the target pane. Never throws. */
export function notifyTmux(pane, message) {
  if (!pane) return;
  try {
    execSync(`tmux display-message -t "${pane}" "${message}"`, { stdio: 'pipe' });
  } catch (e) {}
}