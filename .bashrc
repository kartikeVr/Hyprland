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
