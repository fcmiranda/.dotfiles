alias video-wallpapers='nohup python ~/.local/share/hyprland-video-wallpapers/app.py > /dev/null 2>&1 &'
alias waybar-restart='killall waybar && hyprctl dispatch exec waybar'
alias walker-restart='pkill -f walker && walker &'
alias reload="source ~/.zshrc"
alias omc='/usr/bin/git --git-dir=/home/fecavmi/.omc --work-tree=/home/fecavmi'
alias code.omc='GIT_DIR=/home/fecavmi/.omc GIT_WORK_TREE=/home/fecavmi code /home/fecavmi'
alias code.='GIT_DIR=$PWD/.git GIT_WORK_TREE=$PWD code .'
alias install-packages='~/omc/install/install.zsh'
alias clear="clear && [ -n \"\$TMUX\" ] && tmux clear-history"
alias scrollback='tmux capture-pane -epS - > /tmp/tmux_scrollback.ansi && nvim -c "BaleiaColorize" -c "normal G" /tmp/tmux_scrollback.ansi'
alias adopt='bash $HOME/.dotfiles/scripts/stow-adopt-path.sh'