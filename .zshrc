#!/bin/zsh

# ------------------------------------------------------------------------------
# 🚀 Powerlevel10k Instant Prompt
# This must stay at the top for near-instant terminal startup.
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# 📦 Oh My Zsh Configuration
# ------------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# Set the theme. Powerlevel10k is configured here.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Add your desired plugins.
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
)

# Source Oh My Zsh to load everything.
source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------------------
# 🔧 Environment & Editor Settings
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"

# Wayland & Hyprland specific variables.
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=hyprland

# Python (pyenv) configuration.
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# --- Starship Prompt (Disabled) ---
# NOTE: The ZSH_THEME is set to Powerlevel10k. Enabling Starship will override
# it. Choose one or the other.
# if command -v starship &>/dev/null; then
#   export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
#   eval "$(starship init zsh)"
# fi

# ------------------------------------------------------------------------------
# ✨ Aliases
# ------------------------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -alFh' # Added -h for human-readable sizes
alias grep='grep --color=auto'
alias upgrade='update-all' # Alias for the main update function
alias battery-health="upower -i '/org/freedesktop/UPower/devices/battery_BAT1'"

# Aliases for the 'download' package manager wrapper
alias dl='download'
alias dls='download --search'
alias dln='download --no-update'

# ------------------------------------------------------------------------------
# 🛠️ Custom Functions
# ------------------------------------------------------------------------------

##
# update-all: Updates official repositories and the AUR, then cleans caches.
##

cleanram() {
  echo "
🗑️ The following package files will be deleted, keeping the 3 most recent versions:"
  echo "----------------------------------------------------------------------"
  
  # Perform a verbose dry run to show the user what will be removed
  paccache -v --dryrun --keep=3

  # Check if there are actually any files to remove
  # We run the command again without verbose to check its output
  local files_to_delete=$(paccache --dryrun --keep=3)
  if [[ -z "$files_to_delete" ]]; then
    echo "
✅ Your package cache is already clean. Nothing to do."
    return 0
  fi
  
  echo "----------------------------------------------------------------------"
  
  # Ask for confirmation before deleting
  read -q "REPLY?Proceed with deletion? [y/N] "
  echo # Move to the next line for cleaner output

  # If the user types 'y' or 'Y', proceed with the deletion
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    echo "
    󰈸Deleting files..."
    sudo paccache --remove --keep=3
    echo "
✨ Cache cleaned successfully."
  else
    echo "
❌ Operation cancelled."
  fi
}

update-all() {
  echo "---  Starting full system upgrade ---"

  echo -e "\n[1/3] Updating Official Repositories (pacman)..."
  sudo pacman -Syu --noconfirm

  if command -v yay &>/dev/null; then
    echo -e "\n[2/3] Updating AUR Packages (yay)..."
    yay -Syu --noconfirm
  elif command -v paru &>/dev/null; then
    echo -e "\n[2/3] Updating AUR Packages (paru)..."
    paru -Syu --noconfirm
  else
    echo -e "\n[2/3] No AUR helper (yay/paru) found. Skipping."
  fi

  echo -e "\n[3/3] Cleaning up package caches..."
  sudo pacman -Sc --noconfirm

  echo -e "\n✅ System update complete!"
}


##
# download: A wrapper to search for and install packages.
# Tries pacman, then yay, then paru unless a specific manager is forced.
##
download() {
  local package=""
  local search_only=false
  local skip_update=false
  local force_manager=""

  # --- Argument Parsing ---
  while (( $# > 0 )); do
    case "$1" in
      -s|--search)    search_only=true; shift ;;
      -n|--no-update) skip_update=true; shift ;;
      -m|--manager)   force_manager="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: download [options] <package_name>"
        echo "A wrapper to install packages using pacman, yay, or paru."
        echo
        echo "Options:"
        echo "  -s, --search      Search for a package instead of installing."
        echo "  -n, --no-update   Skip the initial system update check."
        echo "  -m, --manager     Force a specific manager (pacman, yay, paru)."
        echo "  -h, --help        Show this help message."
        return 0
        ;;
      *)
        package="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$package" ]]; then
    echo "Error: No package name provided. Use -h for help." >&2
    return 1
  fi

  # --- Search Logic ---
  if [[ "$search_only" == true ]]; then
    echo "--- 🔍 Searching for '$package' ---"
    command -v pacman &>/dev/null && echo -e "\n--- Official Repositories (pacman) ---" && pacman -Ss "$package"
    command -v yay &>/dev/null && echo -e "\n--- AUR (yay) ---" && yay -Ss "$package"
    command -v paru &>/dev/null && echo -e "\n--- AUR (paru) ---" && paru -Ss "$package"
    return 0
  fi

  # --- Pre-Install System Update ---
  if [[ "$skip_update" == false ]]; then
    update-all
  fi

  # --- Installation Logic ---
  echo -e "\n--- 📦 Attempting to install '$package' ---"
  local managers=("pacman" "yay" "paru")
  local installed=false

  for mgr in "${managers[@]}"; do
    # If a manager is forced, skip all others.
    if [[ -n "$force_manager" && "$force_manager" != "$mgr" ]]; then
      continue
    fi

    # Check if the manager command exists.
    if ! command -v "$mgr" &>/dev/null; then
      continue
    fi
    
    echo "-> Trying with $mgr..."
    local cmd
    # Use sudo for pacman, but not for AUR helpers.
    if [[ "$mgr" == "pacman" ]]; then
      cmd="sudo pacman -S --noconfirm '$package'"
    else
      cmd="$mgr -S --noconfirm '$package'"
    fi

    # Execute the command. If successful, mark as installed and stop.
    if eval "$cmd"; then
      installed=true
      echo -e "\n✅ Successfully installed '$package' with $mgr!"
      break
    fi
  done

  # --- Final Status ---
  if [[ "$installed" == false ]]; then
    echo -e "\n❌ Failed to install '$package' with all available managers."
    echo "💡 Tip: Try searching first with 'dls $package' to find the correct name."
    return 1
  fi
}
# Add this function to your .zshrc file
remove() {
  if [ "$#" -eq 0 ]; then
        echo "Error: No package names provided."
        echo "Usage: remove_packages <package1> <package2> ..."
        return 1
    fi

    # Iterate over all provided package names
    for package in "$@"; do
        echo "Attempting to remove package: $package"
        
        # Check if the package is installed
        if pacman -Q "$package" > /dev/null 2>&1; then
            # Remove the package
            sudo pacman -Rns "$package" --noconfirm
            if [ $? -eq 0 ]; then
                echo "Successfully removed: $package"
            else
                echo "Failed to remove: $package"
            fi
        else
            echo "Package '$package' is not installed or does not exist."
        fi
    done
    # Check if a package name is provided
}

# ------------------------------------------------------------------------------
# 🎨 Powerlevel10k User Configuration
# Source your p10k config file. This must be at the end.
# ------------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
