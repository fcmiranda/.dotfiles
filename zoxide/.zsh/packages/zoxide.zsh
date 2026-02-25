eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide  show only zoxide results
#   CTRL-Z (in picker) toggle to zoxide-only results
#   CTRL-A (in picker) restore full combined list
zcd() {
    local zoxide_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z|--zoxide) zoxide_only=1; shift ;;
            *) break ;;
        esac
    done

    local dir
    local _bind_zo='ctrl-z:reload(zoxide query -l)+change-header(Zoxide only  │  CTRL-A: all results)'
    local _bind_all='ctrl-a:reload(zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null)+change-header(Zoxide + fd  │  CTRL-Z: zoxide only)'

    if (( zoxide_only )); then
        dir=$(zoxide query -l | fzf \
            --header='Zoxide only  │  CTRL-A: all results' \
            --preview='eza --tree --level=2 --icons --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all")
    else
        dir=$( { zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null; } | awk '!seen[$0]++' | fzf \
            --header='Zoxide + fd  │  CTRL-Z: zoxide only' \
            --preview='eza --tree --level=2 --icons --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all")
    fi

    if [[ -n "$dir" ]]; then
        zoxide add "$dir"
        cd "$dir"
    fi
}

# ALT-J: trigger zcd from the command line
_zcd_widget() { zcd; zle reset-prompt }
zle -N _zcd_widget
bindkey '\ej' _zcd_widget
