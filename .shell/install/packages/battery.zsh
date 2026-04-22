#!/usr/bin/env zsh
# Install battery management tools for Asahi Linux on Apple Silicon (M1/M2/M3).
#
# Sets up:
#   - auto-cpufreq: dynamically scales CPU frequency based on workload/AC state
#   - battery-charge-threshold systemd service: persists charge limits across reboots
#   - /etc/battery-charge-threshold.conf: configurable start/end thresholds (default 20/80)
#   - /etc/auto-cpufreq.conf: tuned profile for Apple Silicon under Linux
#
# Only applies on aarch64 (Apple Silicon). On x86_64 it installs tlp instead.

set -euo pipefail

BATTERY_PATH="/sys/class/power_supply/macsmc-battery"
CHARGE_THRESHOLD_CONF="/etc/battery-charge-threshold.conf"
CHARGE_THRESHOLD_SERVICE="/etc/systemd/system/battery-charge-threshold.service"
AUTO_CPUFREQ_CONF="/etc/auto-cpufreq.conf"

ARCH="$(uname -m)"

# ── Helper ─────────────────────────────────────────────────────────────────────
_write_system_file() {
  # Usage: _write_system_file <dest_path> <content>
  local dest="$1"
  local content="$2"
  print -P "  %F{blue}→%f Writing %B${dest}%b..."
  echo "$content" | sudo tee "$dest" > /dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# 1. auto-cpufreq
# ══════════════════════════════════════════════════════════════════════════════
if pkg_is_installed auto-cpufreq; then
  print -P "  %F{cyan}✓%f %Bauto-cpufreq%b already installed"
else
  print -P "  %F{blue}→%f Installing %Bauto-cpufreq%b..."
  pkg_install auto-cpufreq || return 1
fi

# ── auto-cpufreq config ───────────────────────────────────────────────────────
# Tuned for Apple Silicon: balanced on battery, performance on AC but not turbo-always.
if [[ ! -f "$AUTO_CPUFREQ_CONF" ]]; then
  _write_system_file "$AUTO_CPUFREQ_CONF" \
'# auto-cpufreq configuration — tuned for Apple Silicon on Asahi Linux
# Docs: https://github.com/AdnanHodzic/auto-cpufreq

[charger]
# On AC: use schedutil governor (kernel-driven, efficient)
# Allow higher freq range but not always-max to reduce heat on mains
governor = schedutil
# scaling_min_freq = 600000
# scaling_max_freq = 3200000
turbo = auto

[battery]
# On battery: powersave governor + conservative turbo
governor = powersave
# scaling_min_freq = 600000
# scaling_max_freq = 2000000
turbo = never
'
  print -P "  %F{green}✓%f auto-cpufreq config written to %B${AUTO_CPUFREQ_CONF}%b"
else
  print -P "  %F{cyan}✓%f auto-cpufreq config already exists at %B${AUTO_CPUFREQ_CONF}%b"
fi

# ── Enable auto-cpufreq daemon ────────────────────────────────────────────────
if ! systemctl is-enabled auto-cpufreq &>/dev/null; then
  print -P "  %F{blue}→%f Enabling auto-cpufreq service..."
  sudo systemctl enable --now auto-cpufreq
  print -P "  %F{green}✓%f auto-cpufreq enabled and started"
else
  print -P "  %F{cyan}✓%f auto-cpufreq already enabled"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 2. Charge threshold systemd service (Apple Silicon only)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$ARCH" == "aarch64" ]] && [[ -d "$BATTERY_PATH" ]]; then

  # Write the threshold config (default: start=20, end=80)
  if [[ ! -f "$CHARGE_THRESHOLD_CONF" ]]; then
    _write_system_file "$CHARGE_THRESHOLD_CONF" \
'# Battery charge threshold configuration for Apple Silicon (Asahi Linux)
# Charging starts when battery drops below CHARGE_START%
# Charging stops when battery reaches CHARGE_END%
#
# Profile: plugged-in desk use (recommended when AC most of the time)
#   CHARGE_START=60 / CHARGE_END=85  — battery stays in the 60-85% sweet spot
#
# Profile: mixed use (frequent battery operation)
#   CHARGE_START=20 / CHARGE_END=80  — wider range for longer unplugged sessions
#
# Change with: battery-threshold set-custom <start> <end>
CHARGE_START=60
CHARGE_END=85
'
    print -P "  %F{green}✓%f Charge threshold config written (20%% → 80%%)"
  else
    print -P "  %F{cyan}✓%f Charge threshold config already exists at %B${CHARGE_THRESHOLD_CONF}%b"
  fi

  # Write the systemd service
  if [[ ! -f "$CHARGE_THRESHOLD_SERVICE" ]]; then
    _write_system_file "$CHARGE_THRESHOLD_SERVICE" \
'[Unit]
Description=Set battery charge thresholds (Apple Silicon / Asahi Linux)
After=local-fs.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/battery-charge-threshold.conf
ExecStart=/bin/bash -c "echo ${CHARGE_START} > /sys/class/power_supply/macsmc-battery/charge_control_start_threshold && echo ${CHARGE_END} > /sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
ExecStop=/bin/bash -c "echo 95 > /sys/class/power_supply/macsmc-battery/charge_control_start_threshold && echo 100 > /sys/class/power_supply/macsmc-battery/charge_control_end_threshold"

[Install]
WantedBy=multi-user.target
'
    print -P "  %F{green}✓%f Charge threshold systemd service written"
  else
    print -P "  %F{cyan}✓%f Charge threshold service already exists"
  fi

  # Enable and start the service
  sudo systemctl daemon-reload
  if ! systemctl is-enabled battery-charge-threshold &>/dev/null; then
    print -P "  %F{blue}→%f Enabling battery-charge-threshold service..."
    sudo systemctl enable --now battery-charge-threshold
    print -P "  %F{green}✓%f battery-charge-threshold enabled and started"
  else
    print -P "  %F{cyan}✓%f battery-charge-threshold already enabled"
    sudo systemctl restart battery-charge-threshold
  fi

elif [[ "$ARCH" != "aarch64" ]]; then
  print -P "  %F{yellow}⚠%f Charge threshold service is Apple Silicon only (aarch64). Skipping."
else
  print -P "  %F{yellow}⚠%f Battery sysfs path %B${BATTERY_PATH}%b not found. Skipping threshold service."
  print -P "    This is expected if you are not on Asahi Linux."
fi

# ══════════════════════════════════════════════════════════════════════════════
# 3. Sudoers drop-in — passwordless sysfs threshold writes
# ══════════════════════════════════════════════════════════════════════════════
# Required by battery-calibrate-auto running as a systemd user service (no TTY).
SUDOERS_SRC="${0:A:h}/../../battery/etc/sudoers.d/10-battery-threshold"
SUDOERS_DEST="/etc/sudoers.d/10-battery-threshold"

if [[ ! -f "$SUDOERS_DEST" ]]; then
  print -P "  %F{blue}→%f Installing sudoers drop-in for battery threshold writes..."
  # visudo -c validates syntax before writing; fail loudly if the file is broken
  if sudo visudo -c -f "$SUDOERS_SRC" &>/dev/null; then
    sudo install -m 0440 -o root -g root "$SUDOERS_SRC" "$SUDOERS_DEST"
    print -P "  %F{green}✓%f Sudoers drop-in installed at %B${SUDOERS_DEST}%b"
  else
    print -P "  %F{red}✗%f Sudoers syntax check failed — skipping install"
  fi
else
  print -P "  %F{cyan}✓%f Sudoers drop-in already present"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 4. Monthly calibration systemd user timer
# ══════════════════════════════════════════════════════════════════════════════
# The timer calls battery-calibrate-auto on the 1st of each month.
# Persistent=true means it fires at next boot if the machine was off on the due date.
if ! systemctl --user is-enabled battery-calibrate.timer &>/dev/null; then
  print -P "  %F{blue}→%f Enabling battery-calibrate user timer..."
  systemctl --user daemon-reload
  systemctl --user enable --now battery-calibrate.timer
  print -P "  %F{green}✓%f battery-calibrate.timer enabled"
else
  print -P "  %F{cyan}✓%f battery-calibrate.timer already enabled"
fi

print -P "  %F{green}  ✓%f Battery management setup complete"
