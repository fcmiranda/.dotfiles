# Hyprland Crash Fix (Black Screen / Import Loop)

This document explains the reason behind sudden Hyprland crashes (which resulted in a black screen at login) and how to prevent/resolve the issue if it occurs again after an update or dotfiles reset.

---

## 1. The Problem
The Hyprland theme template file:
`~/.dotfiles/main/hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl`

Had the following line active at the top (line 1):
```ini
source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

### What happened in practice:
1. When applying or updating a theme, Omarchy's manager would read this `.tpl` file to generate the final compiled file:
   `~/.config/omarchy/current/theme/hyprland.omarchy.conf`
2. Since the template contained the instruction to import the compiled file itself, the generated file ended up **importing itself**.
3. When starting Hyprland, it read this `source` line, tried to import the file, which in turn tried to import itself, generating an **infinite recursion**.
4. This overflowed the stack memory (Stack Overflow), resulting in a **Segmentation Fault (Segfault / Core Dump)**.
5. Because Hyprland crashed instantly, the system was stuck on a black screen and the automatic login service (`omarchy-seamless-login.service`) failed because it hit the restart limit (`start-limit-hit`).

---

## 2. The Solution
The definitive solution is to ensure that the `source` line is commented out in both the **template** and the **generated file**:

### In the template file (Fixed):
`~/.dotfiles/main/hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl`
```ini
# source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

### In the generated final file (Fixed):
`~/.config/omarchy/current/theme/hyprland.omarchy.conf`
```ini
# source = ~/.config/omarchy/current/theme/hyprland.omarchy.conf
```

---

## 3. How to prevent the issue from returning
Since you manage your dotfiles via Git (worktree in `~/.dotfiles/main`), if you do not save this fix in your Git history, any command like `git checkout`, `git reset`, or `git pull` will discard the fix and bring the error back.

To save it permanently, run the following commands in the terminal:

```bash
# 1. Navigate to the repository folder
cd ~/.dotfiles/main

# 2. Add the template fix
git add hypr/.config/omarchy/themed-overrides/hyprland.conf.tpl

# 3. Commit the changes
git commit -m "fix: remove circular source from hyprland theme template to prevent crashes"

# 4. (Optional) Push to your remote repository
git push
```

If the environment crashes again before you can commit, you can restore the service by running:
```bash
bash ~/restart-hyprland.sh
```
