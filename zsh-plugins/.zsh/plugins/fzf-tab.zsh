# Source fzf-tab plugin (must load after compinit and zsh-vi-mode)
if [ -f "${HOME}/.zsh-plugins/fzf-tab/fzf-tab.plugin.zsh" ]; then
    source "${HOME}/.zsh-plugins/fzf-tab/fzf-tab.plugin.zsh"

    # Show file previews in completions (directories with eza, files with bat)
    # eza --all ensures hidden files/dirs are visible in the tree preview
    zstyle ':fzf-tab:complete:*' fzf-preview \
        '[[ -d $realpath ]] && eza --tree --level=2 --icons --color=always --all "$realpath" || bat --style=numbers --color=always --line-range=:200 "$realpath" 2>/dev/null'

    # Use the same fzf flags as the rest of the setup
    zstyle ':fzf-tab:*' fzf-flags --height=50% --layout=reverse --border

    # Switch between tab groups with < and >
    zstyle ':fzf-tab:*' switch-group '<' '>'

    # Include hidden files in completion candidates (e.g. .config, .env)
    zstyle ':completion:*' file-patterns '%p(D):globbing-flags' '*(/D):directories' '*(D):all-files'

    # Disable sort when completing git branches
    zstyle ':completion:*:git-checkout:*' sort false

    enable-fzf-tab
fi
