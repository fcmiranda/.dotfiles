# Persist zsh history across sessions (used by arrows, autosuggestions, history-search)
# Note: Atuin has its own DB for CTRL-R; this feeds native zsh history for everything else

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=50000      # commands kept in memory per session
SAVEHIST=50000      # commands written to HISTFILE on exit

setopt EXTENDED_HISTORY       # store timestamp + duration with each entry
setopt INC_APPEND_HISTORY     # write to HISTFILE immediately, not only on exit
setopt SHARE_HISTORY          # all sessions read/write the same HISTFILE in real time
setopt HIST_IGNORE_DUPS       # don't record a command identical to the previous one
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries from history
setopt HIST_IGNORE_SPACE      # commands prefixed with space are not saved
setopt HIST_REDUCE_BLANKS     # strip extra whitespace before saving
setopt HIST_VERIFY            # show history expansion before executing (!!)
