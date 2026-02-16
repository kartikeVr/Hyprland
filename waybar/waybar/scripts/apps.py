#!/usr/bin/env python3
"""
windows.py - GTK4 Window Switcher for Hyprland
Usage:
  * windows.py          # Prints JSON for Waybar (count of open windows)
  * windows.py --popup  # Opens the switcher popup
"""

import sys
import json
import subprocess
import shlex
import os
import gi

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GLib, Gdk

def run_command(command):
    try:
        return subprocess.check_output(shlex.split(command), stderr=subprocess.DEVNULL).decode().strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""

def get_windows():
    """Returns a list of open windows from Hyprland."""
    try:
        output = run_command("hyprctl clients -j")
        clients = json.loads(output)
        # Sort by workspace ID for cleaner list
        clients.sort(key=lambda x: x['workspace']['id'])
        return clients
    except json.JSONDecodeError:
        return []

def focus_window(address):
    """Focuses the window with the given address."""
    subprocess.Popen(["hyprctl", "dispatch", "focuswindow", f"address:{address}"])

# --- Waybar JSON Emitter ---
def emit_json():
    wins = get_windows()
    count = len(wins)
    
    # Text to display on the bar
    if count == 0:
        text = "0 Windows"
        tooltip = "Desktop Empty"
        css_class = "empty"
    else:
        text = f"{count} Windows"
        tooltip = "Click to switch windows"
        css_class = "active"
        
    out = {"text": f"  {text}", "tooltip": tooltip, "class": css_class}
    print(json.dumps(out))
    sys.stdout.flush()

# --- GTK4 Popup Application ---
class WindowSwitcher(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.example.window_switcher")

    def do_activate(self):
        win = Gtk.ApplicationWindow(application=self)
        win.set_title("Window Switcher")
        win.set_decorated(False)
        win.set_resizable(False)
        
        # Reuse your Pywal colors!
        self.load_pywal_css(win)

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_start(15)
        main_box.set_margin_end(15)
        main_box.set_margin_top(15)
        main_box.set_margin_bottom(15)

        self.create_list(main_box)
        win.set_child(main_box)
        win.present()

    def load_pywal_css(self, win):
        wal_css_path = os.path.expanduser("~/.cache/wal/colors.css")
        if os.path.exists(wal_css_path):
            provider = Gtk.CssProvider()
            provider.load_from_path(wal_css_path)
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

    def create_list(self, main_box):
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        lbl = Gtk.Label(label="<b>Open Applications</b>")
        lbl.set_use_markup(True)
        lbl.set_xalign(0)
        
        # Close Button
        close_btn = Gtk.Button(label="Close Menu")
        close_btn.connect("clicked", lambda x: self.quit())
        
        header_box.append(lbl)
        header_box.append(close_btn)
        main_box.append(header_box)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_min_content_height(300) # Limit height if you have many apps
        scroll.set_max_content_height(500)
        scroll.set_propagate_natural_height(True)
        
        list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        scroll.set_child(list_box)
        main_box.append(scroll)

        windows = get_windows()
        if not windows:
             list_box.append(Gtk.Label(label="No windows found."))

        for w in windows:
            if w['class'] == "": continue # Skip ghost windows

            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            
            # Label: [WS 1] Title
            ws_id = w['workspace']['id']
            title = w['title']
            if len(title) > 40: title = title[:37] + "..."
            
            label_text = f"<b>[{ws_id}]</b> {title}"
            lbl = Gtk.Label(label=label_text)
            lbl.set_use_markup(True)
            lbl.set_xalign(0)
            lbl.set_hexpand(True) # Push button to the right

            # Switch Button
            btn = Gtk.Button(label="Switch")
            
            # Closure to capture the specific address
            def make_cb(addr):
                def cb(widget):
                    focus_window(addr)
                    self.quit()
                return cb
            
            btn.connect("clicked", make_cb(w['address']))
            
            row.append(lbl)
            row.append(btn)
            list_box.append(row)

if __name__ == "__main__":
    if "--popup" in sys.argv:
        app = WindowSwitcher()
        app.run(None)
    else:
        emit_json()
