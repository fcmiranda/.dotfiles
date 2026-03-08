#!/usr/bin/env zsh

# ==============================================================================
# Script to configure US International keyboard layout and locale settings
# ==============================================================================

# -- Configuration Variables --
LOCALE="en_US.UTF-8"
KEYBOARD_LAYOUT="us"
KEYBOARD_VARIANT="intl"
BACKUP_DIR="$HOME/.locale_backup_$(date +%Y%m%d_%H%M%S)"

# -- Colors for output --
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    printf '%b\n' "${BLUE}[INFO]${NC} $1"
}

print_success() {
    printf '%b\n' "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    printf '%b\n' "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    printf '%b\n' "${RED}[ERROR]${NC} $1"
}

# -- Pre-flight checks --
print_status "Checking system requirements..."

# Check if running as root (not recommended for this script)
if [ "$EUID" -eq 0 ]; then
    print_error "Please run this script as a regular user, not as root."
    exit 1
fi

# Check if locale-gen is available
if ! command -v locale-gen >/dev/null 2>&1; then
    print_error "locale-gen command not found. Please install locales package:"
    echo "  sudo apt update && sudo apt install locales"
    exit 1
fi

# -- Backup current configuration --
print_status "Creating backup of current configuration..."
mkdir -p "$BACKUP_DIR"

# Backup locale settings
if [ -f /etc/locale.gen ]; then
    sudo cp /etc/locale.gen "$BACKUP_DIR/locale.gen.bak"
fi

if [ -f /etc/default/locale ]; then
    sudo cp /etc/default/locale "$BACKUP_DIR/default_locale.bak"
fi

if [ -f /etc/locale.conf ]; then
    sudo cp /etc/locale.conf "$BACKUP_DIR/locale.conf.bak"
fi

# Backup keyboard settings
if [ -f /etc/default/keyboard ]; then
    sudo cp /etc/default/keyboard "$BACKUP_DIR/keyboard.bak"
fi

print_success "Backup created in $BACKUP_DIR"

# -- Configure locale --
print_status "Configuring locale to $LOCALE..."

# Ensure the locale is available
if ! grep -q "^$LOCALE" /etc/locale.gen 2>/dev/null; then
    print_status "Enabling $LOCALE in /etc/locale.gen..."
    echo "$LOCALE UTF-8" | sudo tee -a /etc/locale.gen >/dev/null
fi

# Uncomment the locale if it's commented out
sudo sed -i "s/^# *$LOCALE/$LOCALE/" /etc/locale.gen

# Generate locales
print_status "Generating locales..."
sudo locale-gen

# Set system locale
print_status "Setting system locale..."
sudo tee /etc/default/locale >/dev/null <<EOF
LANG=$LOCALE
LC_ALL=$LOCALE
EOF

# Update locale.conf for systemd-based environments
print_status "Updating /etc/locale.conf..."
sudo tee /etc/locale.conf >/dev/null <<EOF
LANG=$LOCALE
LC_ALL=$LOCALE
EOF

# -- Configure keyboard layout --
print_status "Configuring keyboard layout to US International..."

# Create keyboard configuration
sudo tee /etc/default/keyboard >/dev/null <<EOF
# Keyboard configuration file
# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="$KEYBOARD_LAYOUT"
XKBVARIANT="$KEYBOARD_VARIANT"
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# -- Configure Hyprland if present --
HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRLAND_CONFIG" ]; then
    print_status "Configuring Hyprland keyboard settings..."
    
    # Backup Hyprland config
    cp "$HYPRLAND_CONFIG" "$BACKUP_DIR/hyprland.conf.bak"
    
    # Update Hyprland keyboard settings
    sed -i "s/^[[:space:]]*kb_layout[[:space:]]*=.*/    kb_layout = $KEYBOARD_LAYOUT/" "$HYPRLAND_CONFIG"
    sed -i "s/^[[:space:]]*kb_variant[[:space:]]*=.*/    kb_variant = $KEYBOARD_VARIANT/" "$HYPRLAND_CONFIG"
    sed -i "s/^[[:space:]]*kb_model[[:space:]]*=.*/    kb_model = pc105/" "$HYPRLAND_CONFIG"
    sed -i "s/^[[:space:]]*kb_options[[:space:]]*=.*/    kb_options =/" "$HYPRLAND_CONFIG"
    
    print_success "Hyprland configuration updated"
