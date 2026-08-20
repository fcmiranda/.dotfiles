function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local mm_bin="$HOME/.local/bin/mm"
    [ -x "$mm_bin" ] || mm_bin="$HOME/.cargo/bin/mm"
    [ -x "$mm_bin" ] || mm_bin="$(command -v mm 2>/dev/null || echo "mm")"
    local chosen
    chosen=$(sesh list --icons | grep -Ev '(_lazygitrs|_popups|[[:space:]]+\.)' | "$mm_bin" -o "$HOME/.config/tmux/sesh-picker.toml")
    zle reset-prompt > /dev/null 2>&1 || true
    chosen=$(echo "$chosen" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | sed -E 's/^[^a-zA-Z0-9/~._-]+//' | tr -d '\r' | xargs)
    [[ -z "$chosen" ]] && return
    sesh connect "$chosen"
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions
