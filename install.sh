#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installation & Setup Script for Hyprland Desktop Environment
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${BOLD}Installing dotfiles from:${RESET} ${DOTFILES_DIR}\n"

# ------------------------------------------------------------------------------
# 1. Package Installation (Optional / Interactive)
# ------------------------------------------------------------------------------
install_packages() {
    if ! command -v pacman &>/dev/null; then
        warn "Non-Arch distribution detected. Skipping automated package installation."
        return 0
    fi

    local pkg_file="${DOTFILES_DIR}/Packages"
    if [ ! -f "$pkg_file" ]; then
        return 0
    fi

    # Extract clean list of package names
    local packages
    packages=$(sed -e 's/#.*//' -e 's/\\//g' "$pkg_file" | tr -s '[:space:]' '\n' | grep -v '^$')

    echo -e "${YELLOW}Would you like to install required system packages listed in Packages? [y/N]${RESET} "
    read -r -t 15 response || response="n"
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        info "Installing packages..."
        local aur_helper=""
        if command -v paru &>/dev/null; then
            aur_helper="paru"
        elif command -v yay &>/dev/null; then
            aur_helper="yay"
        fi

        if [ -n "$aur_helper" ]; then
            info "Using AUR helper: $aur_helper"
            $aur_helper -S --needed --noconfirm $packages || warn "Some AUR packages failed to install."
        else
            warn "No AUR helper (paru/yay) found. Installing standard packages via pacman..."
            sudo pacman -S --needed --noconfirm $(echo "$packages" | grep -v '\-bin\|\-git') || true
        fi
    else
        info "Skipping package installation. You can review 'Packages' manually."
    fi
}

install_packages

# ------------------------------------------------------------------------------
# 2. Directory Structure Preparation
# ------------------------------------------------------------------------------
info "Preparing directories in $HOME..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/starship"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.cache/wal"
mkdir -p "$HOME/Pictures/wallpapers"

# ------------------------------------------------------------------------------
# 3. Symlink Configuration Directories
# ------------------------------------------------------------------------------
declare -A dir_mappings=(
    ["hypr"]="hypr"
    ["waybar"]="waybar"
    ["Ghostty"]="ghostty"
    ["nvim"]="nvim"
    ["swaylock"]="swaylock"
    ["walker"]="walker"
    ["elephant"]="elephant"
    ["wlogout"]="wlogout"
)

info "Symlinking configuration directories into ~/.config/..."
for src in "${!dir_mappings[@]}"; do
    dest="${dir_mappings[$src]}"
    target="$HOME/.config/$dest"
    
    # Avoid nested symlinks or conflicts
    if [ -L "$target" ] || [ -d "$target" ]; then
        rm -rf "$target"
    fi
    ln -s "$DOTFILES_DIR/$src" "$target"
    success "Symlinked $src -> ~/.config/$dest"
done

# Compatibility link for Ghostty case-sensitivity
if [ ! -e "$HOME/.config/Ghostty" ]; then
    ln -s "$DOTFILES_DIR/Ghostty" "$HOME/.config/Ghostty"
fi

# ------------------------------------------------------------------------------
# 4. Symlink Standalone Configuration Files
# ------------------------------------------------------------------------------
info "Symlinking standalone configuration files..."

# .zshrc
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    backup="$HOME/.zshrc.bak.$(date +%s)"
    warn "Existing ~/.zshrc found. Backing up to $backup"
    mv "$HOME/.zshrc" "$backup"
fi
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
success "Symlinked .zshrc -> ~/.zshrc"

# kitty.conf
ln -sf "$DOTFILES_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
success "Symlinked kitty.conf -> ~/.config/kitty/kitty.conf"

# starship.toml (both locations for compatibility)
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship/starship.toml"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
success "Symlinked starship.toml -> ~/.config/starship.toml"

# menu_fix.sh
if [ -f "$DOTFILES_DIR/menu_fix.sh" ]; then
    ln -sf "$DOTFILES_DIR/menu_fix.sh" "$HOME/.local/bin/menu_fix.sh"
    chmod +x "$HOME/.local/bin/menu_fix.sh"
    success "Symlinked menu_fix.sh -> ~/.local/bin/menu_fix.sh"
fi

# ------------------------------------------------------------------------------
# 5. Fix Script Execution Permissions
# ------------------------------------------------------------------------------
info "Setting executable permissions on scripts..."
chmod +x "$DOTFILES_DIR/install.sh"
chmod +x "$DOTFILES_DIR"/hypr/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/hypr/scripts/* 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/waybar/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/waybar/scripts/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/waybar/scripts/*.py 2>/dev/null || true
success "Permissions set."

# ------------------------------------------------------------------------------
# 6. Fallback Color Scheme (Ensures Hyprland/Waybar boot without Pywal cache)
# ------------------------------------------------------------------------------
info "Checking Pywal cache fallbacks..."
if [ ! -f "$HOME/.cache/wal/colors-hyprland.conf" ]; then
    cat <<'EOF' > "$HOME/.cache/wal/colors-hyprland.conf"
$color1 = rgba(244, 213, 107, 1.0)
$color14 = rgba(187, 185, 185, 1.0)
$background = rgba(18, 18, 24, 1.0)
$foreground = rgba(230, 230, 230, 1.0)
EOF
    success "Created fallback ~/.cache/wal/colors-hyprland.conf"
fi

if [ ! -f "$HOME/.cache/wal/colors-waybar.css" ]; then
    cat <<'EOF' > "$HOME/.cache/wal/colors-waybar.css"
@define-color background #121218;
@define-color foreground #e6e6e6;
@define-color color0 #121218;
@define-color color1 #e06c75;
@define-color color2 #98c379;
@define-color color3 #e5c07b;
@define-color color4 #61afef;
@define-color color5 #c678dd;
@define-color color6 #56b6c2;
@define-color color7 #abb2bf;
@define-color color8 #5c6370;
EOF
    success "Created fallback ~/.cache/wal/colors-waybar.css"
fi

# ------------------------------------------------------------------------------
# 7. Complete
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}==============================================================================${RESET}"
echo -e "${GREEN}${BOLD} Installation Complete!${RESET}"
echo -e "${GREEN}${BOLD}==============================================================================${RESET}"
echo -e "Next steps:"
echo -e "  1. Reload Hyprland with:  ${BOLD}hyprctl reload${RESET}"
echo -e "  2. Set your wallpaper:    ${BOLD}~/.config/hypr/wallpaperSwitcher.sh${RESET}"
echo -e "  3. Restart Waybar with:   ${BOLD}killall waybar && waybar &${RESET}\n"
