#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FootSwitch Live Diagnostic & Test Tool
Tests /dev/input/by-id/usb-PCsensor_FootSwitch-event-kbd
"""

import os
import sys
import glob
import fcntl
import struct
import select
import time

def find_footswitch():
    by_id = "/dev/input/by-id/usb-PCsensor_FootSwitch-event-kbd"
    if os.path.exists(by_id):
        return os.path.realpath(by_id)
    
    for p in sorted(glob.glob("/dev/input/event*")):
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf) # EVIOCGNAME(256)
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
        print("ПОМИЛКА: PCsensor FootSwitch не знайдено!")
        sys.exit(1)
    
    print(f"Знайдено FootSwitch: {dev_path}")
    fd = os.open(dev_path, os.O_RDONLY | os.O_NONBLOCK)
    
    print("Натискайте педалі для перевірки (Ctrl+C для виходу)...")
    try:
        while True:
            r, _, _ = select.select([fd], [], [], 1.0)
            if fd in r:
                data = os.read(fd, 24 * 16)
                for i in range(0, len(data), 24):
                    sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                    if ev_type == 1: # EV_KEY
                        state = "НАТИСНУТО" if val == 1 else ("ВІДПУЩЕНО" if val == 0 else "ПОВТОР")
                        print(f"[{time.strftime('%H:%M:%S')}] Сканкод {code:3d} | Стан: {state}")
    except KeyboardInterrupt:
        pass
    finally:
        os.close(fd)

if __name__ == "__main__":
    main()
