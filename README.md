# 🌌 Hyprland Desktop Dotfiles

A sleek, modern, and high-performance desktop environment built on **Hyprland**, **Waybar**, **Walker**, **Ghostty**, and **Pywal**.

---

## ⚡ Quick Start

Clone the repository and run the setup script:

```bash
git clone https://github.com/kartikeVr/Hyprland.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Optionally install required system and AUR packages (on Arch Linux).
2. Automatically create symlinks in `~/.config` and `~/.local/bin`.
3. Configure shell integration (`~/.zshrc`, `starship.toml`).
4. Generate Pywal fallback color schemes so Waybar and Hyprland launch cleanly on first boot.
5. Set proper execution permissions for all helper scripts.

---

## 🏗️ Architecture & Components

| Component | Tool / Config | Description |
| :--- | :--- | :--- |
| **Compositor** | [Hyprland](hypr/hyprland.conf) | Dynamic tiling Wayland compositor with custom animations, window rules, and dual config support (`hyprland.conf` & `hyprland.lua`). |
| **Status Bar** | [Waybar](waybar/config.jsonc) | Neumorphic/3D aesthetic bar with dynamic latency, network, bluetooth, interactive popups, and live updates. |
| **Terminal** | [Ghostty](Ghostty/config) / [Kitty](kitty.conf) | GPU-accelerated terminal with custom cursor blaze shaders and transparency. |
| **App Launcher** | [Walker](walker/config.toml) & [Elephant](elephant/config.toml) | Fast, responsive application launcher and provider search. |
| **Shell** | [Zsh](.zshrc) & [Starship](starship.toml) | Fast zsh prompt with plugin management and autocompletions. |
| **Lock Screen** | [Swaylock](swaylock/config) | Minimal lock screen configuration. |
| **Power Menu** | [Wlogout](wlogout/layout) | Neumorphic logout, suspend, reboot, and power-off overlay. |
| **Editor** | [Neovim](nvim/init.lua) | Modern LazyVim-based IDE configuration with full LSP support. |
| **Wallpaper & Theming** | [Pywal](hypr/wallpaperSwitcher.sh) | Automated color scheme extraction from wallpaper images and video backgrounds (`mpvpaper` / `awww`). |

---

## ⌨️ Essential Keybindings

| Keybinding | Action |
| :--- | :--- |
| `Super + Enter` | Launch Terminal (Ghostty / Kitty) |
| `Super + Space` | Application Launcher (Walker) |
| `Super + E` | File Manager (Thunar) |
| `Super + Q` | Close active window |
| `Super + V` | Toggle floating mode |
| `Super + Shift + S` | Switch random wallpaper & re-theme desktop |
| `Super + Backspace` | Power menu (Wlogout) |
| `Super + Shift + W` | Wi-Fi Manager popup |

---

## 📦 Requirements

- **Base System**: Arch Linux (or any modern Linux distribution running Wayland)
- **Audio / Media**: `pipewire`, `wireplumber`, `playerctl`
- **Network / Bluetooth**: `NetworkManager` (`nmcli`), `bluez`, `bluez-utils`
- **Theming**: `pywal` or `pywal16`, `awww` (or `swww`), `mpvpaper`

Refer to [`Packages`](Packages) for the complete list of recommended packages.
