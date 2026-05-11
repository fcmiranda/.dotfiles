#!/bin/bash

# Overwrite parts of the omarchy-menu with user-specific submenus.
# See $OMARCHY_PATH/bin/omarchy-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Omarchy changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) omarchy-lock-screen ;;
#   *Shutdown*) omarchy-cmd-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }

# Override broken upstream System menu entries rendering.
show_system_menu() {
  local options=$'󱄄  Screensaver\n  Lock'
  ! omarchy-toggle-enabled suspend-off && options+=$'\n󰒲  Suspend'
  omarchy-hibernation-available && options+=$'\n󰤁  Hibernate'
  options+=$'\n󰍃  Logout\n  Relaunch\n󰜉  Restart\n󰐥  Shutdown'

  case "$(menu "System" "$options")" in
  *Screensaver*) omarchy-launch-screensaver force ;;
  *Lock*) omarchy-system-lock ;;
  *Suspend*) systemctl suspend ;;
  *Hibernate*) systemctl hibernate ;;
  *Logout*) hyprctl dispatch exit ;;
  *Relaunch*) uwsm stop ;;
  *Restart*) systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  *) back_to show_main_menu ;;
  esac
}
