#!/usr/bin/env python3
"""
apps.py - High-Efficiency Dynamic Window Manager for Hyprland
Using GTK Layer Shell for true Wayland popup behavior and Pywal theming.
"""

import sys
import json
import subprocess
import shlex
import os
import gi

gi.require_version('Gtk', '3.0')
try:
    gi.require_version('GtkLayerShell', '0.1')
    from gi.repository import GtkLayerShell
except ValueError:
    GtkLayerShell = None

from gi.repository import Gtk, GLib, Gdk

def run_command(command):
    try:
        return subprocess.check_output(shlex.split(command), stderr=subprocess.DEVNULL).decode().strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""

def get_windows():
    try:
        output = run_command("hyprctl clients -j")
        clients = json.loads(output)
        return [c for c in clients if c.get('class', '') != ""]
    except json.JSONDecodeError:
        return []

def focus_window(address):
    subprocess.Popen(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])

def kill_window(address):
    subprocess.Popen(["hyprctl", "dispatch", "closewindow", f"address:{address}"])

def emit_json():
    wins = get_windows()
    count = len(wins)
    out = {
        "text": f"  {count}",
        "tooltip": f"{count} Windows\nClick to Manage",
        "class": "active" if count > 0 else "empty"
    }
    print(json.dumps(out))
    sys.stdout.flush()

def get_wal_colors():
    wal_json = os.path.expanduser("~/.cache/wal/colors.json")
    # Default fallback colors
    colors = {
        "background": "#1e1e2e",
        "foreground": "#cdd6f4",
        "color0": "#1e1e2e",
        "color1": "#f38ba8",
        "color2": "#a6e3a1",
        "color3": "#f9e2af",
        "color4": "#89b4fa",
        "color7": "#cdd6f4",
        "color8": "#313244",
        "color15": "#ffffff"
    }
    if os.path.exists(wal_json):
        try:
            with open(wal_json, 'r') as f:
                data = json.load(f)
                colors["background"] = data["special"]["background"]
                colors["foreground"] = data["special"]["foreground"]
                for i in range(16):
                    colors[f"color{i}"] = data["colors"][f"color{i}"]
        except Exception:
            pass
    return colors

def apply_css():
    c = get_wal_colors()
    
    # Matching font and background to Pywal exactly
    # Darker background for buttons (color0 or color8) and light colors for text (foreground/color7)
    css = f"""
    window {{
        background-color: transparent;
    }}
    .popup-window {{
        background-color: {c['background']};
        border: 2px solid {c['color4']};
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }}
    label {{
        color: {c['foreground']};
        font-family: "JetBrainsMono Nerd Font", "Sans";
        font-size: 13px;
        margin: 5px;
    }}
    .header {{
        font-size: 14px;
        color: {c['color4']};
        margin-bottom: 10px;
    }}
    .app-row {{
        padding: 5px;
        border-bottom: 1px solid {c['color8']};
    }}
    .focus-btn {{
        background-color: {c['background']};
        background-image: none;
        color: {c['color2']};
        font-weight: bold;
        border-radius: 4px;
        padding: 4px 10px;
        border: 1px solid {c['color2']};
        box-shadow: none;
    }}
    .focus-btn:hover {{
        background-color: {c['color2']};
        background-image: none;
        color: {c['background']};
    }}
    .kill-btn {{
        background-color: {c['background']};
        background-image: none;
        color: {c['color1']};
        font-weight: bold;
        border-radius: 4px;
        padding: 4px 10px;
        border: 1px solid {c['color1']};
        box-shadow: none;
    }}
    .kill-btn:hover {{
        background-color: {c['color1']};
        background-image: none;
        color: {c['background']};
    }}
    .close-btn {{
        background-color: {c['color0']};
        background-image: none;
        color: {c['foreground']};
        border-radius: 4px;
        margin-top: 10px;
        border: 1px solid {c['color4']};
        box-shadow: none;
    }}
    .close-btn:hover {{
        background-color: {c['color4']};
        color: {c['color8']};
    }}
    """.encode()
    
    style_provider = Gtk.CssProvider()
    style_provider.load_from_data(css)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        style_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

def popup_show():
    windows = get_windows()
    
    win = Gtk.Window()
    win.set_title("WaybarWindowManagerPopup")
    
    if GtkLayerShell:
        GtkLayerShell.init_for_window(win)
        GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_namespace(win, "waybar-popup")
        
        GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, False)
        GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, False)
        GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, False)
        GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, False)
        
        GtkLayerShell.set_exclusive_zone(win, -1)
        GtkLayerShell.set_keyboard_interactivity(win, True)
    else:
        win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        win.set_keep_above(True)

    win.get_style_context().add_class("popup-window")
    apply_css()

    main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    main_box.set_border_width(12)

    header = Gtk.Label()
    header.set_markup("<span font_weight='bold' size='large'>WINDOW MANAGER</span>")
    header.get_style_context().add_class("header")
    main_box.pack_start(header, False, False, 0)

    if not windows:
        main_box.pack_start(Gtk.Label(label="No windows found"), False, False, 10)
    else:
        for w in windows:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            row.get_style_context().add_class("app-row")

            app_cls = w['class'][:12]
            lbl_cls = Gtk.Label(label=f"[{app_cls}]")
            
            title_text = w['title']
            if len(title_text) > 25: title_text = title_text[:22] + "..."
            lbl_title = Gtk.Label(label=title_text)
            lbl_title.set_hexpand(True)
            lbl_title.set_xalign(0)

            btn_focus = Gtk.Button(label="Focus")
            btn_focus.get_style_context().add_class("focus-btn")
            
            btn_kill = Gtk.Button(label="Kill")
            btn_kill.get_style_context().add_class("kill-btn")

            def make_focus_cb(addr):
                return lambda b: [focus_window(addr), Gtk.main_quit()]
            
            def make_kill_cb(addr):
                return lambda b: [kill_window(addr), Gtk.main_quit()]

            btn_focus.connect("clicked", make_focus_cb(w['address']))
            btn_kill.connect("clicked", make_kill_cb(w['address']))

            row.pack_start(lbl_cls, False, False, 0)
            row.pack_start(lbl_title, True, True, 0)
            row.pack_start(btn_focus, False, False, 2)
            row.pack_start(btn_kill, False, False, 2)
            
            main_box.pack_start(row, False, False, 0)

    close_btn = Gtk.Button(label="Close")
    close_btn.get_style_context().add_class("close-btn")
    close_btn.connect("clicked", lambda b: Gtk.main_quit())
    main_box.pack_start(close_btn, False, False, 5)

    def on_key_press(widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False

    win.connect("key-press-event", on_key_press)
    win.add(main_box)
    win.show_all()
    
    GLib.timeout_add_seconds(10, Gtk.main_quit)
    
    Gtk.main()

if __name__ == "__main__":
    if "--popup" in sys.argv:
        popup_show()
    else:
        emit_json()
