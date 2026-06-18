import fs from 'node:fs';
import { spawnSync, spawn } from 'node:child_process';

const PID_FILE = '/tmp/agy-spinner.pid';
const WAYBAR_FILE = '/tmp/agy-waybar-state';

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf-8');
}

function getTmuxColor(opt, fallback) {
  const res = spawnSync('tmux', ['show-option', '-gqv', opt], { encoding: 'utf8' });
  return res.stdout?.trim() || fallback;
}

function notify(title, body) {
  try {
    spawnSync('notify-send', ['-a', 'Antigravity', title, body], { stdio: 'ignore' });
  } catch (e) {}
}

function stopSpinner() {
  if (fs.existsSync(PID_FILE)) {
    try {
      const pid = parseInt(fs.readFileSync(PID_FILE, 'utf8'), 10);
      process.kill(pid, 'SIGTERM');
    } catch (e) { }
    try { fs.unlinkSync(PID_FILE); } catch (e) { }
  }
}

function startSpinner(tmuxPane) {
  stopSpinner(); // ensure no duplicates

  // Resolve spinner config in a detached script to keep animating
  const spinnerScript = `
    const fs = require('fs');
    const { spawnSync } = require('child_process');
    const pane = '${tmuxPane}';
    
    const SPINNERS = {
      arc: { frames: ["◜", "◠", "◝", "◞", "◡", "◟"], interval: 150 },
      moon: { frames: ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"], interval: 125 },
      minidot: { frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"], interval: 83 }
    };
    
    let spinnerName = process.env.AGY_SPINNER || 'arc';
    let intervalOverride = null;
    let colorOverride = null;
    
    try {
      const cfg = JSON.parse(fs.readFileSync(process.env.HOME + '/.config/agy/hooker-config.json', 'utf8'));
      if (!process.env.AGY_SPINNER && cfg.spinner) spinnerName = cfg.spinner;
      if (typeof cfg.interval === 'number') intervalOverride = cfg.interval;
      if (typeof cfg.color === 'string') colorOverride = cfg.color;
    } catch(e){}
    
    const chosen = SPINNERS[spinnerName] || SPINNERS.arc;
    const frames = chosen.frames;
    const interval = intervalOverride || chosen.interval;
    
    const tmuxColor = spawnSync('tmux', ['show-option', '-gqv', '@ACCENT_COLOR'], {encoding:'utf8'}).stdout || '';
    const color = colorOverride || tmuxColor.trim() || 'yellow';
    
    try { fs.writeFileSync('${WAYBAR_FILE}', 'busy', 'utf8'); } catch(e){}
    spawnSync('pkill', ['-RTMIN+13', 'waybar']);

    let i = 0;
    const timer = setInterval(() => {
      const frame = frames[i++ % frames.length];
      const val = '#[fg=' + color + ']' + frame + ' #[fg=default]';
      spawnSync('tmux', [
        'set-option', '-w', '-t', pane, '@agy_state', val, 
        ';', 'set-option', '-w', '-t', pane, '@agy_state_raw', 'busy', 
        ';', 'refresh-client', '-S'
      ]);
    }, interval);

    process.on('SIGTERM', () => {
      clearInterval(timer);
      process.exit(0);
    });
  `;
  const child = spawn('node', ['-e', spinnerScript], { detached: true, stdio: 'ignore' });
  fs.writeFileSync(PID_FILE, child.pid.toString(), 'utf8');
  child.unref();
}

function setStaticState(tmuxPane, stateStr, rawState) {
  stopSpinner();
  try { fs.writeFileSync(WAYBAR_FILE, rawState, 'utf8'); } catch (e) { }
  spawnSync('pkill', ['-RTMIN+13', 'waybar'], { stdio: 'ignore' });
  if (!tmuxPane) return;
  spawnSync('tmux', [
    'set-option', '-w', '-t', tmuxPane, '@agy_state', stateStr,
    ';', 'set-option', '-w', '-t', tmuxPane, '@agy_state_raw', rawState,
    ';', 'refresh-client', '-S'
  ], { stdio: 'ignore' });
}

