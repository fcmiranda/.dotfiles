eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide   show only zoxide results
#   CTRL-Z          toggle to zoxide-only results
#   CTRL-A          restore full combined list
#   CTRL-Y          copy selected path to clipboard
#   CTRL-S          toggle sort (folders-first ↔ alphabetical)
#   TAB             toggle focus: filter mode ↔ navigate mode
#   → / l           (navigate mode) browse into dir
#   ← / h           (navigate mode) go back
#   ↓ / j           (navigate mode) move down
#   ↑ / k           (navigate mode) move up
#   CTRL-P          toggle pane focus: results ⇄ preview
#   CTRL-D/U        scroll preview down / up (half page)
#   CTRL-/          show / hide preview window
zcd() {
    local zoxide_only=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z|--zoxide) zoxide_only=1; shift ;;
            *) break ;;
        esac
    done

    # capture launch directory for relative-path display
    local _cwd="$PWD"

    # temp files for state
    local _stack _sortfile _curdir _modefile _sourcefile _togglescript _relscript _leftaction _rightaction _leftscript _rightscript
    _stack=$(mktemp)
    _sortfile=$(mktemp)
    _curdir=$(mktemp)
    _modefile=$(mktemp)
    _sourcefile=$(mktemp)
    _togglescript=$(mktemp)
    _relscript=$(mktemp)
    _leftaction=$(mktemp)
    _rightaction=$(mktemp)
    _leftscript=$(mktemp)
    _rightscript=$(mktemp)
    _upscript=$(mktemp)
    _downscript=$(mktemp)
    _previewfocusfile=$(mktemp)
    _previewscript=$(mktemp)
    chmod +x "$_togglescript" "$_leftscript" "$_rightscript" "$_upscript" "$_downscript" "$_previewscript"
    # python script: stdin full-paths → stdout "fullpath\trelpath" (relative to _cwd)
    cat > "$_relscript" <<'RELEOF'
import sys, os, signal
signal.signal(signal.SIGPIPE, signal.SIG_DFL)
cwd = None  # set below
RELEOF
    # inject cwd after the heredoc opener so the shell expands it
    echo "cwd = '$_cwd'" >> "$_relscript"
    cat >> "$_relscript" <<'RELEOF'
for line in sys.stdin:
    p = line.rstrip('\n')
    if not p:
        continue
    try:
        rel = os.path.relpath(p, cwd)
    except Exception:
        rel = p
    try:
        print(p + '\t' + rel)
    except BrokenPipeError:
        break
RELEOF
    echo "dirsfirst" > "$_sortfile"
    echo "filter"    > "$_modefile"
    (( zoxide_only )) && echo "zo" > "$_sourcefile" || echo "all" > "$_sourcefile"
    echo "list"      > "$_previewfocusfile"

    # Build list of printable keys to block in navigate mode (fzf has no 'any' in older builds)
    local _input_keys=()
    local _k
    for _k in {a..z} {A..Z} {0..9}; do _input_keys+=($_k); done
    _input_keys+=(space del)
    local _input_keys_str="${(j:,:)_input_keys}"
    # Build --bind string: a:ignore,b:ignore,...
    local _input_binds="${(j:,:)${_input_keys[@]/%/:ignore}}"

    # rel-path variants: emit "fullpath\trelpath" for fzf display
    local _init_all_rel="( zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null ) | awk '!seen[\$0]++' | python3 '$_relscript'"
    local _init_zo_rel="zoxide query -l | python3 '$_relscript'"
    local _init_reload_rel
    (( zoxide_only )) && _init_reload_rel=$_init_zo_rel || _init_reload_rel=$_init_all_rel

    # Browse command: reads _curdir + _sortfile; pipes through relscript
    local _browse="d=\$(cat '$_curdir'); s=\$(cat '$_sortfile'); \
if [ -z \"\$d\" ]; then \
  $_init_reload_rel; \
elif [ \"\$s\" = 'sorted' ]; then \
  fd -H -E.git -a . \"\$d\" 2>/dev/null | sort | python3 '$_relscript'; \
else \
  { fd -td -H -E.git -a . \"\$d\"; fd -tf -H -E.git -a . \"\$d\"; } 2>/dev/null | python3 '$_relscript'; \
fi"

    # Header rows — ESC var expands into the heredoc (TOGGLEEOF unquoted)
    local ESC=$'\033'
    local _h2_filter="${ESC}[1;36m▌ FILTER${ESC}[0m  ${ESC}[2mTAB: nav  │  CTRL-/: preview  │  CTRL-P: pane focus  │  CTRL-D/U: scroll${ESC}[0m"
    local _h2_nav="${ESC}[1;33m▌ NAVIGATE${ESC}[0m  ${ESC}[1;33m→${ESC}[0m: browse  │  ${ESC}[1;33m←${ESC}[0m: back  │  TAB: filter  │  CTRL-P: focus  │  CTRL-D/U: scroll"
    local _prompt_filter="${ESC}[1;36m  ${ESC}[0m"
    local _prompt_nav="${ESC}[1;33m⇆ ${ESC}[0m"
    # Section labels — ANSI color indicates which pane is currently active
    local _input_label_on="${ESC}[1;36m input ${ESC}[0m"
    local _input_label_off=" input "
    local _list_label_on="${ESC}[1;33m results ${ESC}[0m"
    local _list_label_off="${ESC}[1;36m results ${ESC}[0m"
    local _preview_label_on="${ESC}[1;35m preview ${ESC}[0m"
    local _preview_label_off="${ESC}[1;36m preview ${ESC}[0m"
    local _h_all="${_h2_filter}"
    local _h_zo="${_h2_filter}"

    # Write the tab-toggle script AFTER headers are defined so variables expand correctly
    cat > "$_togglescript" <<TOGGLEEOF
