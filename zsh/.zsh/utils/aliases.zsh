alias waybar-restart='killall waybar && hyprctl dispatch exec waybar'
alias reload="source ~/.zshrc"
alias omc='/usr/bin/git --git-dir=/home/fecavmi/.omc --work-tree=/home/fecavmi'
alias code.omc='GIT_DIR=/home/fecavmi/.omc GIT_WORK_TREE=/home/fecavmi code /home/fecavmi'
alias code.here='GIT_DIR=$(pwd) GIT_WORK_TREE=$(pwd) code $(pwd)'