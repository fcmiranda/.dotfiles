# IntelliShell integration
# https://github.com/lasantosr/intelli-shell
#
# Biomechanical Ergonomics & Keybinding Safety:
# 1. INTELLI_SKIP_ESC_BIND=1: DO NOT bind \e to kill-whole-line, preserving zsh-vi-mode Escape.
# 2. INTELLI_SEARCH_HOTKEY="^T": Uses Ctrl+T (inward roll on CapsLock+T, H=0) instead of Ctrl+Space
#    (which is the Tmux Prefix).
# 3. Dedicated safe chords for bookmarks (^Xb), variables (^Xv), and AI fix (^Xx) to prevent
#    overriding standard terminal controls (Ctrl+B, Ctrl+L, Ctrl+X).

export INTELLI_SKIP_ESC_BIND=1
export INTELLI_SEARCH_HOTKEY="^T"
export INTELLI_BOOKMARK_HOTKEY="^Xb"
export INTELLI_VARIABLE_HOTKEY="^Xv"
export INTELLI_FIX_HOTKEY="^Xx"

if (( $+commands[intelli-shell] )); then
  # Ensure completion system is loaded so compdef is available
  (( $+functions[compdef] )) || { autoload -Uz compinit && compinit -C; }

  eval "$(intelli-shell init zsh)"

  # Ensure bindings are registered in zsh-vi-mode if active
  _intelli_zvm_setup() {
    if (( $+widgets[_intelli_search] )); then
      zvm_bindkey viins '^T' _intelli_search
      zvm_bindkey vicmd '^T' _intelli_search
    fi
  }
  zvm_after_init_commands+=('_intelli_zvm_setup')

  # Helper alias to sync version-controlled custom.commands
  alias intelli-sync="intelli-shell import - < ~/.config/intelli-shell/custom.commands"
fi