#!/bin/sh
mode=\$(cat '$_modefile')
src=\$(cat '$_sourcefile')
[ "\$src" = 'zo' ] && h1='$_h1_zo' || h1='$_h1_all'
if [ "\$mode" = 'filter' ]; then
  echo navigate > '$_modefile'
  printf 'hide-input+disable-search+rebind($_input_keys_str)+change-pointer(▶)+change-prompt($_prompt_nav)+change-header(%s\n$_h2_nav)+change-input-label($_input_label_off)+change-list-label($_list_label_on)' "$h1"
else
  echo filter > '$_modefile'
  printf 'show-input+enable-search+unbind($_input_keys_str)+change-pointer( )+change-prompt($_prompt_filter)+change-header(%s\n$_h2_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)' "$h1"
fi
TOGGLEEOF

    # Tab: toggle filter ↔ navigate via external script (avoids multiline bind quoting issues)
    local _bind_tab="tab:transform($_togglescript)"
    # Preview focus toggle: tracks which pane is focused and updates border labels accordingly
    cat > "$_previewscript" <<PREVEOF
#!/bin/sh
state=\$(cat '$_previewfocusfile')
mode=\$(cat '$_modefile')
if [ "\$state" = "list" ]; then
  echo "preview" > '$_previewfocusfile'
  printf 'toggle-preview-focus+change-preview-label($_preview_label_on)+change-input-label($_input_label_off)+change-list-label($_list_label_off)'
else
  echo "list" > '$_previewfocusfile'
  if [ "\$mode" = "filter" ]; then
    printf 'toggle-preview-focus+change-preview-label($_preview_label_off)+change-input-label($_input_label_on)+change-list-label($_list_label_off)'
  else
    printf 'toggle-preview-focus+change-preview-label($_preview_label_off)+change-input-label($_input_label_off)+change-list-label($_list_label_on)'
  fi
fi
PREVEOF
    local _bind_preview_focus="ctrl-p:transform($_previewscript)"
    # Source switches: reset to filter mode and clear navigation state atomically
    local _bind_zo="ctrl-z:execute-silent(echo zo > '$_sourcefile'; echo filter > '$_modefile'; echo list > '$_previewfocusfile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+show-input+enable-search+unbind($_input_keys_str)+change-pointer( )+change-prompt($_prompt_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)+change-preview-label($_preview_label_off)+reload($_init_zo_rel)+change-header(${_h1_zo}\n${_h2_filter})"
    local _bind_all="ctrl-a:execute-silent(echo all > '$_sourcefile'; echo filter > '$_modefile'; echo list > '$_previewfocusfile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+show-input+enable-search+unbind($_input_keys_str)+change-pointer( )+change-prompt($_prompt_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)+change-preview-label($_preview_label_off)+reload($_init_all_rel)+change-header(${_h1_all}\n${_h2_filter})"

    # Clipboard: wl-copy (Wayland-native) replaces xclip (X11-only)
    local _bind_copy="ctrl-y:execute-silent(echo -n {1} | wl-copy)"

    # Navigation actions stored in files so transform scripts can cat them without quoting hell
    # {1} is an fzf placeholder — appears literally so fzf expands it when executing the action
    cat > "$_rightaction" <<RIGHTEOF
execute-silent(cur=\$(cat $_curdir); if [ -z "\$cur" ]; then echo __ROOT__ >> $_stack; else echo "\$cur" >> $_stack; fi; echo {1} > $_curdir)+reload($_browse)
RIGHTEOF
    cat > "$_leftaction" <<LEFTEOF
