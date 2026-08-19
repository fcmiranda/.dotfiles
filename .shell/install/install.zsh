#!/usr/bin/env zsh

# Script to install packages

set -e

# Load helper functions
source "${0:A:h}/helpers.zsh"

echo "Starting installation..."

install_packages \
    kanshi \
    battery \
    atuin \
    ghostty \
    keyd \
    yazi \
    chafa \
    stow \
    visual-studio-code-bin \
    p7zip \
    tmux \
    yq \
    figlet \
    lolcat \
    procs \
    duf \
    gh \
    gh-dash \
    zen-browser-bin \
    opencode-bin \
    gum \
    sesh-bin \
    crush-bin \
    hugo \
    cava \
    mpv-wallpaper \
    bibata-cursor-theme-bin \
    upscayl-bin \
    aether \
    just \
    cargo \
    worktrunk \
    apm-unix \
    wf-recorder \
    herdr \
    ripdrag \
    ffmpegthumbnailer \
    poppler \
    mediainfo \
    ai-memory \
    ai-jail \
    ai-usagebar

install_plugins \
    zsh-plugins \
    tmux-plugins

echo "Installation complete."
