alias waybar-restart='killall waybar && hyprctl dispatch exec waybar'
alias walker-restart='pkill -f walker && walker &'
alias reload="source ~/.zshrc"
alias omc='/usr/bin/git --git-dir=/home/fecavmi/.omc --work-tree=/home/fecavmi'
alias code.omc='GIT_DIR=/home/fecavmi/.omc GIT_WORK_TREE=/home/fecavmi code /home/fecavmi'
alias install-packages='~/omc/install/install.zsh'
alias clear="clear && [ -n \"\$TMUX\" ] && tmux clear-history"
alias scrollback='tmux capture-pane -epS - > /tmp/tmux_scrollback.ansi && nvim -c "BaleiaColorize" -c "normal G" /tmp/tmux_scrollback.ansi'