execute-silent(if [ -s $_stack ]; then prev=\$(tail -1 $_stack); count=\$(wc -l < $_stack); head -n "\$((count-1))" $_stack > $_stack.tmp && mv $_stack.tmp $_stack; if [ "\$prev" = "__ROOT__" ]; then printf '' > $_curdir; else echo "\$prev" > $_curdir; fi; else printf '' > $_curdir; fi)+reload($_browse)
LEFTEOF

    # Transform scripts: check mode → emit cursor action (filter) or navigate action (navigate)
    printf '#!/bin/sh\n[ "$(cat %s)" = "navigate" ] && cat %s || echo forward-char\n' \
        "$_modefile" "$_rightaction" > "$_rightscript"
    printf '#!/bin/sh\n[ "$(cat %s)" = "navigate" ] && cat %s || echo backward-char\n' \
        "$_modefile" "$_leftaction" > "$_leftscript"
    # up/down: same pattern — navigate mode moves cursor, filter mode ignores
    printf '#!/bin/sh\n[ "$(cat %s)" = "navigate" ] && echo up || echo ignore\n' \
        "$_modefile" > "$_upscript"
    printf '#!/bin/sh\n[ "$(cat %s)" = "navigate" ] && echo down || echo ignore\n' \
        "$_modefile" > "$_downscript"

    local _bind_right="right:transform($_rightscript)"
    local _bind_left="left:transform($_leftscript)"
    local _bind_up="up:transform($_upscript)"
    local _bind_down="down:transform($_downscript)"

    # Sort toggle
    local _bind_sort="ctrl-s:execute-silent(if [ \"\$(cat '$_sortfile')\" = 'dirsfirst' ]; then echo sorted > '$_sortfile'; else echo dirsfirst > '$_sortfile'; fi)+reload($_browse)"

    # Preview: tree for dirs, bat for files  ({1} = full path)
    local _preview='[[ -d {1} ]] && eza --tree --level=2 --icons --color=always {1} || bat --style=numbers --color=always --line-range=:300 {1}'

    local _common_binds=(
        --delimiter=$'\t'
        --with-nth=2
        --pointer=' '                                   # hidden in filter mode; changed to ▶ in navigate
        --color='bg:-1,bg+:-1,fg+:15,hl+:bold:2,input-border:8,list-border:8,preview-border:6'  # transparent bg; border + focus colors
        --list-border=rounded
        --input-border=rounded
        --list-label="$_list_label_off"
        --input-label="$_input_label_on"
        --preview-label="$_preview_label_off"
        --bind='ctrl-/:toggle-preview'
        --bind="$_bind_tab"
        --bind="$_bind_zo"
        --bind="$_bind_all"
        --bind="$_bind_copy"
        --bind="$_bind_right"
        --bind="$_bind_left"
        --bind="$_bind_up"
        --bind="$_bind_down"
        --bind="$_bind_sort"
        --bind="$_bind_preview_focus"                  # CTRL-P: toggle pane focus
        --bind='ctrl-down:preview-half-page-down'         # scroll preview down
        --bind='ctrl-up:preview-half-page-up'           # scroll preview up
        --bind="$_input_binds"                          # block printable keys in navigate mode
        --bind="h:transform($_leftscript)"               # h = back (navigate mode) / type normally (filter)
        --bind="l:transform($_rightscript)"              # l = browse (navigate mode) / type normally (filter)
        --bind="j:transform($_downscript)"               # j = down (navigate mode) / type normally (filter)
        --bind="k:transform($_upscript)"                 # k = up (navigate mode) / type normally (filter)
        --bind="start:execute-silent(echo navigate > '$_modefile')+transform($_togglescript)"  # enter filter mode via toggle script (same code path as TAB)
    )

    local dir
    if (( zoxide_only )); then
        dir=$(eval "$_init_zo_rel" | fzf \
            --ansi \
            --prompt="$_prompt_filter" \
            --header="$_h_zo" \
            --preview="$_preview" \
            --preview-window=right:60% \
            "${_common_binds[@]}")
    else
        dir=$(eval "$_init_all_rel" | fzf \
            --ansi \
            --prompt="$_prompt_filter" \
            --header="$_h_all" \
            --preview="$_preview" \
            --preview-window=right:60% \
            "${_common_binds[@]}")
    fi

    rm -f "$_stack" "$_sortfile" "$_curdir" "$_modefile" "$_sourcefile" "$_togglescript" "$_relscript" "$_leftaction" "$_rightaction" "$_leftscript" "$_rightscript" "$_upscript" "$_downscript" "$_previewfocusfile" "$_previewscript"

    # fzf returns "fullpath\trelpath"; extract just the full path
    [[ -n "$dir" ]] && echo "${dir%%$'\t'*}"
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
