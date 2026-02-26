eval "$(zoxide init zsh --cmd j)"

# zcd - cd using combined zoxide frecency + fd directory search (Alt-J)
#   -z / --zoxide   show only zoxide results
#   CTRL-Z          toggle to zoxide-only results
#   CTRL-A          restore full combined list (zoxide + fd)
#   CTRL-G          smart search (zoxide dirs → their contents → rest of $HOME)
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
#   F1              show / hide all shortcuts
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
    _helpstatefile=$(mktemp)
    _helptextfile=$(mktemp)
    _helpscript=$(mktemp)
    chmod +x "$_togglescript" "$_leftscript" "$_rightscript" "$_upscript" "$_downscript" "$_previewscript" "$_helpscript"
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
    if (( zoxide_only )); then
        echo "zo" > "$_sourcefile"
    elif [[ "$_cwd" == "$HOME" ]]; then
        echo "smart" > "$_sourcefile"
    else
        echo "all" > "$_sourcefile"
    fi
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
    # Folders excluded from every fd scan — add names here to keep results clean
    local _ignore_dirs=(
        node_modules .cache target dist build __pycache__
        .venv venv env vendor .gradle .npm .pnpm-store
        .next out coverage .tox .mypy_cache .pytest_cache
        .cargo .rustup .local .mozilla .thunderbird
    )
    local _fd_ex="${(j: :)${_ignore_dirs[@]/#/-E }}"
    local _init_all_rel="( zoxide query -l; fd -td -H -E.git ${_fd_ex} --absolute-path 2>/dev/null ) | awk '!seen[\$0]++' | python3 '$_relscript'"
    local _init_zo_rel="zoxide query -l | python3 '$_relscript'"
    local _init_cwd_rel="{ fd -td -H -E.git ${_fd_ex} -a . '$_cwd'; fd -tf -H -E.git ${_fd_ex} -a . '$_cwd'; } 2>/dev/null | python3 '$_relscript'"
    # smart: wave 1 = all zoxide dirs (frecency order, appear at top)
    #        wave 2 = contents of each zoxide dir clustered in frecency order
    #        wave 3 = rest of $HOME (entries already seen are skipped by awk)
    local _init_smart_rel="{ zoxide query -l 2>/dev/null; zoxide query -l 2>/dev/null | while IFS= read -r _zd; do fd -H -E.git ${_fd_ex} -a --max-depth 3 . \"\$_zd\" 2>/dev/null; done; fd -H -E.git ${_fd_ex} -a . '$HOME' 2>/dev/null; } | awk '!seen[\$0]++' | python3 '$_relscript'"
    # Determine initial source based on launch context
    local _init_source_rel
    if (( zoxide_only )); then
        _init_source_rel=$_init_zo_rel
    elif [[ "$_cwd" == "$HOME" ]]; then
        _init_source_rel=$_init_smart_rel
    else
        _init_source_rel=$_init_cwd_rel
    fi

    # Browse command: reads _curdir + _sortfile + _sourcefile; pipes through relscript
    local _browse="d=\$(cat '$_curdir'); s=\$(cat '$_sortfile'); src=\$(cat '$_sourcefile'); \\
