function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local chosen
    chosen=$(sesh list --icons | grep -Ev '(_lazygitrs|_popups|[[:space:]]+\.)' | ~/.cargo/bin/mm -o "$HOME/.config/tmux/sesh-picker.toml")
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
