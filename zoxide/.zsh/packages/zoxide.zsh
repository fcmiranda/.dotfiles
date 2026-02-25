eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide   show only zoxide results
#   CTRL-Z          toggle to zoxide-only results
#   CTRL-A          restore full combined list
#   CTRL-Y          copy selected path to clipboard
#   CTRL-O          open selected dir in yazi
#   CTRL-S          toggle sort (folders-first ↔ alphabetical)
#   TAB             toggle focus: filter mode ↔ navigate mode
#   → / ←           (navigate mode) browse into dir / go back
zcd() {
    local zoxide_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z|--zoxide) zoxide_only=1; shift ;;
            *) break ;;
        esac
    done

    # temp files for state
    local _stack _sortfile _curdir _modefile _sourcefile _togglescript
    _stack=$(mktemp)
    _sortfile=$(mktemp)
    _curdir=$(mktemp)
    _modefile=$(mktemp)
    _sourcefile=$(mktemp)
    _togglescript=$(mktemp)
    chmod +x "$_togglescript"
    echo "dirsfirst" > "$_sortfile"
    echo "filter"    > "$_modefile"
    (( zoxide_only )) && echo "zo" > "$_sourcefile" || echo "all" > "$_sourcefile"

    # Build list of printable keys to block in navigate mode (fzf has no 'any' in older builds)
    local _input_keys=()
    local _k
    for _k in {a..z} {A..Z} {0..9}; do _input_keys+=($_k); done
    _input_keys+=(space del)
    local _input_keys_str="${(j:,:)_input_keys}"
    # Build --bind string: a:ignore,b:ignore,...
    local _input_binds="${(j:,:)${_input_keys[@]/%/:ignore}}"

    local _init_all='zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null'
    local _init_zo='zoxide query -l'
    local _init_reload
    (( zoxide_only )) && _init_reload=$_init_zo || _init_reload=$_init_all

    # Browse command: reads _curdir + _sortfile
    local _browse="d=\$(cat '$_curdir'); s=\$(cat '$_sortfile'); \
if [ -z \"\$d\" ]; then \
  $_init_reload; \
elif [ \"\$s\" = 'sorted' ]; then \
  fd -H -E.git -a . \"\$d\" 2>/dev/null | sort; \
else \
  { fd -td -H -E.git -a . \"\$d\"; fd -tf -H -E.git -a . \"\$d\"; } 2>/dev/null; \
fi"

    # Header rows — ESC var expands into the heredoc (TOGGLEEOF unquoted)
    local ESC=$'\033'
    local _h1_all="Zoxide + fd  │  CTRL-Z: zo only  │  CTRL-Y: copy  │  CTRL-O: yazi"
    local _h1_zo="Zoxide only  │  CTRL-A: all  │  CTRL-Y: copy  │  CTRL-O: yazi"
    local _h2_filter="${ESC}[1;36m▌ FILTER${ESC}[0m  ${ESC}[2mTAB: navigate  │  CTRL-S: sort  │  CTRL-/: preview${ESC}[0m"
    local _h2_nav="${ESC}[1;33m▌ NAVIGATE${ESC}[0m  ${ESC}[1;33m→${ESC}[0m: browse  │  ${ESC}[1;33m←${ESC}[0m: back  │  TAB: filter  │  CTRL-S: sort"
    local _prompt_filter="${ESC}[1;36m❯ ${ESC}[0m"
    local _prompt_nav="${ESC}[1;33m⇆ ${ESC}[0m"

    local _h_all="${_h1_all}\n${_h2_filter}"
    local _h_zo="${_h1_zo}\n${_h2_filter}"

    # Write the tab-toggle script AFTER headers are defined so variables expand correctly
    cat > "$_togglescript" <<TOGGLEEOF
