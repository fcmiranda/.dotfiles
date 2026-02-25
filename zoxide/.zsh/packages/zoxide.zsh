eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide   show only zoxide results
#   CTRL-Z          toggle to zoxide-only results
#   CTRL-A          restore full combined list
#   CTRL-Y          copy selected path to clipboard
#   CTRL-O          open selected dir in yazi
#   CTRL-RIGHT      drill down into selected dir (push to stack)
#   CTRL-LEFT       go back to previous list (pop from stack)
zcd() {
    local zoxide_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z|--zoxide) zoxide_only=1; shift ;;
            *) break ;;
        esac
    done

    # stack file: each line is a dir we drilled into, popped on alt-h
    local _stack
    _stack=$(mktemp)

    local _init_all='zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null'
    local _init_zo='zoxide query -l'

    local _h_all=$'Zoxide + fd  │  CTRL-Z: zoxide only  │  CTRL-Y: copy  │  CTRL-O: yazi\nCTRL-→: drill down  │  CTRL-←: go back  │  CTRL-/: preview'
    local _h_zo=$'Zoxide only  │  CTRL-A: all results  │  CTRL-Y: copy  │  CTRL-O: yazi\nCTRL-→: drill down  │  CTRL-←: go back  │  CTRL-/: preview'

    local _bind_zo="ctrl-z:execute-silent(: > '$_stack')+reload($_init_zo)+change-header(Zoxide only  │  CTRL-A: all results  │  CTRL-Y: copy  │  CTRL-O: yazi)"
    local _bind_all="ctrl-a:execute-silent(: > '$_stack')+reload($_init_all)+change-header(Zoxide + fd  │  CTRL-Z: zoxide only  │  CTRL-Y: copy  │  CTRL-O: yazi)"
    local _bind_copy='ctrl-y:execute-silent(echo -n {} | xclip -selection clipboard)'
    local _bind_yazi='ctrl-o:become(yazi {})'
    # Push __ROOT__ sentinel when at root (stack empty), or dirname {} when already in a subdir.
    # This way alt-back always pops to the correct previous listing, never the same view.
    local _bind_right="ctrl-right:execute-silent(if [ -s '$_stack' ]; then d=\$(dirname {}); echo \"\$d\" >> '$_stack'; else echo __ROOT__ >> '$_stack'; fi)+reload(fd -td -H -E.git -a . {} 2>/dev/null)"

    local _init_reload
    if (( zoxide_only )); then
        _init_reload=$_init_zo
    else
        _init_reload=$_init_all
    fi
    local _bind_left="ctrl-left:reload(if [ -s '$_stack' ]; then prev=\$(tail -1 '$_stack'); sed -i '\$d' '$_stack'; if [ \"\$prev\" = '__ROOT__' ]; then $_init_reload; else fd -td -H -E.git -a . \"\$prev\" 2>/dev/null; fi; else $_init_reload; fi)"

    local dir
    if (( zoxide_only )); then
        dir=$(eval "$_init_zo" | fzf \
            --header="$_h_zo" \
            --preview='eza --tree --level=2 --icons --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all" \
            --bind="$_bind_copy" \
            --bind="$_bind_yazi" \
            --bind="$_bind_right" \
            --bind="$_bind_left")
    else
        dir=$( { zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null; } | awk '!seen[$0]++' | fzf \
            --header="$_h_all" \
            --preview='eza --tree --level=2 --icons --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all" \
            --bind="$_bind_copy" \
            --bind="$_bind_yazi" \
            --bind="$_bind_right" \
            --bind="$_bind_left")
    fi

    rm -f "$_stack"

    if [[ -n "$dir" ]]; then
        zoxide add "$dir"
        cd "$dir"
    fi
}

# ALT-J: trigger zcd from the command line
_zcd_widget() { zcd; zle reset-prompt }
zle -N _zcd_widget
bindkey '\ej' _zcd_widget
