#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 GOTY Stand - Non-Intrusive Tactical Pip-Boy HUD Overlay
================================================================
Creates a floating, focus-free tactical HUD card on top of the game screen.
Supports:
  - Instant Toggle (show if hidden, hide if shown) via PID file
  - Structured tactical route cards (Header, Layer/Verticality, Step-by-step route)
  - Auto-dismiss after timeout (default 8s)
  - Zero input interception (accept_focus: False, keep_above: True)
"""

import sys
import os
import signal
import json

if "DISPLAY" not in os.environ:
    os.environ["DISPLAY"] = ":0.0"

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk

PID_FILE = "/tmp/fo4_hud_overlay.pid"
ACTIVE_ROUTE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scratch/active_route.json")

def is_pid_running(pid):
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False

def toggle_check():
    """Returns True if already running and was terminated; False if we should show new HUD."""
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            if is_pid_running(pid):
                os.kill(pid, signal.SIGTERM)
                try:
                    os.remove(PID_FILE)
                except Exception:
                    pass
                return True
        except Exception:
            pass
        try:
            os.remove(PID_FILE)
        except Exception:
            pass
    return False

def load_active_route():
    if os.path.exists(ACTIVE_ROUTE_FILE):
        try:
            with open(ACTIVE_ROUTE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "header": "[USAF OLIVIA // ТАКТИЧНИЙ МАРШРУТ]",
        "layer": "ЯРУС: -2 (Підвал / Реактор)",
        "steps": [
            "1. ⭳ Спуск під містки праворуч від реактора",
            "2. ⛨ Комора праворуч [Замок: Новачок]",
            "3. 🧰 Футляр для інструментів на стелажі"
        ],
        "footer": "⚡ Натисніть [Ліва + Середня педаль] для закриття"
    }

def display_hud_card(card_data=None, duration_sec=8.0):
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    def cleanup():
        try:
            if os.path.exists(PID_FILE):
                with open(PID_FILE, "r") as f:
                    if f.read().strip() == str(os.getpid()):
                        os.remove(PID_FILE)
        except Exception:
            pass

    win = Gtk.Window(type=Gtk.WindowType.POPUP)
    win.set_decorated(False)
    win.set_keep_above(True)
    win.set_accept_focus(False)
    win.set_app_paintable(True)
    
    # Position in top-right corner of 1920x1080 screen
    win.set_default_size(430, 160)
    win.move(1920 - 460, 45)

    css = b"""
    window {
        background-color: rgba(6, 18, 6, 0.94);
        border: 2px solid #1bf71b;
        border-radius: 8px;
        box-shadow: 0 0 16px rgba(27, 247, 27, 0.65);
        padding: 12px 16px;
    }
    label.header {
        color: #ffb833;
        font-family: monospace, sans-serif;
        font-weight: bold;
        font-size: 15px;
        letter-spacing: 1px;
    }
    label.layer {
        color: #ffcc66;
        font-family: monospace, sans-serif;
        font-weight: bold;
        font-size: 13px;
        margin-bottom: 4px;
    }
    label.step {
        color: #e0ffe0;
        font-family: monospace, sans-serif;
        font-size: 13px;
    }
    label.footer {
        color: #72b372;
        font-family: monospace, sans-serif;
        font-size: 11px;
        margin-top: 6px;
    }
    """
    provider = Gtk.CssProvider()
    provider.load_from_data(css)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

    if not card_data:
        card_data = load_active_route()

    l_header = Gtk.Label(label=card_data.get("header", "[ТАКТИЧНИЙ МАРШРУТ]"))
    l_header.get_style_context().add_class("header")
    l_header.set_xalign(0.0)
    box.pack_start(l_header, False, False, 0)

    if "layer" in card_data and card_data["layer"]:
        l_layer = Gtk.Label(label=card_data["layer"])
        l_layer.get_style_context().add_class("layer")
        l_layer.set_xalign(0.0)
        box.pack_start(l_layer, False, False, 0)

    for step in card_data.get("steps", []):
        l_step = Gtk.Label(label=step)
        l_step.get_style_context().add_class("step")
        l_step.set_xalign(0.0)
        box.pack_start(l_step, False, False, 0)

    footer_text = card_data.get("footer", "⚡ [Ліва + Середня педаль: Закрити]")
    l_footer = Gtk.Label(label=footer_text)
    l_footer.get_style_context().add_class("footer")
    l_footer.set_xalign(0.0)
    box.pack_start(l_footer, False, False, 0)

    win.add(box)
    win.show_all()

    def on_sigterm(signum, frame):
        cleanup()
        Gtk.main_quit()

    signal.signal(signal.SIGTERM, on_sigterm)
    signal.signal(signal.SIGINT, on_sigterm)

    def on_timeout():
        cleanup()
        Gtk.main_quit()
        return False

    GLib.timeout_add(int(duration_sec * 1000), on_timeout)
    try:
        Gtk.main()
    finally:
        cleanup()

if __name__ == "__main__":
    # If called with --toggle, close if already running, otherwise open
    if "--toggle" in sys.argv:
        if toggle_check():
            sys.exit(0)
    
    dur = 8.0
    for arg in sys.argv:
        if arg.startswith("--dur="):
            try:
                dur = float(arg.split("=")[1])
            except ValueError:
                pass

    display_hud_card(duration_sec=dur)