#!/bin/sh
mode=\$(cat '$_modefile')
src=\$(cat '$_sourcefile')
[ "\$src" = 'zo' ] && h1='$_h1_zo' || h1='$_h1_all'
if [ "\$mode" = 'filter' ]; then
  echo navigate > '$_modefile'
  printf 'disable-search+rebind(left,right)+rebind($_input_keys_str)+change-prompt($_prompt_nav)+change-header(%s\\n$_h2_nav)' "\$h1"
else
  echo filter > '$_modefile'
  printf 'enable-search+unbind(left,right)+unbind($_input_keys_str)+change-prompt($_prompt_filter)+change-header(%s\\n$_h2_filter)' "\$h1"
fi
TOGGLEEOF

    # Tab: toggle filter ↔ navigate via external script (avoids multiline bind quoting issues)
    local _bind_tab="tab:transform($_togglescript)"

    # Source switches: also reset to filter mode and clear navigation state
    local _bind_zo="ctrl-z:execute-silent(echo zo > '$_sourcefile'; echo filter > '$_modefile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+enable-search+unbind(left,right)+unbind($_input_keys_str)+change-prompt($_prompt_filter)+reload($_init_zo)+change-header(${_h1_zo}\n${_h2_filter})"
    local _bind_all="ctrl-a:execute-silent(echo all > '$_sourcefile'; echo filter > '$_modefile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+enable-search+unbind(left,right)+unbind($_input_keys_str)+change-prompt($_prompt_filter)+reload($_init_all)+change-header(${_h1_all}\n${_h2_filter})"

    local _bind_copy='ctrl-y:execute-silent(echo -n {} | xclip -selection clipboard)'
    local _bind_yazi='ctrl-o:become(yazi {})'

    # Navigation (only active in navigate mode via rebind/unbind)
    local _bind_right="right:execute-silent(cur=\$(cat '$_curdir'); if [ -z \"\$cur\" ]; then echo __ROOT__ >> '$_stack'; else echo \"\$cur\" >> '$_stack'; fi; echo {} > '$_curdir')+reload($_browse)"
    local _bind_left="left:execute-silent(if [ -s '$_stack' ]; then prev=\$(tail -1 '$_stack'); sed -i '\$d' '$_stack'; if [ \"\$prev\" = '__ROOT__' ]; then printf '' > '$_curdir'; else echo \"\$prev\" > '$_curdir'; fi; else printf '' > '$_curdir'; fi)+reload($_browse)"

    # Sort toggle
    local _bind_sort="ctrl-s:execute-silent(if [ \"\$(cat '$_sortfile')\" = 'dirsfirst' ]; then echo sorted > '$_sortfile'; else echo dirsfirst > '$_sortfile'; fi)+reload($_browse)"

    # Preview: tree for dirs, bat for files
    local _preview='[[ -d {} ]] && eza --tree --level=2 --icons --color=always {} || bat --style=numbers --color=always --line-range=:300 {}'

    local _common_binds=(
        --bind='ctrl-/:toggle-preview'
        --bind="$_bind_tab"
        --bind="$_bind_zo"
        --bind="$_bind_all"
        --bind="$_bind_copy"
        --bind="$_bind_yazi"
        --bind="$_bind_right"
        --bind="$_bind_left"
        --bind="$_bind_sort"
        --bind="$_input_binds"                          # define printable keys as ignore
        --bind="start:unbind(left,right)+unbind($_input_keys_str)" # start in filter mode (restore defaults)
    )

    local dir
    if (( zoxide_only )); then
        dir=$(eval "$_init_zo" | fzf \
            --ansi \
            --prompt="$_prompt_filter" \
            --header="$_h_zo" \
            --preview="$_preview" \
            --preview-window=right:60% \
            "${_common_binds[@]}")
    else
        dir=$( { zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null; } | awk '!seen[$0]++' | fzf \
            --ansi \
            --prompt="$_prompt_filter" \
            --header="$_h_all" \
            --preview="$_preview" \
            --preview-window=right:60% \
            "${_common_binds[@]}")
    fi

    rm -f "$_stack" "$_sortfile" "$_curdir" "$_modefile" "$_sourcefile" "$_togglescript"

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
