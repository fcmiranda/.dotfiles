#!/bin/zsh

# Setup keyd configuration to remap capslock to esc on tap and ctrl on hold
set -e

echo "Setting up keyd configuration..."

# Ensure keyd is installed before configuring service
if command -v pkg_is_installed &>/dev/null && command -v pkg_install &>/dev/null; then
	if ! pkg_is_installed keyd; then
		echo "Installing keyd package..."
		pkg_install keyd
	fi
elif ! command -v keyd &>/dev/null; then
	echo "keyd is not installed. Please install it and rerun this script."
	exit 1
fi

# Create keyd config directory if it doesn't exist
sudo mkdir -p /etc/keyd

# Write the keyd configuration
sudo tee /etc/keyd/default.conf > /dev/null <<EOF
[ids]

*

[main]

capslock = overload(control, esc)
EOF

echo "Keyd configuration written to /etc/keyd/default.conf"

# Enable and start keyd service
sudo systemctl enable keyd
sudo systemctl start keyd

echo "Keyd service enabled and started."
echo "Capslock is now remapped: tap for esc, hold for ctrl."