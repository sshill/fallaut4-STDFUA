#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FootSwitch Interactive Calibration Tool
Walks the user through pressing Left, Middle, and Right pedals and saves footpad_config.json
"""

import os
import sys
import json
import glob
import fcntl
import struct
import select
import time

CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "footpad_config.json")

KEY_NAMES = {
    16: "KEY_Q",
    33: "KEY_F",
    42: "KEY_LEFTSHIFT",
    57: "KEY_SPACE",
    29: "KEY_LEFTCTRL",
    46: "KEY_C",
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

def wait_for_pedal(fd, step_name):
    print(f"\n>>> {step_name}")
    print("    Очікую натискання педалі...")
    
    pressed_code = None
    while True:
        r, _, _ = select.select([fd], [], [], 0.5)
        if fd in r:
            data = os.read(fd, 24 * 16)
            for i in range(0, len(data), 24):
                sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                if ev_type == 1: # EV_KEY
                    if val == 1 and pressed_code is None:
                        pressed_code = code
                        kname = KEY_NAMES.get(code, f"KEY_{code}")
                        print(f"    [OK] Зафіксовано натискання: сканкод {code} ({kname})")
                    elif val == 0 and pressed_code == code:
                        print("    [OK] Педаль відпущено.\n")
                        return pressed_code

def main():
    dev_path = find_footswitch()
    if not dev_path:
        print("ПОМИЛКА: PCsensor FootSwitch не знайдено!")
        sys.exit(1)
    
    print(f"Пристрій FootSwitch підключено: {dev_path}")
    print("==================================================================")
    print(" ПОЧАТОК КАЛІБРУВАННЯ ТРЬОХ НОЖНИХ ПЕДАЛЕЙ ДЛЯ FALLOUT 4")
    print("==================================================================")
    
    fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)
    
    try:
        # Step 1: Left Pedal
        left_code = wait_for_pedal(fd, "КРОК 1: Натисніть ЛІВУ педаль (призначення: БІГ / СПРИНТ)")
        
        # Step 2: Middle Pedal
        middle_code = wait_for_pedal(fd, "КРОК 2: Натисніть СЕРЕДНЮ педаль (призначення: СТРИБОК / ДЖЕТПАК)")
        
        # Step 3: Right Pedal
        right_code = wait_for_pedal(fd, "КРОК 3: Натисніть ПРАВУ педаль (призначення: ПРИСІСТИ / СКРИТНІСТЬ)")
        
        config = {
            "left": {
                "scancode": left_code,
                "name": KEY_NAMES.get(left_code, f"KEY_{left_code}"),
                "action": "sprint",
                "desc": "Біг / Спринт",
                "keyboard_key": 42,   # KEY_LEFTSHIFT
                "gamepad_btn": 317    # BTN_THUMBL (L3)
            },
            "middle": {
                "scancode": middle_code,
                "name": KEY_NAMES.get(middle_code, f"KEY_{middle_code}"),
                "action": "jump_jetpack",
                "desc": "Стрибок / Джетпак",
                "keyboard_key": 57,   # KEY_SPACE
                "gamepad_btn": 307    # BTN_NORTH (Triangle / Y)
            },
            "right": {
                "scancode": right_code,
                "name": KEY_NAMES.get(right_code, f"KEY_{right_code}"),
                "action": "crouch",
                "desc": "Присісти / Скритність",
                "keyboard_key": 29,   # KEY_LEFTCTRL
                "gamepad_btn": 305    # BTN_EAST (Circle / B)
            }
        }
        
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
            
        print("==================================================================")
        print(f"Калібрування завершено успішно! Конфігурацію збережено в:\n{CONFIG_PATH}")
        print("==================================================================")
        print(json.dumps(config, indent=2, ensure_ascii=False))
        
    except KeyboardInterrupt:
        print("\nКалібрування перервано користувачем.")
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
