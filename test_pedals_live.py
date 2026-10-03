#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Visual Real-Time Pedal Tester with Physical Letters Display
Shows live status of Left, Middle, and Right pedals, displaying:
  1. The exact raw letter/key hardware-programmed into the pedal
  2. The Fallout 4 mapped action (Sprint / Jetpack / Crouch)
  3. Live real-time press/release events
"""

import os
import sys
import json
import glob
import fcntl
import struct
import select
import time
import subprocess
import re

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(STAND_DIR, "footpad_config.json")

KERNEL_CHAR_MAP = {
    16: "q / й",
    17: "w / ц",
    18: "e / у",
    19: "r / к",
    20: "t / е",
    21: "y / н",
    22: "u / г",
    23: "i / ш",
    24: "o / щ",
    25: "p / з",
    30: "a / ф",
    31: "s / і",
    32: "d / в",
    33: "f / а",
    34: "g / п",
    35: "h / р",
    36: "j / о",
    37: "k / л",
    38: "l / д",
    42: "Shift_L",
    44: "z / я",
    45: "x / ч",
    46: "c / с",
    47: "v / м",
    48: "b / и",
    49: "n / т",
    50: "m / ь",
    57: "Space",
    29: "Ctrl_L",
}

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "left":   {"scancode": 16, "name": "q",       "action": "sprint",       "desc": "Біг / Спринт"},
        "middle": {"scancode": 33, "name": "f",       "action": "jump_jetpack", "desc": "Стрибок / Джетпак"},
        "right":  {"scancode": 42, "name": "Shift_L", "action": "crouch",       "desc": "Присісти / Скритність"},
    }

def find_footswitch():
    by_id = "/dev/input/by-id/usb-PCsensor_FootSwitch-event-kbd"
    if os.path.exists(by_id):
        return os.path.realpath(by_id)
    for p in sorted(glob.glob("/dev/input/event*")):
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(b'\0')[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "PCsensor" in name and "Keyboard" in name:
                return p
        except Exception:
            pass
    return None

def render_ui(states, cfg, event_log):
    l_sc = cfg.get("left", {}).get("scancode", 42)
    m_sc = cfg.get("middle", {}).get("scancode", 33)
    r_sc = cfg.get("right", {}).get("scancode", 16)

    l_char = f"'{KERNEL_CHAR_MAP.get(l_sc, str(l_sc))}'"
    m_char = f"'{KERNEL_CHAR_MAP.get(m_sc, str(m_sc))}'"
    r_char = f"'{KERNEL_CHAR_MAP.get(r_sc, str(r_sc))}'"

    l_box = "\033[1;32m [ >>> НАТИСНУТО <<< ] \033[0m" if states["left"] else "      [ ВІДПУЩЕНО ]     "
    m_box = "\033[1;32m [ >>> НАТИСНУТО <<< ] \033[0m" if states["middle"] else "      [ ВІДПУЩЕНО ]     "
    r_box = "\033[1;32m [ >>> НАТИСНУТО <<< ] \033[0m" if states["right"] else "      [ ВІДПУЩЕНО ]     "

    print("\033[H\033[J", end="") # Clear terminal
    print("=========================================================================================")
    print("        ВІДОБРАЖЕННЯ ЛІТЕР ТА ЖИВИЙ ТЕСТЕР ПЕДАЛЕЙ FOOTSWITCH (FALLOUT 4 STAND)          ")
    print("=========================================================================================")
    print("┌──────────────────────────────┬──────────────────────────────┬─────────────────────────┐")
    print("│         ЛІВА ПЕДАЛЬ          │        СЕРЕДНЯ ПЕДАЛЬ        │       ПРАВА ПЕДАЛЬ      │")
    print(f"│  🔤 Фіз. літера: {l_char:<12}│  🔤 Фіз. літера: {m_char:<12}│  🔤 Фіз. літера: {r_char:<7}│")
    print("├──────────────────────────────┼──────────────────────────────┼─────────────────────────┤")
    print("│  🎮 Дія: БІГ / СПРИНТ        │  🎮 Дія: СТРИБОК / ДЖЕТПАК   │  🎮 Дія: ПРИСІСТИ       │")
    print("│     (DualShock L3 + Shift)   │     (DualShock ▲ + Space)    │     (DualShock ● + Ctrl)│")
    print("├──────────────────────────────┼──────────────────────────────┼─────────────────────────┤")
    print(f"│{l_box}│{m_box}│{r_box}│")
    print("└──────────────────────────────┴──────────────────────────────┴─────────────────────────┘")
    print("\n📜 ЖУРНАЛ ОСТАННІХ ПОДІЙ (Фіксація літер у реальному часі):")
    print("-----------------------------------------------------------------------------------------")
    if not event_log:
        print(" [Очікую натискання педалей ногою... Натисніть будь-яку педаль]")
    else:
        for ev in event_log[-6:]:
            print(f" {ev}")
    print("-----------------------------------------------------------------------------------------")
    print("Підказка: Натискайте педалі для перевірки. Натисніть Ctrl+C для виходу.\n")

def main():
    dev_path = find_footswitch()
    if not dev_path:
        print("ПОМИЛКА: PCsensor FootSwitch не знайдено!")
        sys.exit(1)

    cfg = load_config()
    sc_map = {}
    for pos in ["left", "middle", "right"]:
        sc = cfg.get(pos, {}).get("scancode")
        if sc:
            sc_map[sc] = pos

    fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)
    states = {"left": False, "middle": False, "right": False}
    event_log = []

    render_ui(states, cfg, event_log)

    try:
        while True:
            r, _, _ = select.select([fd], [], [], 0.2)
            if fd in r:
                data = os.read(fd, 24 * 16)
                changed = False
                for i in range(0, len(data), 24):
                    sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                    if ev_type == 1 and val in (0, 1):
                        pos = sc_map.get(code)
                        is_pressed = (val == 1)
                        char_name = KERNEL_CHAR_MAP.get(code, f"Key_{code}")
                        t_str = time.strftime('%H:%M:%S')

                        if is_pressed:
                            ev_text = f"[{t_str}] 🦶 НА ТИСК:  Педаль '{pos.upper() if pos else 'НЕВІДОМА'}' ──> Літера: '{char_name}' (код {code})"
                        else:
                            ev_text = f"[{t_str}] 🦶 ВІДПУСК: Педаль '{pos.upper() if pos else 'НЕВІДОМА'}' ──> Літера: '{char_name}'"

                        event_log.append(ev_text)
                        if pos and states[pos] != is_pressed:
                            states[pos] = is_pressed
                        changed = True

                if changed:
                    render_ui(states, cfg, event_log)
    except KeyboardInterrupt:
        print("\nТестування завершено.")
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
