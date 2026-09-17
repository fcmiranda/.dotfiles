# Open-Source Strategy & Architecture Plan: The Terminal AI Cockpit Stack

> **Canonical Blueprint for Packaging & Distributing the `acpd` + `lazygitrs` + `mm` + `tmux` Ecosystem**  
> Based on open-source production engineering principles from [*Fabio Akita's "Boas práticas de projetos de código aberto com LLM - O Mínimo" (2026)*](https://akitaonrails.com/2026/05/30/boas-praticas-projetos-codigo-aberto-llm-o-minimo/).

---

## 1. Executive Vision & The Akita Golden Rule

### 1.1 "Nobody Cares About Your Stack — Focus on the Problem"
The biggest trap of AI-assisted projects is showcasing the tech stack (*"Axum 0.8 Tokio JSON-RPC daemon, Rust TUI git client, and Nucleo fuzzy matcher"*). As Akita emphasizes: **nobody cares**. 

The README and value proposition must lead with the concrete problem solved for the user:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   THE CORE PROBLEM                                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. AI Agents destroy terminal UX: Active token streaming causes popup borders to vanish │
│    and search inputs to break due to background ANSI scroll redraws.                   │
│ 2. Rapid tool chaining causes status bar flicker (10+ state flips/second).              │
│ 3. Double-debounce latency: Nested timer delays cause status bar lag (>1 second).       │
│ 4. Context switching is disjointed: No seamless way to send diff review notes from git  │
│    directly into an active AI agent's chat pane without manual copy-paste tearing.      │
│ 5. Polling timers (`status-interval 1`) drain CPU and laptop battery while idle.       │
│ 6. Shared temporary files (`/tmp/tmux-backdrop.ansi`) collide in multi-pane setups and   │
│    expose sensitive terminal buffers to other local users.                              │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                  THE COCKPIT SOLUTION                                   │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ • Event-Driven status bar (`status-interval 0`, 0% idle CPU) with consolidated debounce.│
│ • Frozen Snapshot Backdrop Popups (`display-popup` never flickers or drops borders).     │
│ • Per-pane UID-isolated backdrop buffers (`/tmp/tmux-backdrop-${UID}-${PANE}.ansi`).    │
│ • 1-Key Inline Diff Review to AI via bracketed paste (`lazygitrs` -> `antigravity`).     │
│ • Sub-millisecond fuzzy navigation & live preview (`matchmaker` with inotify reload).   │
│ • Zero-configuration 1-command install (`curl -fsSL ... | bash`) in under 30 seconds.  │
│ • Zero compilation: Pre-built static musl & Darwin binaries bundled in a single repo.   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Technical Audit of the Components

### 2.1 `acpd` (Agent Client Protocol Daemon)
- **Path:** `/home/fecavmi/dev/github/acpd`
- **Current State:**
  - Robust core: Axum 0.8, Tokio 1.52, nix 0.29, sd-notify.
  - JSON-RPC 2.0 at `POST /rpc` (`agentState/update`, `agentState/list`, `tmux.*`).
  - 11 unit tests passing (`cargo test`).
  - Systemd user service unit (`systemd/acpd.service`).
  - **Token generation is already dynamic:** [`acpd/src/auth.rs`](file:///home/fecavmi/dev/github/acpd/src/auth.rs#L6-L18) correctly checks `$XDG_RUNTIME_DIR/acpd/token`, then `$HOME/.cache/acpd/token`, then `/tmp/acpd-<uid>/token` with `0600` permissions. It contains **no hardcoded paths**.
  - **Unpushed Git Commit:** Local branch `main` is ahead of `origin/main` by 1 commit (`2362508 ci: add multi-platform release workflow and local dist recipes`).
- **Gaps & Discrepancies:**
  - **Hardcoded Path Fallbacks & Omarchy Coupling in `adapters.rs`:**
    - [`src/adapters.rs:529`](file:///home/fecavmi/dev/github/acpd/src/adapters.rs#L529) executes: `let home = std::env::var("HOME").unwrap_or_else(|_| "/home/fecavmi".to_string());`.
    - Lines 533-534 and 572-575 hardcode lookup paths to `~/.config/omarchy/sounds/`.
    - *Remediation:* Replace `/home/fecavmi` with portable `dirs::home_dir()` or return `None`, and generalize sound lookups to `$XDG_CONFIG_HOME/terminal-ai-cockpit/sounds/` with graceful ANSI fallbacks.
  - **Nested Double-Debounce Bug & Architecture Cleanup:**
    - In [`acpd/src/api.rs:290-309`](file:///home/fecavmi/dev/github/acpd/src/api.rs#L290-L309), `update_agent_state` runs an idle debounce task sleeping for `delay_ms = state.idle_debounce_ms` (defaults to **650ms** in [`daemon.rs:42`](file:///home/fecavmi/dev/github/acpd/src/daemon.rs#L42)).
    - When that timer completes, it calls `adapter.update(&update_clone)`.
    - In [`acpd/src/adapters.rs:361-368`](file:///home/fecavmi/dev/github/acpd/src/adapters.rs#L361-L368), `TmuxAdapter::update` receives the `Idle` state and spawns a **second** debouncing task sleeping for another **400ms** (`tokio::time::sleep(tokio::time::Duration::from_millis(400)).await`). Meanwhile, `WaybarAdapter` updates immediately at 650ms, causing a **400ms state desynchronization** between Waybar and Tmux!
    - **Total Idle transition latency:** `650ms + 400ms = 1050ms` (> 1 second!).
    - *Remediation & Architecture Cleanup:* Completely eliminate the redundant 400ms idle task in `adapters.rs:361-368`, establishing `api.rs` as the single authoritative debounce coordinator. Tune the single idle debounce in `api.rs` from 650ms down to **300ms** (configured in `daemon.rs:42`), slashing idle flip latency from 1,050ms to 300ms while preserving flicker prevention during rapid tool chaining and keeping all status adapters synchronized.
  - **Clippy & Rustfmt Failures (Blocking CI):**
    - `cargo fmt --check` fails with formatting diffs in `src/adapters.rs` (lines 403, 585, 626, 644) and `src/api.rs` (lines 1003, 1010, 1014).
    - `cargo clippy --all-targets --all-features -- -D warnings` fails with 4 `clippy::collapsible_if` errors in `src/adapters.rs`:
      - Line 373: nested `if let Some(prev) = states.get(&pane_id)` and `if prev == &AgentState::Idle`.
      - Line 413: nested `if let Some(prev) = states.get(&update.pane_id)` and `if prev == &update.state`.
      - Line 520: nested `if path.starts_with("~/")` and `if let Ok(home) = std::env::var("HOME")`.
      - Line 620: nested `if let Some(cfg) = &self.config` and `if !cfg.enabled`.
  - **No Automated CI:** `.github/workflows/` only contains `release.yml`. Needs automated PR linting (`cargo fmt --check`, `cargo clippy -D warnings`), test suite execution, and security scanning (`cargo audit`).

### 2.2 `lazygitrs` (`fecavmi` branch)
- **Path:** `/home/fecavmi/dev/github/lazygitrs/fecavmi`
- **Current State:**
  - Custom commits on `fecavmi`:
    - `afaa30872`: Added `--commits` CLI flag and `ctrl+g` dual-diff toggle between files and HEAD.
    - `c92cbf564`: Dynamic keybinding display in status bar, local port file resolution (`.lazygitrs.port`) for concurrent git worktrees.
  - Headless zero-dependency AI integration (`AI_INTEGRATION_ARCHITECTURE.md`):
    - Diffs support inline review notes. Pressing `S` triggers `notifyCommand` stored in `.lines.json`.
    - Spawns `lazygit-tmux-injector.sh` using bracketed paste (`tmux paste-buffer -p`) to atomically deliver multi-line prompts to the AI agent pane.
  - **Unpushed Git State (70+ Commits Ahead):**
    - Local branch `fecavmi` has **no remote tracking branch** on `origin` and is **over 70 commits ahead** of `origin/main` (containing all AI review integration, worktree support, `--commits` flag, and UI improvements). This branch must be pushed to `origin/fecavmi` (or a release branch) before CI can run on GitHub.
  - **282 Clippy Errors (Blocking `-D warnings` in CI):**
    - Running `cargo clippy` on the `fecavmi` branch outputs **282 compiler warnings** (183 automatically fixable via `cargo clippy --fix`, remainder requiring manual refactoring for `collapsible_if`, `let_else`, doc comments, and manual iterator conversions).
    - This completely blocks any quality gate CI enforcing `-D warnings`.
    - *Remediation:* Run scoped `cargo clippy --fix --bin "lazygitrs" -p lazygitrs` and manually clean the remaining lint issues before enabling strict CI.
  - **Tree-Sitter C/C++ Cross-Compilation Bottleneck:**
    - `lazygitrs` depends on 13 tree-sitter language grammar crates (`tree-sitter-rust`, `tree-sitter-javascript`, `tree-sitter-typescript`, `tree-sitter-python`, `tree-sitter-go`, `tree-sitter-bash`, `tree-sitter-toml-ng`, `tree-sitter-json`, `tree-sitter-css`, `tree-sitter-html`, `tree-sitter-md`, etc.).
    - Each tree-sitter crate contains C/C++ grammar sources (`parser.c` and scanner files) compiled via `cc` in crate `build.rs`.
    - Naive cross-compilation via `cargo build --target x86_64-unknown-linux-musl` or `aarch64-unknown-linux-musl` fails in standard CI runner environments because target C toolchains (`musl-gcc`, `aarch64-linux-gnu-gcc`) are absent.
    - *Remediation:* CI must avoid naive `cargo build` for multi-arch releases. It must employ containerized builds via `cross-rs/cross` or `cargo-zigbuild` (with `zig` acting as the multi-arch C cross-compiler) to produce true static musl Linux and Apple Darwin binaries.
  - **Repository Pollution via `.lines.json`:**
    - In [`src/pager/notes_store.rs:152, 198`](file:///home/fecavmi/dev/github/lazygitrs/fecavmi/src/pager/notes_store.rs#L152) and [`src/gui/mod.rs:9684`](file:///home/fecavmi/dev/github/lazygitrs/fecavmi/src/gui/mod.rs#L9684), `lazygitrs` persists inline review notes and session data to `.lines.json` directly in the active repository root (`repo_path.join(".lines.json")`).
    - When users launch `lazygitrs` inside any local Git repository, `.lines.json` is generated in the working tree. In repositories lacking `.lines.json` in their local `.gitignore`, it immediately surfaces as an untracked/modified file in `git status`, risking accidental commits to user codebases (as seen in `matchmaker` and `.dotfiles`).
    - *Remediation:* Two-tier mitigation:
      1. *Immediate Stack Layer:* Installer configures a global gitignore entry (`git config --global core.excludesFile ~/.gitignore_global` containing `.lines.json`).
      2. *Engine Layer:* Refactor `lazygitrs` to store review notes inside `.git/info/lines.json` (inside `.git/`, which Git ignores natively) or `$XDG_STATE_HOME/lazygitrs/<repo-hash>/lines.json`, guaranteeing a pristine working tree.
  - **Installer Anti-Pattern in `install.sh`:**
    - Lines 13-20 prioritize `cargo install lazygitrs` if `cargo` is present. This violates Akita's golden rule: it forces developers to compile dozens of crates (taking 5-10 minutes) instead of downloading pre-built binaries, and pulls upstream `Blankeos/lazygitrs` from crates.io which **lacks** the `fecavmi` `--commits` and worktree features!
  - **Hardcoded Injector Invocation:**
    - In [`antigravity/.gemini/hooks/lazygit-hook.mjs:176`](file:///home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-hook.mjs#L176), `notifyCommand` hardcodes:
      ```javascript
      notifyCommand: `/home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/lazygit-tmux-injector.sh {{workspace_path}} {{prompt}}`
      ```
    - Must resolve `lazygit-tmux-injector.sh` portably via `$PATH` or an environment variable (`$TERMINAL_AI_INJECTOR`).

### 2.3 `matchmaker` / `mm` (`fecavmi` branch)
- **Path:** `/home/fecavmi/dev/github/matchmaker/fecavmi`
- **Current State:**
  - Workspace containing `matchmaker-cli` and `matchmaker-lib` with Nucleo fuzzy matcher.
  - Enhanced features on `fecavmi`:
    - `6e66ccf`: Alternate screen, Mode 2026 sync, zero horizontal striping.
    - `a7a436b`: `-w/--watch` live-reload with inotify and debouncing.
    - `bc5624b`: Inline Kitty graphics placeholders with LRU cache.
    - `e224cc5` & `bdc7d36`: Mermaid diagram fence extraction, panning, zooming, and toggle.
- **Gaps & Discrepancies:**
  - **25 Unpushed Commits:**
    - Local branch `fecavmi` is 25 commits ahead of `origin/fecavmi` (`6e66ccf`, `11e4c4b`, `a7a436b`, `bc5624b`, `e224cc5`, `0e464b5`, etc.). These must be pushed to remote to ensure reproducible builds.
  - **2,000+ Line Rustfmt Formatting Diff:**
    - Running `cargo fmt --check` outputs a **2,216-line formatting diff** across the codebase. A blanket `cargo fmt` would severely pollute `git blame` history and create catastrophic merge conflicts with upstream PRs.
    - *Remediation:* Scope `rustfmt --check` in CI strictly to changed files or PR diffs, or execute formatting as a dedicated isolated cleanup commit recorded in `.git-blame-ignore-revs`.
  - **Clippy Warnings & Macro Expansion Issues (Blocking `-D warnings`):**
    - `cargo clippy` emits **95 warnings** across `matchmaker-cli`, `matchmaker-partial`, and `matchmaker-partial-macros` (manual `div_ceil` reimplementations, doc comments, clamp patterns, unused lifetimes, identical branch blocks).
    - Procedural macros in `matchmaker-partial-macros` generate code that triggers clippy warnings (such as collapsible `if` blocks) upon expansion.
    - `matchmaker-cli/src/fm.rs` has 12 unused code warnings: `CurrentItem`, `UndoAction::{DeletedFile, Copied, Moved}`, `DeleteOverlay`, `CreateOverlay`, `RenameOverlay`, `UnzipOverlay`, `input_width`, `visible_suffix`.
    - *Remediation:* Clean up procedural macro expansions or add targeted inner `#![allow(clippy::...)]` gates, resolve dead code in `fm.rs` with `#[allow(dead_code)]` or clean removal, and collapse redundant `if` branches.

### 2.4 `tmux` & Backdrop Snapshot Layer
- **Path:** `/home/fecavmi/.dotfiles/main/tmux/.config/tmux/`
- **Current State:**
  - Floating popup isolation via frozen ANSI snapshots rendered into a background pane.
  - 100% event-driven status bar (`status-interval 0`) with custom pills (`@ai_agent_state`, `@ai_agent_bell`).
  - Interactive window switcher with live preview and key actions (`c` create, `d` kill) powered by `window-picker.toml`.
- **Gaps & Race Conditions:**
  - **The Shared `/tmp/tmux-backdrop.ansi` Race Condition & Security Hole:**
    - 5 separate scripts write directly to a shared, hardcoded `/tmp/tmux-backdrop.ansi`:
      1. [`tmux/.config/tmux/lazygitrs-popup.sh:55`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/lazygitrs-popup.sh#L55)
      2. [`tmux/.config/tmux/sesh-picker.sh:21`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/sesh-picker.sh#L21)
      3. [`tmux/.config/tmux/window-picker.sh:24`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/window-picker.sh#L24)
      4. [`tmux/.config/tmux/scrollback-extract.sh:40`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/scrollback-extract.sh#L40)
      5. [`tmux/.config/tmux/dir-peek.sh:48`](file:///home/fecavmi/.dotfiles/main/tmux/.config/tmux/dir-peek.sh#L48)
    - *Bugs caused:* Concurrent popups in different panes or sessions clobber each other's backdrop. On multi-user systems, terminal scrollbacks containing sensitive code/credentials are exposed to other users in `/tmp`.
    - *Remediation:* Create a unified helper script `tmux-popup-isolate.sh` that scopes the backdrop to:
      `/tmp/tmux-backdrop-${UID}-${CURRENT_PANE#%}.ansi` with strict `0600` permissions and automated cleanup traps (`rm -f`).
  - **Coupling to Omarchy Theme:**
    - Scripts source `~/.local/state/omarchy/current/theme/tmux-style.sh` without checking if Omarchy is installed, breaking on generic Linux/macOS environments.

### 2.5 Agent Client Hooks Layer
- **Paths:**
  - `antigravity/.gemini/hooks/hook-lib.mjs`
  - `opencode/.config/opencode/plugins/hooker.ts`
- **Gaps & Hardcoding:**
  - While `acpd/src/auth.rs` is clean, both client hooks hardcode UID `1001` and home path `/home/fecavmi`:
    - [`hook-lib.mjs:92-99`](file:///home/fecavmi/.dotfiles/main/antigravity/.gemini/hooks/hook-lib.mjs#L92-L99):
      ```javascript
      const uid = process.getuid?.() || 1001;
      const candidates = [
        join(xdgRuntime, 'acpd', 'token'),
        join(tmpdir(), `acpd-${uid}`, 'token'),
        join(process.env.HOME || '/home/fecavmi', '.cache', 'acpd', 'token'),
        `/run/user/1001/acpd/token`,
      ];
      ```
    - [`hooker.ts:8-15`](file:///home/fecavmi/.dotfiles/main/opencode/.config/opencode/plugins/hooker.ts#L8-L15):
      ```typescript
      const uid = process.getuid?.() ?? 1001;
      const candidates = [
        join(xdgRuntime, "acpd", "token"),
        join(tmpdir(), `acpd-${uid}`, "token"),
        join(process.env.HOME || "/home/fecavmi", ".cache", "acpd", "token"),
        `/run/user/1001/acpd/token`,
      ];
      ```
  - *Remediation:* Strip hardcoded `1001` and `/home/fecavmi` fallbacks. Use standard `$HOME`, `$XDG_RUNTIME_DIR`, and `os.userInfo().uid`.

---

## 3. The Three Akita Pillars for the New Stack

### Pillar 1: Universal Installation Surface ("Compile Once, Repackage Many")

Users must never be forced to compile from source. The stack will provide a unified installer and native packages across all major distributions.

```
                  ┌─────────────────────────────────────────┐
                  │       GitHub Actions Release Tag        │
                  │                (v*.*.*)                 │
                  └───────────────────┬─────────────────────┘
                                      │
                         [Compile Native Binaries]
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         ▼                            ▼                            ▼
  Linux x86_64/ARM64           macOS Universal              Windows x86_64
  (musl - static)             (Apple Silicon/Intel)            (msvc)
         │                            │                            │
         └────────────────────────────┼────────────────────────────┘
                                      │
                     Single Unified Tarball + .sha256
                   (terminal-ai-cockpit-v*.*.*-<arch>)
                                      │
         ┌───────────────┬────────────┴───┬───────────────┬────────────────┐
         ▼               ▼                ▼               ▼                ▼
    install.sh       AUR (-bin)     Homebrew Tap        mise           Docker
   (1-command)      (PKGBUILD)       (Formula)       (gh releases)    (runtime)
```

#### 1. Universal One-Liner (`install.sh`)
```bash
curl -fsSL https://raw.githubusercontent.com/fcmiranda/terminal-ai-cockpit/main/install.sh | bash
```

**Installer Logic (Strict Zero-Compile Guarantee):**
1. **Never compile:** Never invoke `cargo install` or `cargo build`.
2. **Arch & OS Detection:** Detects `linux` / `macos` and `x86_64` / `aarch64`.
3. **Bundle Download:** Fetches the unified archive containing pre-built `acpd`, `lazygitrs`, and `mm`.
4. **Integrity Check:** Validates `sha256sum` before extraction to `~/.local/bin/` (or `--prefix`).
5. **Backdrop Isolation Helper:** Installs `tmux-popup-isolate.sh` to `~/.local/bin/`.
6. **Tmux Plugin Registration:**
   - Appends `run-shell "~/.tmux/plugins/terminal-ai-cockpit/cockpit.tmux"` to `~/.tmux.conf` or TPM config.
7. **Systemd User Service:**
   - Enables `acpd.service` via `systemctl --user enable --now acpd`.
8. **Agent Hook Linking:**
   - Detects installed AI agents (`antigravity`, `opencode`, `claude`) and links portable hooks.

---

### Pillar 2: Tests, CI & Automated Tagged Releases

#### 2.1 Quality Gate CI Pipeline (`.github/workflows/ci.yml`)
Every commit and PR must pass through an automated gate before merging:

```yaml
name: CI Suite

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy
      - uses: Swatinem/rust-cache@v2
      
      # 1. Format verification (requires prior formatting of adapters.rs and api.rs)
      - name: Rustfmt Check
        run: cargo fmt --all --check

      # 2. Strict Clippy (requires prior fix of 4 collapsible_if errors)
      - name: Clippy Warnings as Errors
        run: cargo clippy --all-targets --all-features -- -D warnings

      # 3. Complete Test Suite
      - name: Run Tests
        run: cargo test --all-targets --all-features

      # 4. Dependency Security Audit
      - name: Security Audit
        uses: rustsec/audit-check@v1.4.1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

#### 2.2 The Two-Tier Release Packaging Model

A critical flaw in naive stack packaging is attempting to build every component in a single monolithic CI workflow. As revealed in the technical audit:
1. `lazygitrs` depends on 13 tree-sitter C/C++ grammar parsers requiring specialized cross-compilers (`musl-gcc`, `aarch64-linux-gnu-gcc` via `cross` or `cargo-zigbuild`).
2. `acpd` is a pure Tokio/Axum asynchronous daemon.
3. `matchmaker` is a standalone workspace with Nucleo fuzzy matching and terminal graphics.

Compiling all three engines in a single monolithic GitHub Actions runner causes massive CI timeouts (15+ minutes), cross-compilation toolchain collisions, and destroys the modular independence of the underlying open-source projects.

To satisfy Akita's principles of maintainability and zero-friction delivery, the stack implements a **Two-Tier Release Architecture**:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        TIER 1: SUB-REPO ENGINE RELEASES                                │
├──────────────────────────┬───────────────────────────┬─────────────────────────────────┤
│ fcmiranda/acpd           │ fcmiranda/lazygitrs       │ fcmiranda/matchmaker            │
│ (v*.*.* release tag)     │ (v*.*.* release tag)      │ (v*.*.* release tag)            │
│ Native Rust Toolchain    │ cross-rs / cargo-zigbuild │ Native Rust Toolchain           │
│ (musl + Darwin static)   │ (13 C parsers + musl)     │ (musl + Darwin static)          │
└────────────┬─────────────┴─────────────┬─────────────┴────────────────┬────────────────┘
             ▼                           ▼                              ▼
     acpd-<target>.tar.gz       lazygitrs-<target>.tar.gz       mm-<target>.tar.gz
             │                           │                              │
             └───────────────────────────┼──────────────────────────────┘
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               TIER 2: terminal-ai-cockpit UMBRELLA RELEASE (NO COMPILATION)             │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. Triggered by release tag (e.g., v1.0.0).                                           │
│ 2. Reads pinned engine versions from cockpit-manifest.json.                            │
│ 3. Downloads pre-compiled Tier 1 release artifacts via GitHub API / gh release.       │
│ 4. Verifies SHA256 checksums of all upstream binaries.                                 │
│ 5. Bundles pre-built binaries with cockpit.tmux, install.sh, systemd units, hooks.     │
│ 6. Generates unified distribution archive: terminal-ai-cockpit-v1.0.0-<target>.tar.gz  │
│ 7. Slices CHANGELOG.md via Akita's awk script and publishes umbrella GitHub Release.  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

##### Tier 1: Sub-Repository Engine Cross-Compilation Pipeline
For `lazygitrs` (and similarly for `acpd` and `matchmaker`), cross-compilation handles C grammar sources via `cross`:

```yaml
# In fcmiranda/lazygitrs: .github/workflows/release.yml
name: Engine Release

on:
  push:
    tags: ['v*.*.*']

jobs:
  build:
    strategy:
      matrix:
        include:
          - target: x86_64-unknown-linux-musl
            os: ubuntu-latest
            use_cross: true
          - target: aarch64-unknown-linux-musl
            os: ubuntu-latest
            use_cross: true
          - target: aarch64-apple-darwin
            os: macos-latest
            use_cross: false
          - target: x86_64-apple-darwin
            os: macos-13
            use_cross: false
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          targets: ${{ matrix.target }}
      - uses: Swatinem/rust-cache@v2

      # Pre-built cross binary (2 seconds vs 4 minutes cargo install)
      - name: Install cross
        if: matrix.use_cross
        uses: taiki-e/install-action@cross

      - name: Build Binary (with C tree-sitter support)
        run: |
          if [ "${{ matrix.use_cross }}" = "true" ]; then
            cross build --release --target ${{ matrix.target }}
          else
            cargo build --release --target ${{ matrix.target }}
          fi

      # Cross-platform checksum (shasum on macOS, sha256sum on Linux)
      - name: Package & Checksum
        run: |
          TAR_NAME="lazygitrs-${{ github.ref_name }}-${{ matrix.target }}.tar.gz"
          tar -czf "$TAR_NAME" -C target/${{ matrix.target }}/release lazygitrs
          if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$TAR_NAME" > "${TAR_NAME}.sha256"
          else
            shasum -a 256 "$TAR_NAME" > "${TAR_NAME}.sha256"
          fi

      - name: Upload Release Asset
        uses: softprops/action-gh-release@v2
        with:
          files: |
            lazygitrs-*.tar.gz
            lazygitrs-*.sha256
```

##### Tier 2: Umbrella Assembly Pipeline (`terminal-ai-cockpit`)
The meta-repository CI builds **nothing from source**. It is an assembly and packaging pipeline:

```yaml
# In fcmiranda/terminal-ai-cockpit: .github/workflows/release.yml
name: Cockpit Umbrella Release

on:
  push:
    tags: ['v*.*.*']
  workflow_dispatch:

permissions:
  contents: write

jobs:
  bundle-release:
    strategy:
      matrix:
        target:
          - x86_64-unknown-linux-musl
          - aarch64-unknown-linux-musl
          - x86_64-apple-darwin
          - aarch64-apple-darwin
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Assemble Pre-Compiled Cockpit Bundle
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          TARGET: ${{ matrix.target }}
          TAG: ${{ github.ref_name }}
        run: |
          mkdir -p bundle/bin bundle/tmux bundle/hooks bundle/systemd
          
          # Read pinned versions from manifest
          ACPD_VER=$(jq -r .acpd cockpit-manifest.json)
          LZG_VER=$(jq -r .lazygitrs cockpit-manifest.json)
          MM_VER=$(jq -r .matchmaker cockpit-manifest.json)
          
          # Fetch pre-built Tier 1 artifacts
          gh release download "$ACPD_VER" --repo fcmiranda/acpd --pattern "*${TARGET}*.tar.gz" -O acpd.tar.gz
          gh release download "$LZG_VER" --repo fcmiranda/lazygitrs --pattern "*${TARGET}*.tar.gz" -O lazygitrs.tar.gz
          gh release download "$MM_VER" --repo fcmiranda/matchmaker --pattern "*${TARGET}*.tar.gz" -O mm.tar.gz
          
          tar -xzf acpd.tar.gz -C bundle/bin/
          tar -xzf lazygitrs.tar.gz -C bundle/bin/
          tar -xzf mm.tar.gz -C bundle/bin/
          
          # Copy orchestration scripts and plugins
          cp scripts/tmux-popup-isolate.sh bundle/bin/
          cp scripts/lazygit-tmux-injector.sh bundle/bin/
          chmod +x bundle/bin/*
          cp -r tmux/* bundle/tmux/
          cp -r hooks/* bundle/hooks/
          cp systemd/acpd.service bundle/systemd/
          
          # Package final bundle and sha256
          BUNDLE_NAME="terminal-ai-cockpit-${TAG}-${TARGET}.tar.gz"
          tar -czf "$BUNDLE_NAME" -C bundle .
          sha256sum "$BUNDLE_NAME" > "${BUNDLE_NAME}.sha256"

      - name: Extract Changelog Section
        id: changelog
        run: |
          VERSION="${GITHUB_REF_NAME#v}"
          awk -v ver="$VERSION" '
            BEGIN { hdr = "## [" ver "]" }
            index($0, hdr) == 1 { flag=1; next }
            flag && index($0, "## [") == 1 { exit }
            flag { print }
          ' CHANGELOG.md > release_notes.md

      - name: Publish GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          body_path: release_notes.md
          files: |
            terminal-ai-cockpit-*.tar.gz
            terminal-ai-cockpit-*.sha256
          token: ${{ secrets.GITHUB_TOKEN }}
```

---

### Pillar 3: Real Deploy & Decoupled Configuration

#### 3.1 Eliminating Dotfiles Hardcoding & Portable Theming
All references to user-specific dotfiles and themes are replaced with portable tmux options and fallbacks:

```bash
# Portable Tmux Theme Resolution:
COCKPIT_BORDER="${TMUX_COCKPIT_BORDER_COLOR:-$(tmux show-option -gqv @cockpit_border_color 2>/dev/null || echo '#cba6f7')}"
COCKPIT_BG="${TMUX_COCKPIT_BG_COLOR:-$(tmux show-option -gqv @cockpit_bg_color 2>/dev/null || echo 'default')}"
```

#### 3.2 Production-Ready Backdrop Snapshot Helper (`tmux-popup-isolate.sh`)

The helper script resolves all multi-pane race conditions, layout disruptions, and security risks. It incorporates:
1. **Full CLI option parsing:** Transparently handles arbitrary `display-popup` flags (`-w`, `-h`, `-x`, `-y`, `-d`, `-S`, `-s`, `-b`, `-T`, `-c`, `-e`, `-t`, `-E`, `-EE`, `-B`, `-C`, `-k`, `-N`) and executes trailing user commands.
2. **Conditional Idle Bypass:** Checks `#{@ai_agent_state_raw}`. If the AI agent is idle or inactive, it bypasses the snapshot backdrop pane entirely and launches `display-popup` directly, ensuring **zero overhead and instantaneous launch**.
3. **Pane Zooming & User Zoom Preservation (`resize-pane -Z`):** Zooms the frozen backdrop pane so the snapshot spans the entire terminal window without distorting splits. On cleanup, it restores the user's prior `window_zoomed_flag` state.
4. **UID & Raw Pane Scoping with Atomic umask:** Isolates temporary backdrops to `/tmp/tmux-backdrop-${UID}-${RAW_PANE}.ansi` created atomically via `(umask 077 && : > "$BACKDROP_FILE")`.
5. **Deterministic Cleanup & Focus Restoration:** Uses `trap cleanup EXIT INT TERM` to guarantee automatic pane destruction, file deletion, automatic-rename restoration, and focus preservation.

```bash
#!/usr/bin/env bash
# ~/.local/bin/tmux-popup-isolate.sh
# Hardened, zero-flicker Tmux popup isolator.
# Freezes terminal backdrop during active AI streaming to eliminate redraw flicker.
set -euo pipefail

POPUP_ARGS=()
CMD_ARGS=()

# 1. Parse all valid Tmux display-popup flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        # Options taking an argument
        -w|-h|-x|-y|-d|-S|-s|-b|-T|-c|-e|-t)
            [[ $# -ge 2 ]] || { echo "Error: $1 requires an argument" >&2; exit 1; }
            POPUP_ARGS+=("$1" "$2")
            shift 2
            ;;
        # Boolean / flag options (including -EE)
        -E|-EE|-B|-C|-k|-N)
            POPUP_ARGS+=("$1")
            shift 1
            ;;
        --)
            shift
            CMD_ARGS+=("$@")
            break
            ;;
        *)
            CMD_ARGS+=("$@")
            break
            ;;
    esac
done

# Safe check for argument presence without string-matching false positives
has_arg() {
    local target="$1"
    for arg in "${POPUP_ARGS[@]}"; do
        if [[ "$arg" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

# Apply default styling and dimensions if omitted
has_arg "-w" || POPUP_ARGS+=(-w 90%)
has_arg "-h" || POPUP_ARGS+=(-h 88%)
has_arg "-b" || { has_arg "-B" || POPUP_ARGS+=(-b rounded); }
has_arg "-E" || has_arg "-EE" || POPUP_ARGS+=(-E)

if [[ ${#CMD_ARGS[@]} -eq 0 ]]; then
    CMD_ARGS=("$SHELL")
fi

# 2. Conditional Idle Bypass: Check AI agent streaming state
AI_STATE="$(tmux display-message -p '#{@ai_agent_state_raw}' 2>/dev/null || echo 'idle')"

if [[ "$AI_STATE" != "busy" && "$AI_STATE" != "working" ]]; then
    # Zero overhead: spawn popup directly without backdrop pane creation
    exec tmux display-popup "${POPUP_ARGS[@]}" "${CMD_ARGS[@]}"
fi

# 3. Active AI Streaming: Create isolated frozen snapshot backdrop
CURRENT_PANE="$(tmux display-message -p '#{pane_id}')"
RAW_PANE="${CURRENT_PANE#%}"
ORIG_SESS="$(tmux display-message -p '#{session_name}')"
WAS_ZOOMED="$(tmux display-message -p '#{window_zoomed_flag}')"
BACKDROP_FILE="/tmp/tmux-backdrop-${UID:-$(id -u)}-${RAW_PANE}.ansi"

# Atomic file creation with strict 0600 permissions (eliminates TOCTOU race)
(umask 077 && : > "$BACKDROP_FILE")
tmux capture-pane -ep -t "$CURRENT_PANE" > "$BACKDROP_FILE" 2>/dev/null || true

# Turn off automatic rename to prevent status bar flicker
tmux set-option -w -t "$CURRENT_PANE" automatic-rename off 2>/dev/null || true

BACKDROP_PANE=""

cleanup() {
    local exit_code=$?
    if [[ -n "$BACKDROP_PANE" ]]; then
        tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    fi
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
    rm -f "$BACKDROP_FILE"

    # Restore session focus and pre-existing zoom
    local current_sess
    current_sess="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
    if [[ "$current_sess" == "$ORIG_SESS" ]]; then
        tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
        if [[ "$WAS_ZOOMED" == "1" ]]; then
            tmux resize-pane -Z -t "$CURRENT_PANE" 2>/dev/null || true
        fi
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# Spawn frozen background pane
BACKDROP_PANE="$(tmux split-window -d -P -F '#{pane_id}' -t "$CURRENT_PANE" "cat '$BACKDROP_FILE'; tail -f /dev/null" 2>/dev/null || true)"

if [[ -n "$BACKDROP_PANE" ]]; then
    tmux resize-pane -Z -t "$BACKDROP_PANE" 2>/dev/null || true
fi

# Run popup over frozen snapshot
tmux display-popup "${POPUP_ARGS[@]}" "${CMD_ARGS[@]}"
```

---

## 4. Repository Architecture: The Two-Tier Umbrella Distribution Model

To satisfy both the requirement for standalone open-source modularity and the user's desire for a single unified distribution repository, the architecture uses a **Two-Tier Umbrella Distribution Model**:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│              TIER 2 UMBRELLA DISTRIBUTION: fcmiranda/terminal-ai-cockpit                │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│ • install.sh               -> 1-line zero-compile curl installer (< 30s execution)      │
│ • cockpit-manifest.json    -> Pinned upstream release versions of acpd, lazygitrs, mm  │
│ • binaries/release assets  -> Pre-assembled bundles: terminal-ai-cockpit-v*.*.*-<arch>  │
│ • tmux/                    -> complete cockpit.tmux plugin (isolated popups, pills)     │
│ • hooks/                   -> generic AI agent hooks (antigravity, opencode, claude)    │
│ • scripts/                 -> tmux-popup-isolate.sh, lazygit-tmux-injector.sh           │
│ • systemd/                 -> acpd.service user unit                                    │
│ • docs/                    -> problem-first README, architecture manifesto, demos       │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                                       ▲
                                       │ (Automated Tier 2 CI Assembly - Zero Compilation)
┌──────────────────────────────────────┴──────────────────────────────────────────────────┐
│                             TIER 1 UPSTREAM CORE ENGINES                                │
├──────────────────────────────┬───────────────────────────┬──────────────────────────────┤
│ 1. Daemon Engine:            │ 2. Git & Review TUI:      │ 3. Navigation & Finder:      │
│    fcmiranda/acpd            │    fcmiranda/lazygitrs    │    fcmiranda/matchmaker      │
│    (Axum 0.8, Tokio 1.52)    │    (branch: fecavmi)      │    (branch: fecavmi)         │
│    • Standalone CI & Releases│    • Standalone CI & cross│    • Standalone CI & Releases│
│    • musl + Darwin binaries  │      tree-sitter C builds │    • musl + Darwin binaries  │
└──────────────────────────────┴───────────────────────────┴──────────────────────────────┘
```

### 4.1 Why the Two-Tier Model Wins:
1. **Isolation of C Cross-Compilation Complexity:** The 13 C tree-sitter grammars in `lazygitrs` require specialized `cross` or `cargo-zigbuild` environments. Isolating this to Tier 1 ensures that packaging failures in one tool never break or block the release of `acpd` or the overall cockpit distribution.
2. **Zero-Compile Assembly in Tier 2:** The umbrella distribution repository builds **nothing from source**. Its release workflow simply pulls verified, pre-built binary assets from Tier 1, validates SHA256 hashes, bundles them with scripts and tmux plugins, and publishes in under 2 minutes.
3. **Open-Source Modular Independence:** Community members who only want `lazygitrs` (with `--commits` and AI review notes) or `acpd` (for custom Tmux or Waybar integrations) can consume them independently without downloading the full cockpit.
4. **1-Command Zero-Friction User Experience:** End-users running `curl -fsSL ... | bash` receive a single unified archive containing all pre-built binaries, configs, systemd units, and tmux plugins ready to run immediately.

---

## 5. Step-by-Step Implementation Checklist

### Phase 1: Decoupling, Sanitization & Bug Fixing
- [ ] **acpd (Debounce Bug & Architecture Cleanup):**
  - Completely eliminate the redundant 400ms idle task in [`acpd/src/adapters.rs:361-368`](file:///home/fecavmi/dev/github/acpd/src/adapters.rs#L361-L368).
  - Centralize debouncing in [`acpd/src/api.rs:290-309`](file:///home/fecavmi/dev/github/acpd/src/api.rs#L290-L309) and tune default idle delay from 650ms down to **300ms** in [`daemon.rs:42`](file:///home/fecavmi/dev/github/acpd/src/daemon.rs#L42).
- [ ] **acpd (Clippy & Rustfmt Remediation):**
  - Fix the 4 `clippy::collapsible_if` errors in `src/adapters.rs` (lines 373, 413, 520, 620).
  - Run `cargo fmt` to resolve formatting diffs in `src/adapters.rs` and `src/api.rs`.
- [ ] **lazygitrs (Clippy & Tree-Sitter C Build Setup):**
  - Run scoped `cargo clippy --fix --bin "lazygitrs" -p lazygitrs` to remediate the bulk of the 282 compiler warnings.
  - Manually resolve remaining clippy warnings to pass strict `-D warnings` in CI.
  - Configure `cross-rs/cross` or `cargo-zigbuild` build targets for the 13 C tree-sitter language grammars.
- [ ] **lazygitrs (.lines.json Repository Pollution Fix):**
  - Immediate Stack Layer: Add global gitignore setup (`core.excludesFile ~/.gitignore_global` containing `.lines.json`) to `install.sh`.
  - Engine Layer: Plan migration of review note persistence to `.git/info/lines.json` or `$XDG_STATE_HOME/lazygitrs/<repo-hash>/lines.json` to keep working trees completely clean.
- [ ] **lazygitrs (Installer & Path Decoupling):**
  - Patch `install.sh` to remove `cargo install` compilation hijack.
  - Update `lazygit-hook.mjs:176` to invoke `lazygit-tmux-injector.sh` via `$PATH` / `$TERMINAL_AI_INJECTOR` rather than hardcoded dotfiles paths.
- [ ] **matchmaker (Git, Rustfmt & Clippy Scoping):**
  - Push the 25 unpushed commits on branch `fecavmi` to remote origin.
  - Scope `rustfmt --check` in CI to changed files or PR diffs to avoid 2,216-line git blame disruption.
  - Resolve or gate the 12 dead code compiler warnings in `matchmaker-cli/src/fm.rs`.
  - Remediate procedural macro clippy warnings in `matchmaker-partial-macros`.
- [ ] **Agent Hooks (Path Sanitization):**
  - Remove `/run/user/1001/` and `/home/fecavmi` from `antigravity/.gemini/hooks/hook-lib.mjs:92-99`.
  - Remove `/run/user/1001/` and `/home/fecavmi` from `opencode/.config/opencode/plugins/hooker.ts:8-15`.
- [ ] **tmux (Backdrop Isolation & Theming):**
  - Deploy complete `tmux-popup-isolate.sh` with `resize-pane -Z`, conditional idle bypass, CLI flags, and 0600 UID-pane isolation.
  - Refactor `lazygitrs-popup.sh`, `window-picker.sh`, `sesh-picker.sh`, `scrollback-extract.sh`, and `dir-peek.sh` to use `tmux-popup-isolate.sh`.
  - Provide fallback theme variables for non-Omarchy environments.

### Phase 2: Two-Tier CI/CD & Multi-Arch Build Automation
- [ ] **Tier 1 Engine CI/CD:**
  - Add `.github/workflows/ci.yml` across `acpd`, `lazygitrs`, and `matchmaker` (`cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`, `cargo audit`).
  - Configure `.github/workflows/release.yml` in `lazygitrs` with `cross` to cross-compile 13 C tree-sitter grammars into static musl and Darwin binaries.
  - Configure `.github/workflows/release.yml` in `acpd` and `matchmaker` producing multi-arch binaries and `.sha256` checksums.
- [ ] **Tier 2 Umbrella CI/CD (`terminal-ai-cockpit`):**
  - Create `cockpit-manifest.json` tracking pinned upstream engine release tags.
  - Create `.github/workflows/release.yml` that downloads pre-compiled Tier 1 assets, verifies SHA256 hashes, bundles them with scripts/plugins, and generates `terminal-ai-cockpit-v*.*.*-<arch>.tar.gz`.
  - Implement Akita's `awk` changelog slicer from `CHANGELOG.md` for automated GitHub Release notes.

### Phase 3: Unified Repository Setup (`terminal-ai-cockpit`)
- [ ] Initialize `fcmiranda/terminal-ai-cockpit`.
- [ ] Structure directories: `bin/`, `tmux/`, `hooks/`, `scripts/`, `systemd/`, `docs/`.
- [ ] Assemble `cockpit.tmux` registering status bar format options (`#{cockpit_status}`, `#{cockpit_spinner}`) and popup keybindings (`Ctrl+g`, `Prefix+s`, `Prefix+i`).

### Phase 4: Universal Installer (`install.sh`)
- [ ] Write POSIX-compliant, zero-compilation `install.sh`:
  - Detects OS/Arch.
  - Downloads latest Tier 2 release tarball from `terminal-ai-cockpit`.
  - Verifies sha256 checksum.
  - Installs binaries to `~/.local/bin/`.
  - Configures global gitignore for `.lines.json`.
  - Activates `acpd.service` via `systemctl --user enable --now`.
  - Automatically configures `.tmux.conf` with `cockpit.tmux`.
- [ ] Test on clean Docker containers: Ubuntu 24.04, Alpine Linux, Arch Linux, macOS Sonoma.

### Phase 5: Documentation & Community Launch
- [ ] Problem-First `README.md`:
  - Highlight flicker-free streaming, 1-key inline diff reviews, and 0% idle CPU (no tech-stack vanity).
- [ ] Terminal Demos (`vhs`):
  - Record animated SVG/GIFs demonstrating the frozen backdrop popup during active AI token streaming.
- [ ] Packaging Distribution:
  - Create Arch AUR package (`terminal-ai-cockpit-bin`).
  - Create Homebrew formula (`brew tap fcmiranda/tap && brew install terminal-ai-cockpit`).
