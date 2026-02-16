#!/bin/bash

# This script creates symlinks from the home directory to the dotfiles in this repository.

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# List of directories to symlink
directories=(
    Ghostty
    elephant
    hypr
    nvim
    swaylock
    waybar
    walker
    wlogout
)

# List of files to symlink
files=(
    hyprland.conf
    kitty.conf
    pyprland.toml
    starship.toml
)

# Create symlinks for directories
for dir in "${directories[@]}"; do
    ln -s -f "$DIR/$dir" "$HOME/.config/$dir"
    echo "Symlinked $DIR/$dir to $HOME/.config/$dir"
done

# Create symlinks for files
for file in "${files[@]}"; do
    ln -s -f "$DIR/$file" "$HOME/.config/$file"
    echo "Symlinked $DIR/$file to $HOME/.config/$file"
done

echo "Done."