function bell(tmuxPane, action) {
  if (!tmuxPane) return;

  const tmuxSession = (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#S"], { encoding: "utf8" }).stdout || "").trim();
  const tmuxWindowId = (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#{window_id}"], { encoding: "utf8" }).stdout || "").trim();

  // Don't ring bell if already focused
  const listClients = spawnSync("tmux", ["list-clients", "-F", "#{client_session} #{window_id}"], { encoding: "utf8" }).stdout || "";
  const anyOtherClient = listClients
    .trim().split("\n").filter(Boolean)
    .some((line) => {
      const [cs, wid] = line.split(" ");
      return !(cs === tmuxSession && wid === tmuxWindowId);
    });

  if (!anyOtherClient) return;

  const tmuxWindowIndex = (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#I"], { encoding: "utf8" }).stdout || "").trim();
  const tmuxWindow = (spawnSync("tmux", ["display-message", "-t", tmuxPane, "-p", "#W"], { encoding: "utf8" }).stdout || "").trim();

  const msg = `  #[fg=cyan]${tmuxWindowIndex}:${tmuxWindow} › ${action} #[fg=yellow](i)#[fg=default]`;
  spawnSync("tmux", ["set", "-g", "@agy_last_bell", tmuxPane]);
  spawnSync("tmux", ["set", "-g", "@agy_bell", msg, ";", "refresh-client", "-S"]);

  const cleaner = spawn("sh", ["-c", `sleep 7 && tmux set -g @agy_bell '' && tmux refresh-client -S`], { detached: true, stdio: "ignore" });
  cleaner.unref();
}

async function main() {
  const eventType = process.argv[2];
  const tmuxPane = process.env.TMUX_PANE || '';

  try {
    const inputStr = await readStdin();
    const context = inputStr.trim() ? JSON.parse(inputStr) : {};

    // Debug logging
    try { fs.appendFileSync('/tmp/agy-plugin-debug.log', `Hook ${eventType}: ${inputStr}\n`); } catch (e) { }

    if (eventType === 'SessionStart' || eventType === 'PreInvocation') {
      notify('Antigravity Hooks Active', 'Session has started and hooks are connected.');
      if (tmuxPane) {
        spawnSync('tmux', [
          'set', '-g', '@agy_state', '',
          ';', 'set-option', '-w', '-t', tmuxPane, 'automatic-rename', 'off',
          ';', 'rename-window', '-t', tmuxPane, '󰚩'
        ]);
        startSpinner(tmuxPane);
      }
    }
    else if (eventType === 'PreToolUse') {
      const toolName = context.tool_name || context.tool || '';
      // Map ask_user / permission prompts to question state
      if (toolName === 'ask_user' || toolName === 'question' || toolName === 'request_permission') {
        const cQuest = getTmuxColor('@PREFIX_COLOR', '#cba6f7');
        setStaticState(tmuxPane, `#[fg=${cQuest}]󱜻 #[fg=default]`, 'question');
        bell(tmuxPane, '󱜻 question');
      } else {
        if (tmuxPane) startSpinner(tmuxPane);
      }
      console.log(JSON.stringify(context)); // Allow the tool by echoing context back
      process.exit(0);
    }
    else if (eventType === 'PostToolUse') {
      // Keep state as busy until Stop is called or next tool is pre-used
      process.exit(0);
    }
    else if (eventType === 'Stop' || eventType === 'PostInvocation') {
      const cIdle = getTmuxColor('@CURRENT_COLOR', '#94e2d5');
      setStaticState(tmuxPane, `#[fg=${cIdle}]󱥂 #[fg=default]`, 'idle');
      bell(tmuxPane, '󱥂 finished');
      notify('Antigravity Finished', 'The agent has completed the request.');
      process.exit(0);
    }
    else {
      console.log(JSON.stringify(context));
      process.exit(0);
    }

  } catch (err) {
    try { fs.appendFileSync('/tmp/agy-plugin-debug.log', `Error: ${err.message}\n`); } catch (e) { }
    if (eventType === 'PreToolUse') console.log(JSON.stringify(context || {}));
    process.exit(0);
  }
}

main();