if [ -z \"\$d\" ]; then \\
  if [ \"\$src\" = 'smart' ]; then \\
    $_init_smart_rel; \\
  elif [ \"\$src\" = 'zo' ]; then \\
    $_init_zo_rel; \\
  else \\
    $_init_all_rel; \\
  fi; \\
elif [ \"\$s\" = 'sorted' ]; then \
  fd -H -E.git ${_fd_ex} -a . \"\$d\" 2>/dev/null | sort | python3 '$_relscript'; \
else \
  { fd -td -H -E.git ${_fd_ex} -a . \"\$d\"; fd -tf -H -E.git ${_fd_ex} -a . \"\$d\"; } 2>/dev/null | python3 '$_relscript'; \
fi"

    # ── Theme ─────────────────────────────────────────────────────────────────
    local ESC=$'\033'
    # Terminal color numbers used by fzf --color (change here to retheme everything)
    local input_color=6      # cyan   — input box border + filter-mode accents
    local result_color=3     # yellow — results list border + navigate-mode accents
    local preview_color=5    # magenta — preview border + help label
    local pointer_color=5    # magenta — pointer glyph (matches preview border)
    # Icons (single char recommended so fzf width stays correct)
    local filter_icon=''    # prompt icon in filter mode
    local nav_icon='⇆'       # prompt icon in navigate mode
    local ptr_filter_icon='' # list pointer in filter mode
    local ptr_nav_icon=''   # list pointer in navigate mode
    # ──────────────────────────────────────────────────────────────────────────

    # Derived ANSI sequences (built from the variables above — don't edit below)
    local _prompt_filter="${ESC}[1;3${input_color}m${filter_icon} ${ESC}[0m"
    local _prompt_nav="${ESC}[1;3${result_color}m${nav_icon} ${ESC}[0m"
    local _ptr_filter="$ptr_filter_icon"
    local _ptr_nav="$ptr_nav_icon"
    # Section labels — active label uses the pane's accent color; inactive is plain/dim
    local _input_label_on="${ESC}[1;3${input_color}m input ${ESC}[0m"
    local _input_label_off=" input "
    local _list_label_on="${ESC}[1;3${result_color}m results ${ESC}[0m"
    local _list_label_off="${ESC}[1;3${input_color}m results ${ESC}[0m"
    local _list_label_nav_tmpl="${ESC}[1;3${result_color}m{fzf:match-count} results for [{q}]${ESC}[0m"
    local _preview_label_on="${ESC}[1;3${preview_color}m preview ${ESC}[0m"
    local _preview_label_off="${ESC}[1;3${input_color}m preview ${ESC}[0m"
    local _h1_all="All  │  CTRL-Z: zoxide  │  CTRL-G: smart  │  CTRL-Y: copy"
    local _h1_zo="Zoxide  │  CTRL-A: all  │  CTRL-G: smart  │  CTRL-Y: copy"
    local _h1_smart="Smart  │  CTRL-A: all  │  CTRL-Z: zoxide  │  CTRL-Y: copy"
    local _h_all="$_h1_all"
    local _h_zo="$_h1_zo"
    local _h_smart="$_h1_smart"

    # Write the tab-toggle script AFTER headers are defined so variables expand correctly
    cat > "$_togglescript" <<TOGGLEEOF
#!/bin/sh
mode=\$(cat '$_modefile')
src=\$(cat '$_sourcefile')
if [ "\$src" = 'zo' ]; then h1='$_h1_zo'; elif [ "\$src" = 'smart' ]; then h1='$_h1_smart'; else h1='$_h1_all'; fi
if [ "\$mode" = 'filter' ]; then
  echo navigate > '$_modefile'
  if [ -z "\$FZF_QUERY" ]; then
    lbl=\$(printf '\033[1;33m%s results\033[0m' "\$FZF_MATCH_COUNT")
  else
    lbl=\$(printf '\033[1;33m%s results for [%s]\033[0m' "\$FZF_MATCH_COUNT" "\$FZF_QUERY")
  fi
  printf 'hide-input+disable-search+rebind($_input_keys_str)+change-pointer($_ptr_nav)+change-prompt($_prompt_nav)+change-header(%s)+change-input-label($_input_label_off)+change-list-label(%s)' "$h1" "\$lbl"
else
  echo filter > '$_modefile'
  printf 'show-input+enable-search+unbind($_input_keys_str)+change-pointer($_ptr_filter)+change-prompt($_prompt_filter)+change-header(%s)+change-input-label($_input_label_on)+change-list-label($_list_label_off)' "$h1"
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
  printf 'toggle-preview-focus+change-preview-label($_preview_label_on)+change-input-label($_input_label_off)'
else
  echo "list" > '$_previewfocusfile'
  if [ "\$mode" = "filter" ]; then
    printf 'toggle-preview-focus+change-preview-label($_preview_label_off)+change-input-label($_input_label_on)+change-list-label($_list_label_off)'
  else
    if [ -z "\$FZF_QUERY" ]; then
      lbl=\$(printf '\033[1;33m%s results\033[0m' "\$FZF_MATCH_COUNT")
    else
      lbl=\$(printf '\033[1;33m%s results for [%s]\033[0m' "\$FZF_MATCH_COUNT" "\$FZF_QUERY")
    fi
    printf 'toggle-preview-focus+change-preview-label($_preview_label_off)+change-input-label($_input_label_off)+change-list-label(%s)' "\$lbl"
  fi
fi
PREVEOF
    local _bind_preview_focus="ctrl-p:transform($_previewscript)"
    # Source switches: reset to filter mode and clear navigation state atomically
    local _bind_zo="ctrl-z:execute-silent(echo zo > '$_sourcefile'; echo filter > '$_modefile'; echo list > '$_previewfocusfile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+show-input+enable-search+unbind($_input_keys_str)+change-pointer($_ptr_filter)+change-prompt($_prompt_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)+change-preview-label($_preview_label_off)+reload($_init_zo_rel)+change-header(${_h1_zo})"
    local _bind_all="ctrl-a:execute-silent(echo all > '$_sourcefile'; echo filter > '$_modefile'; echo list > '$_previewfocusfile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+show-input+enable-search+unbind($_input_keys_str)+change-pointer($_ptr_filter)+change-prompt($_prompt_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)+change-preview-label($_preview_label_off)+reload($_init_all_rel)+change-header(${_h1_all})"
    local _bind_smart="ctrl-g:execute-silent(echo smart > '$_sourcefile'; echo filter > '$_modefile'; echo list > '$_previewfocusfile'; : > '$_stack'; printf '' > '$_curdir'; echo dirsfirst > '$_sortfile')+show-input+enable-search+unbind($_input_keys_str)+change-pointer($_ptr_filter)+change-prompt($_prompt_filter)+change-input-label($_input_label_on)+change-list-label($_list_label_off)+change-preview-label($_preview_label_off)+reload($_init_smart_rel)+change-header(${_h1_smart})"

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
    local _result_label_script=$(mktemp)
    chmod +x "$_result_label_script"
    cat > "$_result_label_script" <<RLSCEOF
#!/bin/sh
if [ "\$(cat '$_modefile')" = 'navigate' ]; then
  if [ -z "\$FZF_QUERY" ]; then
    printf 'change-list-label(\033[1;33m%s results\033[0m)' "\$FZF_MATCH_COUNT"
  else
    printf 'change-list-label(\033[1;33m%s results for [%s]\033[0m)' "\$FZF_MATCH_COUNT" "\$FZF_QUERY"
  fi
else
  echo ignore
fi
RLSCEOF
    local _bind_result_label="result:transform($_result_label_script)"
    local _bind_sort="ctrl-s:execute-silent(if [ \"\$(cat '$_sortfile')\" = 'dirsfirst' ]; then echo sorted > '$_sortfile'; else echo dirsfirst > '$_sortfile'; fi)+reload($_browse)"

    # Preview: tree for dirs, bat for files  ({1} = full path)
    local _preview='[[ -d {1} ]] && eza --tree --level=2 --icons --color=always {1} || bat --style=numbers --color=always --line-range=:300 {1}'

    # Help overlay — written once; CTRL-? toggles it into the preview pane
    local _preview_label_help="${ESC}[1;35m shortcuts ${ESC}[0m"
    cat > "$_helptextfile" <<HELPEOF
${ESC}[1;35m  ALL SHORTCUTS${ESC}[0m

${ESC}[1m  Mode${ESC}[0m
  TAB          toggle filter ↔ navigate

${ESC}[1m  Sources${ESC}[0m
  CTRL-Z       zoxide only
  CTRL-A       all dirs + zoxide
  CTRL-G       smart search (frecency)

${ESC}[1m  Navigation${ESC}[0m  ${ESC}[2m(navigate mode only)${ESC}[0m
  → / l        browse into dir
  ← / h        go back
  ↓ / j        move down
  ↑ / k        move up

${ESC}[1m  Preview${ESC}[0m
  CTRL-/       show / hide preview
  CTRL-P       toggle pane focus
  CTRL-↓/↑     scroll preview

${ESC}[1m  Other${ESC}[0m
  CTRL-S       toggle sort
  CTRL-Y       copy path
  F1           toggle this help
  ENTER        cd to selection
  ESC          cancel
HELPEOF
    cat > "$_helpscript" <<HELPSCRIPTEOF
#!/bin/sh
if [ "\$(cat '$_helpstatefile')" = "on" ]; then
  echo off > '$_helpstatefile'
  printf 'change-preview($_preview)+change-preview-label($_preview_label_off)'
else
  echo on > '$_helpstatefile'
  printf 'change-preview(cat $_helptextfile)+change-preview-label($_preview_label_help)'
fi
HELPSCRIPTEOF
    local _bind_help="f1:transform($_helpscript)"

    local _common_binds=(
        --delimiter=$'\t'
        --with-nth=2
        --pointer="$_ptr_filter"                        # filter mode pointer; changed to $_ptr_nav in navigate
        --scheme=path                                   # path-aware fzf scoring
        --tiebreak=index                                # preserve emission order on equal fzf scores
        --color='bg:-1,bg+:-1,fg+:15,hl+:bold:2,input-border:6,list-border:3,preview-border:5,pointer:5'  # transparent bg; input=cyan, list=yellow, preview=magenta
        --no-border
        --list-border=rounded
        --input-border=rounded
        --list-label="$_list_label_off"
        --input-label="$_input_label_on"
        --preview-label="$_preview_label_off"
        --bind='ctrl-/:toggle-preview'
        --bind="$_bind_tab"
        --bind="$_bind_zo"
        --bind="$_bind_all"
        --bind="$_bind_smart"
        --bind="$_bind_copy"
        --bind="$_bind_right"
        --bind="$_bind_left"
        --bind="$_bind_sort"
        --bind="$_bind_result_label"                    # live label update in navigate mode
        --bind="$_bind_preview_focus"                  # CTRL-P: toggle pane focus
        --bind="$_bind_help"                            # CTRL-?: show/hide shortcuts
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
    local _h_init
    if (( zoxide_only )); then
        _h_init="$_h_zo"
    elif [[ "$_cwd" == "$HOME" ]]; then
        _h_init="$_h_smart"
    else
        _h_init="$_h_all"
    fi
    dir=$(eval "$_init_source_rel" | fzf \
        --ansi \
        --prompt="$_prompt_filter" \
        --header="$_h_init" \
        --preview="$_preview" \
        --preview-window=right:60% \
        "${_common_binds[@]}")

    rm -f "$_stack" "$_sortfile" "$_curdir" "$_modefile" "$_sourcefile" "$_togglescript" "$_relscript" "$_leftaction" "$_rightaction" "$_leftscript" "$_rightscript" "$_upscript" "$_downscript" "$_previewfocusfile" "$_previewscript" "$_result_label_script" "$_helpstatefile" "$_helptextfile" "$_helpscript"

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
