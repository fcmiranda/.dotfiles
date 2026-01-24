# Source zsh-vi-mode configuration
function zvm_config() {
    # Keep last mode behavior - the plugin default
    ZVM_LINE_INIT_MODE=$ZVM_MODE_LAST
    # Export ZVM_MODE so starship custom modules can read it
    typeset -gx ZVM_MODE
}

# Refresh prompt on vi mode change for starship integration
function zvm_after_select_vi_mode() {
    typeset -gx ZVM_MODE
    zle reset-prompt 2>/dev/null
}

if [ -f "${HOME}/.zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]; then
    source "${HOME}/.zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi

# Load omarchy-based colors for zsh-vi-mode prompt indicator
if [ -f "${HOME}/.zsh-plugins/zsh-vi-mode-theme.zsh" ]; then
    source "${HOME}/.zsh-plugins/zsh-vi-mode-theme.zsh"
elif [ -f "${HOME}/.zsh-plugins/.zsh/plugins/zsh-vi-mode-theme.zsh" ]; then
    source "${HOME}/.zsh-plugins/.zsh/plugins/zsh-vi-mode-theme.zsh"
elif [ -f "${HOME}/.dotfiles/zsh-plugins/.zsh/plugins/zsh-vi-mode-theme.zsh" ]; then
    source "${HOME}/.dotfiles/zsh-plugins/.zsh/plugins/zsh-vi-mode-theme.zsh"
fi

# Custom zle-line-init to always start in insert mode with proper prompt reset
function _zvm_custom_zle_line_init() {
    # Always reset to insert mode first without prompt reset (like original)
    ZVM_MODE=''
    zvm_select_vi_mode $ZVM_MODE_INSERT
}

# Hook to override zle-line-init after zvm_init completes
function zvm_after_init_override_line_init() {
    zle -N zle-line-init _zvm_custom_zle_line_init
}
zvm_after_init_commands+=('zvm_after_init_override_line_init')

# =============================================================================
# Combined surround text objects: ib (inside brackets) and iq (inside quotes)
# =============================================================================

# Find the innermost surround from a list of candidates
# Returns: bpos epos bchar echar (or empty if not found)
function _zvm_find_innermost_surround() {
    local candidates=("$@")
    local best_bpos=-1
    local best_epos=-1
    local best_bchar=""
    local best_echar=""
    local best_size=999999

    for surround in "${candidates[@]}"; do
        local ret=($(zvm_search_surround "$surround"))
        if [[ ${#ret[@]} -ge 2 ]]; then
            local bpos=${ret[1]}
            local epos=${ret[2]}
            local size=$((epos - bpos))
            # Select the innermost (smallest) surround
            if [[ $size -lt $best_size ]]; then
                best_size=$size
                best_bpos=$bpos
                best_epos=$epos
                local match=($(zvm_match_surround "$surround"))
                best_bchar=${match[1]}
                best_echar=${match[2]}
            fi
        fi
    done

    if [[ $best_bpos -ge 0 ]]; then
        echo $best_bpos $best_epos $best_bchar $best_echar
    fi
}

# Visual select inside brackets (combines vi{, vi(, vi[, vi<)
function zvm_select_inside_bracket() {
    local ret=($(_zvm_find_innermost_surround '(' '[' '{' '<'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_exit_visual_mode
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Inside: skip the brackets themselves
    ((bpos++))
    MARK=$bpos; CURSOR=$((epos - 1))
    zle redisplay
}

# Visual select around brackets (combines va{, va(, va[, va<)
function zvm_select_around_bracket() {
    local ret=($(_zvm_find_innermost_surround '(' '[' '{' '<'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_exit_visual_mode
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Around: include the brackets
    ((epos++))
    MARK=$bpos; CURSOR=$((epos - 1))
    zle redisplay
}

# Visual select inside quotes (combines vi", vi', vi`)
function zvm_select_inside_quote() {
    local ret=($(_zvm_find_innermost_surround '"' "'" '`'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_exit_visual_mode
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Inside: skip the quotes themselves
    ((bpos++))
    MARK=$bpos; CURSOR=$((epos - 1))
    zle redisplay
}

# Visual select around quotes (combines va", va', va`)
function zvm_select_around_quote() {
    local ret=($(_zvm_find_innermost_surround '"' "'" '`'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_exit_visual_mode
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Around: include the quotes
    ((epos++))
    MARK=$bpos; CURSOR=$((epos - 1))
    zle redisplay
}

# Change/delete/yank inside brackets (combines ci{, ci(, ci[, ci<)
function zvm_change_inside_bracket() {
    local action=${1:-c}
    local ret=($(_zvm_find_innermost_surround '(' '[' '{' '<'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_select_vi_mode $ZVM_MODE_NORMAL
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Inside: skip the brackets themselves
    ((bpos++))
    CUTBUFFER=${BUFFER:$bpos:$((epos - bpos))}
    zvm_clipboard_copy_buffer 2>/dev/null
    case $action in
        c)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            zvm_select_vi_mode $ZVM_MODE_INSERT
            ;;
        d)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            ;;
        y)
            CURSOR=$bpos
            ;;
    esac
}

# Change/delete/yank around brackets (combines ca{, ca(, ca[, ca<)
function zvm_change_around_bracket() {
    local action=${1:-c}
    local ret=($(_zvm_find_innermost_surround '(' '[' '{' '<'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_select_vi_mode $ZVM_MODE_NORMAL
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Around: include the brackets
    ((epos++))
    CUTBUFFER=${BUFFER:$bpos:$((epos - bpos))}
    zvm_clipboard_copy_buffer 2>/dev/null
    case $action in
        c)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            zvm_select_vi_mode $ZVM_MODE_INSERT
            ;;
        d)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            ;;
        y)
            CURSOR=$bpos
            ;;
    esac
}

# Change/delete/yank inside quotes (combines ci", ci', ci`)
function zvm_change_inside_quote() {
    local action=${1:-c}
    local ret=($(_zvm_find_innermost_surround '"' "'" '`'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_select_vi_mode $ZVM_MODE_NORMAL
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Inside: skip the quotes themselves
    ((bpos++))
    CUTBUFFER=${BUFFER:$bpos:$((epos - bpos))}
    zvm_clipboard_copy_buffer 2>/dev/null
    case $action in
        c)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            zvm_select_vi_mode $ZVM_MODE_INSERT
            ;;
        d)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            ;;
        y)
            CURSOR=$bpos
            ;;
    esac
}

# Change/delete/yank around quotes (combines ca", ca', ca`)
function zvm_change_around_quote() {
    local action=${1:-c}
    local ret=($(_zvm_find_innermost_surround '"' "'" '`'))
    if [[ ${#ret[@]} -eq 0 ]]; then
        zvm_select_vi_mode $ZVM_MODE_NORMAL
        return
    fi
    local bpos=${ret[1]}
    local epos=${ret[2]}
    # Around: include the quotes
    ((epos++))
    CUTBUFFER=${BUFFER:$bpos:$((epos - bpos))}
    zvm_clipboard_copy_buffer 2>/dev/null
    case $action in
        c)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            zvm_select_vi_mode $ZVM_MODE_INSERT
            ;;
        d)
            BUFFER="${BUFFER:0:$bpos}${BUFFER:$epos}"
            CURSOR=$bpos
            ;;
        y)
            CURSOR=$bpos
            ;;
    esac
}

# Wrapper functions for specific actions
function zvm_delete_inside_bracket() { zvm_change_inside_bracket d; }
function zvm_delete_around_bracket() { zvm_change_around_bracket d; }
function zvm_delete_inside_quote() { zvm_change_inside_quote d; }
function zvm_delete_around_quote() { zvm_change_around_quote d; }
function zvm_yank_inside_bracket() { zvm_change_inside_bracket y; }
function zvm_yank_around_bracket() { zvm_change_around_bracket y; }
function zvm_yank_inside_quote() { zvm_change_inside_quote y; }
function zvm_yank_around_quote() { zvm_change_around_quote y; }
function zvm_change_inside_bracket_c() { zvm_change_inside_bracket c; }
function zvm_change_around_bracket_c() { zvm_change_around_bracket c; }
function zvm_change_inside_quote_c() { zvm_change_inside_quote c; }
function zvm_change_around_quote_c() { zvm_change_around_quote c; }

# Track consecutive up presses for atuin activation
_zvm_up_press_count=0

# Custom up handler: double-up triggers atuin
function _zvm_up_or_atuin() {
    ((_zvm_up_press_count++))
    if [[ $_zvm_up_press_count -ge 3 ]]; then
        _zvm_up_press_count=0
        BUFFER=""
        CURSOR=0
        zle atuin-search
    else
        # Schedule reset after a brief delay
        (sleep 0.5; _zvm_up_press_count=0) &!
        zle up-line-or-history
    fi
}

# Custom down handler: reset counter and go down
function _zvm_down_reset_counter() {
    _zvm_up_press_count=0
    zle down-line-or-history
}

# Custom keybindings after zsh-vi-mode initialization
function zvm_after_init() {
    # Unbind ctrl-p/ctrl-n and bind ctrl-j/ctrl-k for history navigation
    bindkey -M viins -r '^P'
    bindkey -M viins -r '^N'

    # Define custom up handler widget
    zvm_define_widget _zvm_up_or_atuin
    zvm_define_widget _zvm_down_reset_counter

    bindkey -M viins '^[[A' _zvm_up_or_atuin
    bindkey -M viins '^K' up-line-or-history
    bindkey -M viins '^J' _zvm_down_reset_counter
    bindkey -M viins '^[[B' _zvm_down_reset_counter

    # Bind ctrl-r to backward-kill-word in insert mode
    bindkey -M viins '^R' backward-kill-word

    # ==========================================================================
    # Register combined surround widgets and keybindings
    # ==========================================================================

    # Define widgets for combined surrounds
    zvm_define_widget zvm_select_inside_bracket
    zvm_define_widget zvm_select_around_bracket
    zvm_define_widget zvm_select_inside_quote
    zvm_define_widget zvm_select_around_quote
    zvm_define_widget zvm_delete_inside_bracket
    zvm_define_widget zvm_delete_around_bracket
    zvm_define_widget zvm_delete_inside_quote
    zvm_define_widget zvm_delete_around_quote
    zvm_define_widget zvm_yank_inside_bracket
    zvm_define_widget zvm_yank_around_bracket
    zvm_define_widget zvm_yank_inside_quote
    zvm_define_widget zvm_yank_around_quote
    zvm_define_widget zvm_change_inside_bracket_c
    zvm_define_widget zvm_change_around_bracket_c
    zvm_define_widget zvm_change_inside_quote_c
    zvm_define_widget zvm_change_around_quote_c

    # Visual mode: vib, vab, viq, vaq
    zvm_bindkey visual 'ib' zvm_select_inside_bracket
    zvm_bindkey visual 'ab' zvm_select_around_bracket
    zvm_bindkey visual 'iq' zvm_select_inside_quote
    zvm_bindkey visual 'aq' zvm_select_around_quote

    # Normal mode: dib, dab, diq, daq (delete)
    zvm_bindkey vicmd 'dib' zvm_delete_inside_bracket
    zvm_bindkey vicmd 'dab' zvm_delete_around_bracket
    zvm_bindkey vicmd 'diq' zvm_delete_inside_quote
    zvm_bindkey vicmd 'daq' zvm_delete_around_quote

    # Normal mode: yib, yab, yiq, yaq (yank)
    zvm_bindkey vicmd 'yib' zvm_yank_inside_bracket
    zvm_bindkey vicmd 'yab' zvm_yank_around_bracket
    zvm_bindkey vicmd 'yiq' zvm_yank_inside_quote
    zvm_bindkey vicmd 'yaq' zvm_yank_around_quote

    # Normal mode: cib, cab, ciq, caq (change)
    zvm_bindkey vicmd 'cib' zvm_change_inside_bracket_c
    zvm_bindkey vicmd 'cab' zvm_change_around_bracket_c
    zvm_bindkey vicmd 'ciq' zvm_change_inside_quote_c
    zvm_bindkey vicmd 'caq' zvm_change_around_quote_c
}
