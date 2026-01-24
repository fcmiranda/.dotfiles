# ~/.zshenv - Always loaded (even for non-interactive shells)
# Put environment variables here that should be available everywhere

# FZF environment variables (so subshells like yazi's shell inherit them)
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
    --height=60%
    --layout=reverse
    --border=rounded
    --info=inline
    --margin=1
    --padding=1
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --header-first
    --cycle
    --scroll-off=5
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-d:preview-page-down'
    --bind='ctrl-u:preview-page-up'
    --bind='ctrl-a:select-all'
    --bind='ctrl-y:execute-silent(echo {+} | xclip -selection clipboard)'
"
