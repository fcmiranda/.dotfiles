# OpenCode Tmux Plugin (hooker.ts)

Displays OpenCode session state as an animated icon in the tmux window tab.

## Spinner configuration

### Via env var (one-off)

```sh
OPENCODE_SPINNER=moon opencode
```

### Via config file (persistent)

Create `~/.config/opencode/hooker-config.json`:

```json
{ "spinner": "moon" }
```

With a custom frame interval (ms):

```json
{ "spinner": "minidot", "interval": 60 }
```

> **Priority:** env var → config file → default (`nerd`)

### Available spinners

| Name        | Frames                              | Default interval |
|-------------|-------------------------------------|-----------------|
| `nerd`      | 󰤆 󰤇 󰤈 󰤉 󰤊 󰤋                        | 100ms           |
| `minidot`   | ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏              | 83ms            |
| `dot`       | ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷                  | 100ms           |
| `line`      | \| / - \\                           | 100ms           |
| `jump`      | ⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠                    | 100ms           |
| `pulse`     | █ ▓ ▒ ░                             | 125ms           |
| `points`    | ∙∙∙ ●∙∙ ∙●∙ ∙∙●                    | 143ms           |
| `meter`     | ▱▱▱ ▰▱▱ ▰▰▱ ▰▰▰ ▰▰▱ ▰▱▱ ▱▱▱       | 143ms           |
| `hamburger` | ☱ ☲ ☴ ☲                             | 333ms           |
| `ellipsis`  | `·` `.` `..` `...`                  | 333ms           |
| `globe`     | 🌍 🌎 🌏                             | 250ms           |
| `moon`      | 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘             | 125ms           |
| `monkey`    | 🙈 🙉 🙊                             | 333ms           |
| `arc`       | ◜ ◠ ◝ ◞ ◡ ◟                         | 150ms           |
| `nerdarc`   | ◜󰤆 ◠󰤇 ◝󰤈 ◞󰤉 ◡󰤊 ◟󰤋                  | 120ms           |

## State icons

| State        | Icon | Color  | When                        |
|--------------|------|--------|-----------------------------|
| `busy`       | spinner | yellow | AI processing / tool running |
| `idle`       | 󱥂   | green  | AI finished the prompt      |
| `question`   |    | cyan   | AI asking you something     |
| `retry`      |    | orange | AI retrying                 |
| `permission` | 󰌾 | red    | Tool needs permission       |
