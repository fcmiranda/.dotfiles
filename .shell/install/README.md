# Workstation Bootstrap

## Install zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/fcmiranda/.omc/refs/heads/main/omc/sh/zsh.sh)"
```

## Install US International locale

```sh
cd && ./omc/sh/us-intl-locale.sh
```

## Install packages (kanshi, atuin)

```sh
chmod +x ~/omc/pkgs/install.zsh
cd && ~/omc/pkgs/install.zsh
```

## Install zsh plugins
```sh
chmod +x ~/omc/pkgs/zsh-plugins.zsh
cd && ~/omc/pkgs/zsh-plugins.zsh
```


# Todo
Create a markdown file 

Setup Section

How to install .zsh and set as default shell using `sh -c "$(curl -fsSL https://raw.githubusercontent.com/fcmiranda/.omc/refs/heads/main/omc/sh/zsh.sh)"` or [running the zsh script locally](sh/zsh.sh) 
How clone omc repo and how checkout using `sh -c "$(curl -fsSL https://raw.githubusercontent.com/fcmiranda/.omc/refs/heads/main/omc/sh/omc.sh)"` or [running the omc.zsh locally](sh/omc.sh) 
Why it was create us international locale [script](sh/us-intl-locale.sh), how works and how run it


Setup Section
Installing packages, plugins and setup them

How [install script](pkgs/install.zsh) works
How zsh.sh works importing the modules and evaluating the files


Setup Section
Config files

Why and how the configs bellow were created:
x11 dialogs
    /home/fecavmi/.config/hypr/x11-dialogs.conf
workspaces
    /home/fecavmi/.config/hypr/workspaces.conf
animations
    /home/fecavmi/.config/hypr/animations.conf






