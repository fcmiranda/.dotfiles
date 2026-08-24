#!/usr/bin/env bash
set -e

TARGET_USER="${1:-$USER}"

echo "Configurando login automático no SDDM para: $TARGET_USER"
sudo mkdir -p /etc/sddm.conf.d
printf "[Autologin]\nUser=%s\nSession=hyprland\nRelogin=false\n" "$TARGET_USER" | sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null
echo "✓ Login automático no Hyprland configurado com sucesso!"
cat /etc/sddm.conf.d/autologin.conf
