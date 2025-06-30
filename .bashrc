# .bashrc

# If not running interactively, don't do anything
# It's good practice to have this near the top.
[[ $- != *i* ]] && return

# Basic aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
alias cleanram='sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"'
# System upgrade and cache remover
upgrade() {
    echo "Starting system upgrade..."
    sudo pacman -Syu
    if [ $? -eq 0 ]; then
        echo "Upgrade successful! Cleaning cache..."
        sudo pacman -Sc --noconfirm
    else
        echo "Upgrade failed. Skipping cache cleanup."
    fi
}
# Editor settings
export EDITOR="nano"
export VISUAL="nano"
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=wayland
export UV_LINK_MODE=copy
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
eval "$(dbus-launch --sh-syntax)"
# Starship Prompt Configuration
# Ensure this is the LAST thing that tries to set your prompt.
export STARSHIP_CONFIG="/home/kartike/.config/starship/starship.toml"
eval "$(/usr/bin/starship init bash --print-full-init)"

# Advanced package manager wrapper
download() {
    local package=""
    local search_only=false
    local skip_update=false
    local force_manager=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--search)
                search_only=true
                shift
                ;;
            -n|--no-update)
                skip_update=true
                shift
                ;;
            -m|--manager)
                force_manager="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: download [options] <package_name>"
                echo "Options:"
                echo "  -s, --search      Search for package instead of installing"
                echo "  -n, --no-update   Skip system update"
                echo "  -m, --manager     Force specific package manager (pacman/yay/paru/snap/flatpak)"
                echo "  -h, --help        Show this help message"
                echo ""
                echo "Examples:"
                echo "  download firefox"
                echo "  download -s spotify"
                echo "  download -m snap discord"
                echo "  download -n vlc"
                return 0
                ;;
            *)
                package="$1"
                shift
                ;;
        esac
    done
    
    # Check if package name was provided
    if [ -z "$package" ]; then
        echo "Error: No package name provided"
        echo "Usage: download [options] <package_name>"
        return 1
    fi
    
    # Search mode
    if [ "$search_only" = true ]; then
        echo "=== Searching for '$package' ==="
        
        echo -e "\n--- Pacman ---"
        pacman -Ss "$package" 2>/dev/null | head -10
        
        if command -v yay &> /dev/null; then
            echo -e "\n--- AUR (yay) ---"
            yay -Ss "$package" 2>/dev/null | head -10
        fi
        
        if command -v snap &> /dev/null; then
            echo -e "\n--- Snap ---"
            snap search "$package" 2>/dev/null | head -10
        fi
        
        if command -v flatpak &> /dev/null; then
            echo -e "\n--- Flatpak ---"
            flatpak search "$package" 2>/dev/null | head -10
        fi
        
        return 0
    fi
    
    # Update system unless skipped
    if [ "$skip_update" = false ]; then
        echo "=== Updating System ==="
        sudo pacman -Syu || echo "Warning: System update failed, continuing..."
        echo ""
    fi
    
    # Install package
    local installed=false
    
    # Function to try installation with a specific manager
    try_install() {
        local manager="$1"
        local cmd="$2"
        
        if [ -n "$force_manager" ] && [ "$force_manager" != "$manager" ]; then
            return 1
        fi
        
        if command -v ${cmd%% *} &> /dev/null; then
            echo "Trying $manager..."
            if eval "$cmd"; then
                echo "✓ Successfully installed $package with $manager"
                installed=true
                return 0
            fi
        fi
        return 1
    }
    
    # Try different package managers
    echo "=== Installing $package ==="
    
    try_install "pacman" "sudo pacman -S '$package' --noconfirm" || \
    try_install "yay" "yay -S '$package' --noconfirm" || \
    try_install "paru" "paru -S '$package' --noconfirm" || \
    try_install "snap" "sudo snap install '$package'" || \
    try_install "flatpak" "flatpak install -y flathub '$package'"
    
    # Show result
    if [ "$installed" = true ]; then
        echo -e "\n✓ Installation complete!"
        sudo pacman -Sc --noconfirm
    else
        echo -e "\n✗ Failed to install $package"
        echo "Try: download -s $package   to search for the correct package name"
    fi
}

# Also create shorter aliases
alias dl='download'
alias dls='download -s'
alias dln='download -n'

# Remove packages with similar logic
remove() {
    local package="$1"
    
    if pacman -Q "$package" &> /dev/null; then
        sudo pacman -Rns "$package"
    elif command -v snap &> /dev/null && snap list | grep -q "^$package "; then
        sudo snap remove "$package"
    elif command -v flatpak &> /dev/null && flatpak list | grep -qi "$package"; then
        flatpak uninstall "$package"
    else
        echo "Package $package not found"
    fi
}

# Update all package managers
update-all() {
    echo "=== Updating All Package Managers ==="
    
    echo -e "\n--- Pacman ---"
    sudo pacman -Syu
    
    if command -v yay &> /dev/null; then
        echo -e "\n--- AUR (yay) ---"
        yay -Syu
    fi
    
    if command -v snap &> /dev/null; then
        echo -e "\n--- Snap ---"
        sudo snap refresh
    fi
    
    if command -v flatpak &> /dev/null; then
        echo -e "\n--- Flatpak ---"
        flatpak update -y
    fi
    
    echo -e "\n=== Cleaning Caches ==="
    sudo pacman -Sc --noconfirm
}
