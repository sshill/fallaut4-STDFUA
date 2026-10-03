#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Відображення фізичних літер та кодів USB-педалей PCsensor FootSwitch
=============================================================================
Показує точну літеру (латинську/кириличну), сканкод та X11 символ,
який апаратно зашито в контролер кожної педалі.
"""

import os
import sys
import glob
import fcntl
import struct
import select
import time
import subprocess
import re

def get_system_keymap():
    try:
        out = subprocess.check_output(['xmodmap', '-pke'], stderr=subprocess.DEVNULL).decode()
        km = {}
        for line in out.splitlines():
            m = re.match(r'keycode\s+(\d+)\s*=\s*(.*)', line)
            if m:
                kc = int(m.group(1))
                syms = [s for s in m.group(2).split() if s != 'NoSymbol']
                km[kc] = syms
        return km
    except Exception:
        return {}

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

def main():
    dev_path = find_footswitch()
    if not dev_path:
        print("\n❌ ПОМИЛКА: PCsensor FootSwitch не підключено або не знайдено!")
        sys.exit(1)

    keymap = get_system_keymap()
    
    # Standard kernel-to-char fallback table
    KERNEL_CHAR_MAP = {
        16: ('q', 'Q', 'й', 'Й'),
        17: ('w', 'W', 'ц', 'Ц'),
        18: ('e', 'E', 'у', 'У'),
        19: ('r', 'R', 'к', 'К'),
        20: ('t', 'T', 'е', 'Е'),
        21: ('y', 'Y', 'н', 'Н'),
        22: ('u', 'U', 'г', 'Г'),
        23: ('i', 'I', 'ш', 'Ш'),
        24: ('o', 'O', 'щ', 'Щ'),
        25: ('p', 'P', 'з', 'З'),
        30: ('a', 'A', 'ф', 'Ф'),
        31: ('s', 'S', 'і', 'І'),
        32: ('d', 'D', 'в', 'В'),
        33: ('f', 'F', 'а', 'А'),
        34: ('g', 'G', 'п', 'П'),
        35: ('h', 'H', 'р', 'Р'),
        36: ('j', 'J', 'о', 'О'),
        37: ('k', 'K', 'л', 'Л'),
        38: ('l', 'L', 'д', 'Д'),
        42: ('Shift_L', 'Shift_L', 'Лівий Shift', 'Лівий Shift'),
        44: ('z', 'Z', 'я', 'Я'),
        45: ('x', 'X', 'ч', 'Ч'),
        46: ('c', 'C', 'с', 'С'),
        47: ('v', 'V', 'м', 'М'),
        48: ('b', 'B', 'и', 'И'),
        49: ('n', 'N', 'т', 'Т'),
        50: ('m', 'M', 'ь', 'Ь'),
        57: ('Space', 'Space', 'Пробіл', 'Пробіл'),
        29: ('Ctrl_L', 'Ctrl_L', 'Лівий Ctrl', 'Лівий Ctrl'),
    }

    fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)

    print("=======================================================================================")
    print("      ДІАГНОСТИКА СИРИХ ЛІТЕР ТА СИМВОЛІВ ФУТПАДА (PCSENSOR FOOTSWITCH)")
    print("=======================================================================================")
    print(f" Пристрій вводу: {dev_path}")
    print(" Натискайте будь-яку педаль — нижче відобразиться ТОЧНА ЛІТЕРА, яку вона посилає.")
    print(" (Для виходу натисніть Ctrl+C у цьому вікні)")
    print("---------------------------------------------------------------------------------------\n")

    try:
        while True:
            r, _, _ = select.select([fd], [], [], 0.5)
            if fd in r:
                data = os.read(fd, 24 * 16)
                for i in range(0, len(data), 24):
                    sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                    if ev_type == 1: # EV_KEY
                        x11_code = code + 8
                        syms = keymap.get(x11_code, [])
                        primary_sym = syms[0] if syms else f"Key_{code}"
                        
                        char_info = KERNEL_CHAR_MAP.get(code)
                        if char_info:
                            lat_char = char_info[0]
                            cyr_char = char_info[2]
                        else:
                            lat_char = primary_sym
                            cyr_char = "-"

                        t_str = time.strftime('%H:%M:%S')

                        if val == 1:
                            print(f"[{t_str}] 🦶 ПЕДАЛЬ НАТИСНУТО:")
                            print(f"       ├── 🔤 Фізична літера:     '{lat_char}' (кирилиця: '{cyr_char}')")
                            print(f"       ├── ⌨️  X11 символ:         {primary_sym} (код: {x11_code})")
                            print(f"       └── ⚙️  Kernel сканкод:     {code}")
                            print("---------------------------------------------------------------------------------------")
                        elif val == 0:
                            print(f"[{t_str}] 🦶 ПЕДАЛЬ ВІДПУЩЕНО:       '{lat_char}'")
                            print("---------------------------------------------------------------------------------------")

    except KeyboardInterrupt:
        print("\n\nДіагностику літер завершено.")
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
