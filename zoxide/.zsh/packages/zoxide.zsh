eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide   show only zoxide results
#   CTRL-Z          toggle to zoxide-only results
#   CTRL-A          restore full combined list
#   CTRL-Y          copy selected path to clipboard
#   CTRL-O          open selected dir in yazi
#   CTRL-RIGHT      browse into selected dir (dirs + files, folders first)
#   CTRL-LEFT       go back to previous list
#   CTRL-S          toggle sort (folders-first ↔ alphabetical)
zcd() {
    local zoxide_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z|--zoxide) zoxide_only=1; shift ;;
            *) break ;;
        esac
    done

    # temp files for navigation state
    local _stack _sortfile _curdir
    _stack=$(mktemp)
    _sortfile=$(mktemp)
    _curdir=$(mktemp)
    echo "dirsfirst" > "$_sortfile"
    # _curdir empty = at root (show initial list)

    local _init_all='zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null'
    local _init_zo='zoxide query -l'
    local _init_reload
    if (( zoxide_only )); then
        _init_reload=$_init_zo
    else
        _init_reload=$_init_all
    fi

    # Browse command: reads _curdir + _sortfile, dirs first or sorted
    local _browse="d=\$(cat '$_curdir'); s=\$(cat '$_sortfile'); \
if [ -z \"\$d\" ]; then \
  $_init_reload; \
elif [ \"\$s\" = 'sorted' ]; then \
  fd -H -E.git -a . \"\$d\" 2>/dev/null | sort; \
else \
  { fd -td -H -E.git -a . \"\$d\"; fd -tf -H -E.git -a . \"\$d\"; } 2>/dev/null; \
fi"

    local _h_all=$'Zoxide + fd  │  CTRL-Z: zo only  │  CTRL-Y: copy  │  CTRL-O: yazi\nCTRL-→: browse  │  CTRL-←: back  │  CTRL-S: sort  │  CTRL-/: preview'
    local _h_zo=$'Zoxide only  │  CTRL-A: all results  │  CTRL-Y: copy  │  CTRL-O: yazi\nCTRL-→: browse  │  CTRL-←: back  │  CTRL-S: sort  │  CTRL-/: preview'

    local _bind_zo="ctrl-z:execute-silent(: > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+reload($_init_zo)+change-header(Zoxide only  │  CTRL-A: all results  │  CTRL-Y: copy  │  CTRL-O: yazi)"
    local _bind_all="ctrl-a:execute-silent(: > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+reload($_init_all)+change-header(Zoxide + fd  │  CTRL-Z: zo only  │  CTRL-Y: copy  │  CTRL-O: yazi)"
    local _bind_copy='ctrl-y:execute-silent(echo -n {} | xclip -selection clipboard)'
    local _bind_yazi='ctrl-o:become(yazi {})'

    # ctrl-right: push curdir (or __ROOT__) to stack, set curdir={}, reload browse
    local _bind_right="ctrl-right:execute-silent(cur=\$(cat '$_curdir'); if [ -z \"\$cur\" ]; then echo __ROOT__ >> '$_stack'; else echo \"\$cur\" >> '$_stack'; fi; echo {} > '$_curdir')+reload($_browse)"

    # ctrl-left: pop stack → restore curdir, reload browse
    local _bind_left="ctrl-left:execute-silent(if [ -s '$_stack' ]; then prev=\$(tail -1 '$_stack'); sed -i '\$d' '$_stack'; if [ \"\$prev\" = '__ROOT__' ]; then printf '' > '$_curdir'; else echo \"\$prev\" > '$_curdir'; fi; else printf '' > '$_curdir'; fi)+reload($_browse)"

    # ctrl-s: toggle sort mode, reload browse
    local _bind_sort="ctrl-s:execute-silent(if [ \"\$(cat '$_sortfile')\" = 'dirsfirst' ]; then echo sorted > '$_sortfile'; else echo dirsfirst > '$_sortfile'; fi)+reload($_browse)"

    # preview: tree for dirs, bat for files
    local _preview='[[ -d {} ]] && eza --tree --level=2 --icons --color=always {} || bat --style=numbers --color=always --line-range=:300 {}'

    local dir
    if (( zoxide_only )); then
        dir=$(eval "$_init_zo" | fzf \
            --header="$_h_zo" \
            --preview="$_preview" \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all" \
            --bind="$_bind_copy" \
            --bind="$_bind_yazi" \
            --bind="$_bind_right" \
            --bind="$_bind_left" \
            --bind="$_bind_sort")
    else
        dir=$( { zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null; } | awk '!seen[$0]++' | fzf \
            --header="$_h_all" \
            --preview="$_preview" \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --bind="$_bind_zo" \
            --bind="$_bind_all" \
            --bind="$_bind_copy" \
            --bind="$_bind_yazi" \
            --bind="$_bind_right" \
            --bind="$_bind_left" \
            --bind="$_bind_sort")
    fi

    rm -f "$_stack" "$_sortfile" "$_curdir"

    # always print the selected path; the caller decides what to do
    [[ -n "$dir" ]] && echo "$dir"
}

# ALT-J: trigger zcd from the command line
_zcd_widget() {
    local result
    result=$(zcd)
    if [[ -n "$result" ]]; then
        if [[ -d "$result" ]]; then
            zoxide add "$result"
            cd "$result"
        else
            # file selected: insert path at cursor
            LBUFFER+="$result"
        fi
    fi
    zle reset-prompt
}
zle -N _zcd_widget
bindkey '\ej' _zcd_widget
