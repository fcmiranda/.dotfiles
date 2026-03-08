
- window for nvim
- toggle test panel
- window for opencode
- server
----------
.tmux.conf

- https://github.com/joshmedeski/dotfiles/blob/main/.config/tmux/tmux.conf
------  
create a githubpage using hugo to explain whe workflow
- add a section for tips
- add section features, scrollback, vi-cmd-mode (custom feature surround)
- kanshi for handle monitor

----------
ghostty config
font-codepoint-map = U+E900-U+E901=omc
----------

linkarzu workflow
I'm also highly interested in testing Ghostty out without tmux in the way, I use tmux basically the entire day, as soon as I open Ghostty, tmux takes over with this command
I use the tmux-resurrect plugin so all my sessions are restored when I close and re-open Ghostty
I use tmux to easily switch between my different github repos, I use ThePrimeagen's tmux-sessionizer
So with keymaps I jump to my different projects hyper+t+j -> dotfiles, hyper+t+u obsidian repo, hyper+t+l -> blogpost, hyper+t+r -> daily note, etc, etc
Also with hyper+t+n I get an fzf menu of my different directories, so I can create a session out of any of those that I don't have keymaps for. And I just switch to them using the tmux sessions window (image below)
Also if I tap left_shift on my keyboard, I jump back to the previous or alternate tmux session
I honestly don't care about remote servers via SSH, my main goal is the session management features, if on a remote server I'll use tmux in th