fi

# -- Configure Hyprland input.conf if present --
HYPRLAND_INPUT_CONFIG="$HOME/.config/hypr/input.conf"
if [ -f "$HYPRLAND_INPUT_CONFIG" ]; then
    print_status "Configuring Hyprland input.conf keyboard settings..."
    
    # Backup input.conf
    cp "$HYPRLAND_INPUT_CONFIG" "$BACKUP_DIR/input.conf.bak"
    
    # Update keyboard settings in input.conf within the input block
    if awk -v layout="$KEYBOARD_LAYOUT" -v variant="$KEYBOARD_VARIANT" '
    BEGIN { in_block = 0 }
    {
        if (!in_block && $0 ~ /^[[:space:]]*input[[:space:]]*{/) {
            indent = $0
            sub(/input[[:space:]]*\{.*/, "", indent)
            print indent "input {"
            print indent "  kb_layout = " layout
            print indent "  kb_variant = " variant
            print indent "  kb_model = pc105"
            print indent "  kb_options ="
            in_block = 1
            next
        }

        if (in_block) {
            if ($0 ~ /^[[:space:]]*kb_(layout|variant|model|options)[[:space:]]*=/) {
                next
            }
            if ($0 ~ /^[[:space:]]*}/) {
                print $0
                in_block = 0
                next
            }
        }

        print $0
    }
    ' "$HYPRLAND_INPUT_CONFIG" > "$BACKUP_DIR/input.conf.tmp" && \
    mv "$BACKUP_DIR/input.conf.tmp" "$HYPRLAND_INPUT_CONFIG"; then
        print_success "Hyprland input.conf updated"
    else
        print_error "Failed to update Hyprland input.conf. Original file preserved."
        rm -f "$BACKUP_DIR/input.conf.tmp"
    fi
fi

# -- Apply keyboard settings for current session --
print_status "Applying keyboard settings for current session..."

# For X11 session
if [ -n "$DISPLAY" ]; then
    if command -v setxkbmap >/dev/null 2>&1; then
        setxkbmap -layout "$KEYBOARD_LAYOUT" -variant "$KEYBOARD_VARIANT"
        print_success "Keyboard layout applied to current X11 session"
    fi
fi

# For console
if command -v loadkeys >/dev/null 2>&1; then
    # Try to load US international keymap for console
    if [ -f /usr/share/keymaps/i386/qwerty/us-acentos.kmap.gz ]; then
        sudo loadkeys us-acentos
        print_success "Console keymap set to US International"
    elif [ -f /usr/share/keymaps/i386/qwerty/us.kmap.gz ]; then
        sudo loadkeys us
        print_success "Console keymap set to US (basic)"
    fi
fi

# -- Configure cedilla support --
print_status "Configuring proper cedilla support..."

# Step 2: Fix GTK cedilla support
GTK3_IMMODULES="/usr/lib/gtk-3.0/3.0.0/immodules.cache"
GTK2_IMMODULES="/usr/lib/gtk-2.0/2.10.0/immodules.cache"

if [ -f "$GTK3_IMMODULES" ]; then
    print_status "Updating GTK3 immodules for cedilla support..."
    sudo cp "$GTK3_IMMODULES" "$BACKUP_DIR/gtk3-immodules.cache.bak"
    sudo sed -i 's/"cedilla" "Cedilla" "gtk30" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa"/"cedilla" "Cedilla" "gtk30" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa:en"/g' "$GTK3_IMMODULES"
    print_success "GTK3 immodules updated"
fi

if [ -f "$GTK2_IMMODULES" ]; then
    print_status "Updating GTK2 immodules for cedilla support..."
    sudo cp "$GTK2_IMMODULES" "$BACKUP_DIR/gtk2-immodules.cache.bak"
    sudo sed -i 's/"cedilla" "Cedilla" "gtk20" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa"/"cedilla" "Cedilla" "gtk20" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa:en"/g' "$GTK2_IMMODULES"
    print_success "GTK2 immodules updated"
fi

# Step 3: Fix X11 Compose sequences for cedilla
COMPOSE_FILE="/usr/share/X11/locale/en_US.UTF-8/Compose"
if [ -f "$COMPOSE_FILE" ]; then
    print_status "Fixing X11 Compose sequences for proper cedilla..."
    
    # Backup original Compose file
    sudo cp "$COMPOSE_FILE" "$BACKUP_DIR/Compose.bak"
    
    # Create temporary file with cedilla fixes
    TEMP_COMPOSE=$(mktemp)
    sed 's/ć/ç/g' < "$COMPOSE_FILE" | sed 's/Ć/Ç/g' > "$TEMP_COMPOSE"
    
    # Replace the original file
    sudo mv "$TEMP_COMPOSE" "$COMPOSE_FILE"
    
    print_success "X11 Compose sequences updated for cedilla"
else
    print_warning "X11 Compose file not found at $COMPOSE_FILE"
fi

# -- Update initramfs (for early boot keyboard layout) --
if command -v update-initramfs >/dev/null 2>&1; then
    print_status "Updating initramfs..."
    sudo update-initramfs -u
fi

# -- Set user environment variables --
print_status "Setting user environment variables..."

# Update user's .p.zshrc file
PROFILE_FILE="$HOME/.zshrc"

# Remove any existing locale exports to avoid duplicates
sed -i '/^export LANG=/d' "$PROFILE_FILE" 2>/dev/null || true
sed -i '/^export LC_ALL=/d' "$PROFILE_FILE" 2>/dev/null || true

# Add new locale exports
echo "" >> "$PROFILE_FILE"
echo "# Locale settings (added by us-intl-locale.sh)" >> "$PROFILE_FILE"
echo "export LANG=$LOCALE" >> "$PROFILE_FILE"
echo "export LC_ALL=$LOCALE" >> "$PROFILE_FILE"

print_success "Environment variables added to $PROFILE_FILE"

# -- Final instructions --
echo
echo "=========================================================="
print_success "🎉 Setup Complete! 🎉"
echo
print_status "Changes applied:"
echo "  • Locale: $LOCALE"
echo "  • System locale files: /etc/default/locale, /etc/locale.conf"
echo "  • Keyboard Layout: $KEYBOARD_LAYOUT ($KEYBOARD_VARIANT)"
echo "  • Backup created: $BACKUP_DIR"
echo
print_warning "IMPORTANT: To fully activate all changes, please:"
echo "  1. *** REBOOT YOUR COMPUTER *** (required for cedilla fixes)"
echo "  2. Or run: source $PROFILE_FILE (for locale only)"
echo
print_status "Cedilla configuration applied:"
echo "  • GTK2/GTK3 immodules updated to support English cedilla"
echo "  • X11 Compose sequences fixed (ć→ç, Ć→Ç)"
if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
    echo "  • Hyprland keyboard configuration updated"
fi
if [ -f "$HOME/.config/hypr/input.conf" ]; then
    echo "  • Hyprland input.conf keyboard configuration updated"
fi
echo
print_status "To verify the changes:"
echo "  • Check locale: locale"
echo "  • Inspect locale.conf: cat /etc/locale.conf"
echo "  • Check keyboard: setxkbmap -query"
echo "  • Test cedilla: Right Alt + , then c should produce ç"
echo
print_status "US International keyboard shortcuts:"
echo "  • Acute (´): Right Alt + e, then vowel (é, á, etc.)"
echo "  • Grave (\`): Right Alt + \`, then vowel (è, à, etc.)"
echo "  • Circumflex (^): Right Alt + 6, then vowel (ê, â, etc.)"
echo "  • Tilde (~): Right Alt + n, then n (ñ) or vowel (ã, õ)"
echo "  • Umlaut (¨): Right Alt + \", then vowel (ü, ä, etc.)"
echo "  • Cedilla (ç): Right Alt + , then c"
echo "=========================================================="
