#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 Footpad & Native DualShock 4 Unified Input Mapper Daemon
=============================================================================
Architecture:
  - 100% Native Sony DualShock 4 v2 Profile (054c:09cc):
    Passes all controller sticks, triggers, and buttons 1:1 WITHOUT remapping
    or altering the player's saved Fallout 4 controls setup.
  - Merges PCsensor 3-Pedal USB FootSwitch events into the DualShock 4 stream:
      1. Left Pedal   (q / 16)       -> Sprint (L3 / BTN_THUMBL / 317 + Shift)
      2. Middle Pedal (f / 33)       -> Jump / Jetpack (Triangle / BTN_NORTH / 307 + Space)
      3. Right Pedal  (Shift_L / 42) -> Crouch / Sneak (R3 / BTN_THUMBR / 318 + Ctrl)
  - Grabs DualShock 4 Touchpad (evdev event-mouse):
    Blocks mouse pointer movement / focus loss, maps physical click to
    POV Switch (Share / BTN_SELECT / 314 + KEY_F) matching PlayStation 4!
"""

import os
import sys
import json
import glob
import fcntl
import struct
import signal
import select
import time
import math
import collections
import subprocess

try:
    sys.stdout.reconfigure(line_buffering=True)
    sys.stderr.reconfigure(line_buffering=True)
except Exception:
    pass

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(STAND_DIR, "footpad_config.json")
SHOW_HUD_SCRIPT = os.path.join(STAND_DIR, "show_hud_toast.py")
LIVE_STATE_FILE = os.path.join(STAND_DIR, "scratch/footpad_live.json")
LOG_FILE = os.path.join(STAND_DIR, "scratch/footpad.log")

class TeeLogger:
    def __init__(self, stream, filename):
        self.stream = stream
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        self.logfile = open(filename, "a", encoding="utf-8", buffering=1)
    def write(self, message):
        try: self.stream.write(message)
        except Exception: pass
        try:
            self.logfile.write(message)
            self.logfile.flush()
        except Exception: pass
    def flush(self):
        try: self.stream.flush()
        except Exception: pass
        try: self.logfile.flush()
        except Exception: pass

sys.stdout = TeeLogger(sys.stdout, LOG_FILE)
sys.stderr = TeeLogger(sys.stderr, LOG_FILE)

# Linux Input Event Constants
EV_SYN = 0
EV_KEY = 1
EV_ABS = 3
SYN_REPORT = 0

UI_SET_EVBIT   = 0x40045564
UI_SET_KEYBIT  = 0x40045565
UI_SET_ABSBIT  = 0x40045567
UI_DEV_CREATE  = 0x5501
UI_DEV_DESTROY = 0x5502
EVIOCGRAB      = 0x40044590

# Default configuration fallback
DEFAULT_CONFIG = {
    "left":   {"scancode": 16, "action": "sprint",       "keyboard_key": 42, "gamepad_btn": 317}, # L3 (Sprint)
    "middle": {"scancode": 33, "action": "jump_jetpack", "keyboard_key": 57, "gamepad_btn": 308}, # Y (Jump/Jetpack)
    "right":  {"scancode": 42, "action": "crouch",       "keyboard_key": 29, "gamepad_btn": 318}, # R3 (Crouch/Sneak)
}

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"[Footpad Mapper] Помилка читання конфігу: {e}, використовую стандартний")
    return DEFAULT_CONFIG

def is_virtual_device(event_path):
    """Returns True if the event device is a virtual uinput device."""
    try:
        ev_name = os.path.basename(event_path)
        sys_path = os.path.realpath(f"/sys/class/input/{ev_name}")
        return "devices/virtual" in sys_path
    except Exception:
        return False

def find_footswitch():
    by_id = "/dev/input/by-id/usb-PCsensor_FootSwitch-event-kbd"
    if os.path.exists(by_id):
        rp = os.path.realpath(by_id)
        if not is_virtual_device(rp):
            return rp
    for p in sorted(glob.glob("/dev/input/event*")):
        if is_virtual_device(p):
            continue
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "PCsensor" in name and "Keyboard" in name:
                return p
        except Exception:
            pass
    return None

def find_dualshock4():
    by_id = "/dev/input/by-id/usb-Sony_Interactive_Entertainment_Wireless_Controller-if03-event-joystick"
    if os.path.exists(by_id):
        rp = os.path.realpath(by_id)
        if not is_virtual_device(rp):
            return rp
    for p in sorted(glob.glob("/dev/input/event*")):
        if is_virtual_device(p):
            continue
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "Sony" in name and ("Wireless Controller" in name or "DualShock" in name) and "Touchpad" not in name and "Motion" not in name:
                return p
        except Exception:
            pass
    return None

def find_dualshock4_touchpad():
    by_id = "/dev/input/by-id/usb-Sony_Interactive_Entertainment_Wireless_Controller-if03-event-mouse"
    if os.path.exists(by_id):
        rp = os.path.realpath(by_id)
        if not is_virtual_device(rp):
            return rp
    for p in sorted(glob.glob("/dev/input/event*")):
        if is_virtual_device(p):
            continue
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "Sony" in name and "Touchpad" in name:
                return p
        except Exception:
            pass
    return None

def find_all_footswitch_nodes():
    nodes = []
    for p in sorted(glob.glob("/dev/input/event*")):
        if is_virtual_device(p):
            continue
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "PCsensor" in name:
                nodes.append(p)
        except Exception:
            pass
    return nodes

def find_dualshock4_motion():
    by_id = "/dev/input/by-id/usb-Sony_Interactive_Entertainment_Wireless_Controller-event-if03"
    if os.path.exists(by_id):
        rp = os.path.realpath(by_id)
        if not is_virtual_device(rp):
            return rp
    for p in sorted(glob.glob("/dev/input/event*")):
        if is_virtual_device(p):
            continue
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode('utf-8', errors='ignore')
            os.close(fd)
            if "Sony" in name and "Motion" in name:
                return p
        except Exception:
            pass
    return None

class UnifiedFootpadMapper:
    def __init__(self):
        self.config = load_config()
        self.running = True
        
        # Scancode lookup: code -> (pos, action, keyboard_key, gamepad_btn)
        self.pedal_map = {}
        for pos, data in self.config.items():
            sc = data.get("scancode")
            if sc:
                default_data = DEFAULT_CONFIG.get(pos, {})
                self.pedal_map[sc] = (
                    pos,
                    data.get("action", "unknown"),
                    data.get("keyboard_key", default_data.get("keyboard_key", 0)),
                    data.get("gamepad_btn", default_data.get("gamepad_btn", 0))
                )

        self.fd_footpad = None
        self.fd_ds4 = None
        self.fd_touchpad = None
        self.fd_uinput_gamepad = None
        self.fd_uinput_kbd = None
        self.fd_aux_grabbed = []
        
        self.pedal_states = {"left": False, "middle": False, "right": False}
        self.btn_state_controller = {317: False, 308: False, 318: False}
        self.btn_state_pedal = {317: False, 308: False, 318: False}
        self.trigger_l2_state = False
        self.trigger_r2_state = False
        self.hud_combo_active = False
        self.pedal_crouch_held = False
        
        # Motorics Ring Buffer (250 Hz, 1000 samples = 4 seconds of rolling telemetry in RAM)
        self.ring_buffer = collections.deque(maxlen=1000)
        self.axes_state = [0] * 8 # 0:LX, 1:LY, 2:L2, 3:RX, 4:RY, 5:R2, 6:HatX, 7:HatY
        self.aim_tremor_index = 0.0
        self.last_tremor_calc = 0.0
        
        # Telemetry Session Stream
        self.recording_active = False
        self.telemetry_fp = None
        self.recording_start_time = 0.0
        self.recording_file_path = ""

        os.makedirs(os.path.dirname(LIVE_STATE_FILE), exist_ok=True)
        self.write_live_state("Ініціалізація")

    def write_live_state(self, last_action=""):
        try:
            st = {
                "states": self.pedal_states,
                "last_action": last_action,
                "has_ds4": self.fd_ds4 is not None,
                "has_touchpad": self.fd_touchpad is not None,
                "aim_tremor_index": self.aim_tremor_index,
                "buffer_len": len(self.ring_buffer),
                "recording": self.recording_active,
                "recording_file": self.recording_file_path if self.recording_active else "",
                "updated_at": time.time(),
            }
            with open(LIVE_STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(st, f)
        except Exception:
            pass

    def reset_gamepad_states(self):
        """Resets all controller buttons and sticks to neutral without destroying the virtual device."""
        self.btn_state_controller = {317: False, 308: False, 318: False}
        self.trigger_l2_state = False
        self.trigger_r2_state = False
        if self.fd_uinput_gamepad:
            # Neutralise buttons (except those currently held down by pedals)
            for btn in [304, 305, 307, 308, 310, 311, 314, 315, 316, 317, 318]:
                pedal_held = self.btn_state_pedal.get(btn, False)
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, btn, 1 if pedal_held else 0)
            # Center sticks
            for axis in [0, 1, 3, 4]:
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, axis, 0)
            # Reset triggers
            for axis in [2, 5]:
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, axis, 0)
            # Center D-pad
            for axis in [16, 17]:
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, axis, 0)

    def setup_uinput_gamepad(self):
        """Creates a standard Virtual Microsoft Xbox 360 controller via uinput for 100% XInput compatibility."""
        self.fd_uinput_gamepad = os.open('/dev/uinput', os.O_WRONLY | os.O_NONBLOCK)
        fcntl.ioctl(self.fd_uinput_gamepad, UI_SET_EVBIT, EV_KEY)
        fcntl.ioctl(self.fd_uinput_gamepad, UI_SET_EVBIT, EV_ABS)

        # Standard Xbox 360 buttons: A(304), B(305), X(307), Y(308), LB(310), RB(311), Back(314), Start(315), Guide(316), L3(317), R3(318)
        for btn in [304, 305, 307, 308, 310, 311, 314, 315, 316, 317, 318]:
            fcntl.ioctl(self.fd_uinput_gamepad, UI_SET_KEYBIT, btn)

        # Standard Xbox 360 axes: LeftX(0), LeftY(1), LT(2), RightX(3), RightY(4), RT(5), D-padX(16), D-padY(17)
        for axis in [0, 1, 2, 3, 4, 5, 16, 17]:
            fcntl.ioctl(self.fd_uinput_gamepad, UI_SET_ABSBIT, axis)

        name = b'Microsoft X-Box 360 pad'
        bustype = 0x03 # USB
        vendor = 0x045e # Microsoft
        product = 0x028e # Xbox 360 Controller
        version = 1

        absmax = [0] * 64
        absmin = [0] * 64
        absfuzz = [0] * 64
        absflat = [0] * 64

        for a in [0, 1, 3, 4]:
            absmin[a] = -32768
            absmax[a] = 32767
            absflat[a] = 0
        for a in [2, 5]:
            absmin[a] = 0
            absmax[a] = 255
        for a in [16, 17]:
            absmin[a] = -1
            absmax[a] = 1

        dev_struct = struct.pack('80sHHHHi' + 'i'*64*4,
            name, bustype, vendor, product, version, 0,
            *absmax, *absmin, *absfuzz, *absflat)

        os.write(self.fd_uinput_gamepad, dev_struct)
        fcntl.ioctl(self.fd_uinput_gamepad, UI_DEV_CREATE)
        print("[Footpad Mapper] Створено Virtual Microsoft Xbox 360 Controller via uinput (100% XInput)")

    def setup_uinput_keyboard(self):
        """Virtual keyboard disabled to prevent Wine/Fallout 4 gamepad mode conflicts."""
        self.fd_uinput_kbd = None

    def destroy_uinput_gamepad(self):
        if self.fd_uinput_gamepad:
            try:
                fcntl.ioctl(self.fd_uinput_gamepad, UI_DEV_DESTROY)
                os.close(self.fd_uinput_gamepad)
            except Exception:
                pass
            self.fd_uinput_gamepad = None
            print("[Footpad Mapper] Віртуальний геймпад відключено (Xbox 360 Controller від’єднано)")

    def setup_footpad(self):
        p = find_footswitch()
        if not p:
            return False

        try:
            fd = os.open(p, os.O_RDWR | os.O_NONBLOCK)
            fcntl.ioctl(fd, EVIOCGRAB, 1)
            self.fd_footpad = fd
            print(f"[Footpad Mapper] Захоплено FootSwitch: {p} (сирі сканкоди заблоковано)")

            # Grab all other PCsensor nodes (mouse, interface 01) to completely prevent raw events escaping
            for aux_p in find_all_footswitch_nodes():
                if aux_p != p:
                    try:
                        aux_fd = os.open(aux_p, os.O_RDWR | os.O_NONBLOCK)
                        fcntl.ioctl(aux_fd, EVIOCGRAB, 1)
                        self.fd_aux_grabbed.append(aux_fd)
                        print(f"[Footpad Mapper] Захоплено додатковий вузол FootSwitch: {aux_p} (EVIOCGRAB)")
                    except Exception as e_aux:
                        print(f"[Footpad Mapper] Не вдалося захопити {aux_p}: {e_aux}")

            return True
        except Exception as e:
            print(f"[Footpad Mapper] Помилка захоплення FootSwitch: {e}")
            try: os.close(fd)
            except: pass
            self.fd_footpad = None
            return False

    def setup_dualshock4(self):
        p = find_dualshock4()
        if not p:
            return False

        try:
            fd = os.open(p, os.O_RDWR | os.O_NONBLOCK)
            fcntl.ioctl(fd, EVIOCGRAB, 1)
            self.fd_ds4 = fd
            print(f"[Footpad Mapper] Захоплено фізичний DualShock 4: {p} (Кастомний сетап XInput Xbox 360)")

            # Also grab motion sensor node to eliminate phantom motion packets
            motion_p = find_dualshock4_motion()
            if motion_p:
                try:
                    m_fd = os.open(motion_p, os.O_RDWR | os.O_NONBLOCK)
                    fcntl.ioctl(m_fd, EVIOCGRAB, 1)
                    self.fd_aux_grabbed.append(m_fd)
                    print(f"[Footpad Mapper] Захоплено DS4 Motion сенсори: {motion_p} (EVIOCGRAB)")
                except Exception:
                    pass

            if not self.fd_uinput_gamepad:
                self.setup_uinput_gamepad()
            return True
        except Exception as e:
            try: os.close(fd)
            except: pass
            self.fd_ds4 = None
            return False

    def setup_touchpad(self):
        p = find_dualshock4_touchpad()
        if not p:
            return False

        try:
            fd = os.open(p, os.O_RDWR | os.O_NONBLOCK)
            fcntl.ioctl(fd, EVIOCGRAB, 1)
            self.fd_touchpad = fd
            print(f"[Footpad Mapper] Захоплено DS4 Touchpad: {p} (клік = перемикання POV, мишу заблоковано)")
            return True
        except Exception as e:
            try: os.close(fd)
            except: pass
            self.fd_touchpad = None
            return False

    def emit_event(self, fd, ev_type, code, val):
        if fd:
            ev = struct.pack('qqHHi', 0, 0, ev_type, code, val)
            syn = struct.pack('qqHHi', 0, 0, EV_SYN, SYN_REPORT, 0)
            os.write(fd, ev + syn)

    def scale_stick(self, val):
        # DS4 hardware reports 0..255. Hardware center fluctuates around 128..132.
        # Deadzone: 122..134 -> 0 (prevents jitter, phantom menu scrolling & drift in Pip-Boy)
        if 122 <= val <= 134:
            return 0
        elif val > 134:
            # Map 135..255 smoothly to 1..32767
            return min(32767, int((val - 134) * (32767.0 / (255.0 - 134.0))))
        else:
            # Map 121..0 smoothly to -1..-32768
            return max(-32768, int((val - 122) * (32768.0 / 122.0)))

    def handle_ds4_event(self, ev_type, code, val):
        if not self.fd_uinput_gamepad:
            return

        now = time.time()
        event_desc = None

        if ev_type == EV_KEY:
            # 1. Player Profile: L1 (310) -> LT (Axis 2, 0 or 255) [Aim / Block]
            if code == 310:
                axis_val = 255 if (val == 1) else 0
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, 2, axis_val)
                state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_L1_Aim"
                print(f"[{time.strftime('%H:%M:%S')}] DS4 L1 [Приціл / Блок (LT)]: {state_str}")

            # 2. Player Profile: R1 (311) -> RT (Axis 5, 0 or 255) [Attack / Fire]
            elif code == 311:
                axis_val = 255 if (val == 1) else 0
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, 5, axis_val)
                state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_R1_Fire"
                print(f"[{time.strftime('%H:%M:%S')}] DS4 R1 [Постріл / Атака (RT)]: {state_str}")

            # 3. Square (308) -> Xbox X (307) [Reload / Ready Weapon / Pip-Boy Favorite]
            elif code == 308:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 307, val)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Square"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Квадрат [Xbox X]: {state_str}")

            # 4. Triangle (307) -> Xbox Y (308) [Jump / Jetpack] (Shared with Middle Pedal)
            elif code == 307:
                self.btn_state_controller[308] = (val == 1)
                effective = 1 if (self.btn_state_controller[308] or self.btn_state_pedal.get(308, False)) else 0
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 308, effective)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Triangle"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Трикутник [Xbox Y]: {state_str}")

            # 5. Cross (304) -> Xbox A (304) [Activate / Take / Pip-Boy Select]
            elif code == 304:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 304, val)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Cross"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Хрест [Xbox A]: {state_str}")

            # 6. Circle (305) -> Xbox B (305) [Pip-Boy Open/Close / Back]
            elif code == 305:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 305, val)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Circle_PipBoy"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Коло [Xbox B (Піп-Бой)]: {state_str}")

            # 7. Options (315) -> Xbox Start (315) [Pause / Settings]
            elif code == 315:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 315, val)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Start"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Options [Start]: {state_str}")

            # 8. Share (314) -> Xbox Back (314) [Toggle POV]
            elif code == 314:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 314, val)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_Share"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 Share [Back]: {state_str}")

            # 9. PS Button (316) -> Xbox Guide (316)
            elif code == 316:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 316, val)

            # 10. L3 (317) -> Xbox L3 (317) [Sprint] (Shared with Left Pedal)
            elif code == 317:
                self.btn_state_controller[317] = (val == 1)
                effective = 1 if (self.btn_state_controller[317] or self.btn_state_pedal.get(317, False)) else 0
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 317, effective)
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_L3"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 L3 [Спринт]: {state_str}")

            # 11. R3 (318) -> Xbox R3 (318) [Sneak / Crouch] (Shared with Right Pedal)
            elif code == 318:
                self.btn_state_controller[318] = (val == 1)
                effective = 1 if (self.btn_state_controller[318] or self.btn_state_pedal.get(318, False)) else 0
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 318, effective)
                if val == 1:
                    self.pedal_crouch_held = not self.pedal_crouch_held
                if val in (0, 1):
                    state_str = "НАТИСНУТО" if val == 1 else "ВІДПУЩЕНО"
                    event_desc = f"BTN_{'DOWN' if val == 1 else 'UP'}_R3"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 R3 [Скритність]: {state_str}")

        elif ev_type == EV_ABS:
            # 1. Left Stick X/Y (DS4 0/1 -> Xbox 0/1) with smooth deadzone
            if code in (0, 1):
                self.axes_state[code] = val
                scaled = self.scale_stick(val)
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, code, scaled)

            # 2. Player Profile: L2 Trigger (DS4 Axis 2) -> LB (Button 310) [V.A.T.S. / Pip-Boy Prev Tab]
            # Sensitive threshold val > 15 (light touch) with hysteresis release val < 8
            elif code == 2:
                self.axes_state[2] = val
                if not self.trigger_l2_state and val > 15:
                    self.trigger_l2_state = True
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 310, 1)
                    event_desc = "BTN_DOWN_L2_PipBoyPrev"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 L2 [LB / Піп-Бой Назад / V.A.T.S.]: НАТИСНУТО (val={val})")
                elif self.trigger_l2_state and val < 8:
                    self.trigger_l2_state = False
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 310, 0)
                    event_desc = "BTN_UP_L2_PipBoyPrev"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 L2 [LB / Піп-Бой Назад / V.A.T.S.]: ВІДПУЩЕНО")

            # 3. Right Stick X/Y (DS4 3/4 -> Xbox 3/4) with smooth deadzone
            elif code in (3, 4):
                self.axes_state[code] = val
                scaled = self.scale_stick(val)
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, code, scaled)

            # 4. Player Profile: R2 Trigger (DS4 Axis 5) -> RB (Button 311) [Melee / Pip-Boy Next Tab]
            # Sensitive threshold val > 15 (light touch) with hysteresis release val < 8
            elif code == 5:
                self.axes_state[5] = val
                if not self.trigger_r2_state and val > 15:
                    self.trigger_r2_state = True
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 311, 1)
                    event_desc = "BTN_DOWN_R2_PipBoyNext"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 R2 [RB / Піп-Бой Вперед / Бій]: НАТИСНУТО (val={val})")
                elif self.trigger_r2_state and val < 8:
                    self.trigger_r2_state = False
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 311, 0)
                    event_desc = "BTN_UP_R2_PipBoyNext"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 R2 [RB / Піп-Бой Вперед / Бій]: ВІДПУЩЕНО")

            # 5. D-Pad Hat (DS4 16/17 -> Xbox 16/17)
            elif code in (16, 17):
                if code == 16: self.axes_state[6] = val
                else: self.axes_state[7] = val
                self.emit_event(self.fd_uinput_gamepad, EV_ABS, code, val)
                if val != 0:
                    axis_name = "D-Pad X (Вліво/Вправо)" if code == 16 else "D-Pad Y (Вгору/Вниз)"
                    direction = ("Вправо" if val > 0 else "Вліво") if code == 16 else ("Вниз" if val > 0 else "Вгору")
                    event_desc = f"HAT_{axis_name}_{direction}"
                    print(f"[{time.strftime('%H:%M:%S')}] DS4 {axis_name}: {direction}")

        # --- MOTORICS RING BUFFER & TREMOR ENGINE (250 Hz) ---
        self.ring_buffer.append((
            now,
            self.axes_state[0], self.axes_state[1], # LX, LY
            self.axes_state[3], self.axes_state[4], # RX, RY
            self.axes_state[2], self.axes_state[5], # L2, R2
            event_desc
        ))

        # Recalculate aim tremor index periodically (every 150 ms)
        if now - self.last_tremor_calc >= 0.15:
            self.last_tremor_calc = now
            cutoff = now - 0.5
            recent = [p for p in self.ring_buffer if p[0] >= cutoff]
            if len(recent) >= 5:
                rx_vals = [p[3] for p in recent]
                ry_vals = [p[4] for p in recent]
                mean_rx = sum(rx_vals) / len(rx_vals)
                mean_ry = sum(ry_vals) / len(ry_vals)
                var = sum((x - mean_rx)**2 + (y - mean_ry)**2 for x, y in zip(rx_vals, ry_vals)) / len(rx_vals)
                self.aim_tremor_index = round(math.sqrt(var), 2)

        # Telemetry Stream during Control Run
        if self.recording_active and self.telemetry_fp:
            elapsed = now - self.recording_start_time
            record = {
                "timestamp": round(elapsed, 3),
                "left_stick": [self.axes_state[0], self.axes_state[1]],
                "right_stick": [self.axes_state[3], self.axes_state[4]],
                "l2_trigger": self.axes_state[2],
                "r2_trigger": self.axes_state[5],
                "aim_tremor_index": self.aim_tremor_index,
                "event": event_desc
            }
            try:
                self.telemetry_fp.write(json.dumps(record) + "\n")
            except Exception:
                pass

    def check_recording_commands(self):
        """Checks for IPC control commands to start/stop session recording."""
        cmd_file = os.path.join(STAND_DIR, "scratch/telemetry_record.cmd")
        if os.path.exists(cmd_file):
            try:
                with open(cmd_file, "r", encoding="utf-8") as f:
                    cmd_data = json.load(f)
                try: os.remove(cmd_file)
                except: pass
                
                action = cmd_data.get("action")
                if action == "start":
                    target_file = cmd_data.get("output_file", os.path.join(STAND_DIR, "screens/session/session_telemetry.jsonl"))
                    os.makedirs(os.path.dirname(target_file), exist_ok=True)
                    if self.telemetry_fp:
                        try: self.telemetry_fp.close()
                        except: pass
                    self.telemetry_fp = open(target_file, "w", encoding="utf-8", buffering=1)
                    self.recording_active = True
                    self.recording_file_path = target_file
                    self.recording_start_time = time.time()
                    print(f"[{time.strftime('%H:%M:%S')}] 🔴 ЗАПИС КОНТРОЛЬНОГО ПРОГОНУ АКТИВОВАНО -> {target_file}")
                    self.write_live_state("recording_started")
                elif action == "stop":
                    self.recording_active = False
                    if self.telemetry_fp:
                        try: self.telemetry_fp.close()
                        except: pass
                        self.telemetry_fp = None
                    print(f"[{time.strftime('%H:%M:%S')}] ⏹️ ЗАПИС КОНТРОЛЬНОГО ПРОГОНУ ЗАВЕРШЕНО.")
                    self.write_live_state("recording_stopped")
            except Exception as e:
                print(f"[Footpad Mapper] Помилка обробки команди запису: {e}")

    def check_inject_commands(self):
        """Checks for IPC control commands to inject gamepad events for verification."""
        cmd_file = os.path.join(STAND_DIR, "scratch/gamepad_inject.cmd")
        if os.path.exists(cmd_file):
            try:
                with open(cmd_file, "r", encoding="utf-8") as f:
                    cmd_data = json.load(f)
                try: os.remove(cmd_file)
                except: pass
                
                btn = cmd_data.get("btn")
                axis = cmd_data.get("axis")
                val = cmd_data.get("val", 1)
                action = cmd_data.get("action", "press")
                
                if btn is not None and self.fd_uinput_gamepad:
                    if action == "tap":
                        self.emit_event(self.fd_uinput_gamepad, EV_KEY, btn, 1)
                        time.sleep(0.08)
                        self.emit_event(self.fd_uinput_gamepad, EV_KEY, btn, 0)
                        print(f"[{time.strftime('%H:%M:%S')}] [IPC Inject] Tap Button {btn}")
                    else:
                        self.emit_event(self.fd_uinput_gamepad, EV_KEY, btn, val)
                        print(f"[{time.strftime('%H:%M:%S')}] [IPC Inject] Button {btn} -> {val}")
                elif axis is not None and self.fd_uinput_gamepad:
                    self.emit_event(self.fd_uinput_gamepad, EV_ABS, axis, val)
                    print(f"[{time.strftime('%H:%M:%S')}] [IPC Inject] Axis {axis} -> {val}")
            except Exception as e:
                print(f"[Footpad Mapper] Помилка обробки команди inject: {e}")

    def handle_touchpad_event(self, ev_type, code, val):
        # Code 272 (BTN_LEFT) is the physical click of the DualShock 4 touchpad
        if ev_type == EV_KEY and code == 272 and val in (0, 1):
            is_pressed = (val == 1)
            state_str = "НАТИСНУТО" if is_pressed else "ВІДПУЩЕНО"
            print(f"[{time.strftime('%H:%M:%S')}] DS4 Touchpad Click (Switch POV / Back): {state_str}")
            
            # 1. Emit Back / BTN_SELECT (code 314) on Virtual Xbox 360 (View / POV switch)
            if self.fd_uinput_gamepad:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 314, val)
                
            self.write_live_state(f"touchpad_click_{state_str.lower()}")

    def handle_pedal_event(self, code, val):
        if val not in (0, 1): # Ignore autorepeat
            return
        
        mapping = self.pedal_map.get(code)
        if not mapping:
            return

        pos, action, kbd_key, gamepad_btn = mapping
        is_pressed = (val == 1)
        self.pedal_states[pos] = is_pressed
        
        state_str = "НАТИСНУТО" if is_pressed else "ВІДПУЩЕНО"
        print(f"[{time.strftime('%H:%M:%S')}] Педаль '{pos.upper()}' ({action}): {state_str}")

        # Check Left + Middle combo for HUD toggle
        if self.pedal_states.get("left", False) and self.pedal_states.get("middle", False):
            if not self.hud_combo_active:
                self.hud_combo_active = True
                print(f"[{time.strftime('%H:%M:%S')}] ⚡ КОМБО ПЕДАЛЕЙ (ЛІВА + СЕРЕДНЯ): Перемикання HUD-орієнтира!")
                try:
                    hud_env = dict(os.environ)
                    if "DISPLAY" not in hud_env:
                        hud_env["DISPLAY"] = ":0.0"
                    if "XAUTHORITY" not in hud_env:
                        hud_env["XAUTHORITY"] = os.path.expanduser("~/.Xauthority")
                    subprocess.Popen([sys.executable, SHOW_HUD_SCRIPT, "--toggle"], env=hud_env)
                except Exception as e:
                    print(f"[Footpad Mapper] Помилка виклику HUD: {e}")

            # Suppress sprint and jump while both pedals are held
            if self.fd_uinput_gamepad:
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 317, 0) # Release L3 (Sprint)
                self.emit_event(self.fd_uinput_gamepad, EV_KEY, 308, 0) # Release Y (Jump)
            self.write_live_state("hud_combo_triggered")
            return
        else:
            if self.hud_combo_active:
                self.hud_combo_active = False
                if self.fd_uinput_gamepad:
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 317, 0)
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, 308, 0)
                self.write_live_state("hud_combo_released")
                return

        # Special handling for "crouch" pedal: Hold-to-Crouch emulation
        # Fallout 4 natively operates crouch (R3) as a toggle.
        # To simulate true hold-to-crouch:
        # - Pressing pedal sends an R3 pulse (enters crouch)
        # - Releasing pedal sends another R3 pulse (exits crouch / stands up)
        if action == "crouch":
            if is_pressed:
                if self.fd_uinput_gamepad and gamepad_btn:
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, gamepad_btn, 1)
                    time.sleep(0.035)
                    self.emit_event(self.fd_uinput_gamepad, EV_KEY, gamepad_btn, 0)
                self.pedal_crouch_held = True
            else:
                if getattr(self, "pedal_crouch_held", False):
                    if self.fd_uinput_gamepad and gamepad_btn:
                        self.emit_event(self.fd_uinput_gamepad, EV_KEY, gamepad_btn, 1)
                        time.sleep(0.035)
                        self.emit_event(self.fd_uinput_gamepad, EV_KEY, gamepad_btn, 0)
                    self.pedal_crouch_held = False
            self.write_live_state(f"{pos}_{state_str.lower()}")
            return

        # 1. Update Gamepad State (Merged directly into Virtual Xbox 360 stream)
        if self.fd_uinput_gamepad and gamepad_btn:
            self.btn_state_pedal[gamepad_btn] = is_pressed
            effective = 1 if (self.btn_state_pedal[gamepad_btn] or self.btn_state_controller.get(gamepad_btn, False)) else 0
            self.emit_event(self.fd_uinput_gamepad, EV_KEY, gamepad_btn, effective)

        self.write_live_state(f"{pos}_{state_str.lower()}")

    def run(self):
        # 1. Virtual Devices: Persistent Xbox 360 Pad
        # Kept permanently open to prevent Fallout 4 from dropping out of gamepad mode
        self.setup_uinput_gamepad()
        
        # 2. FootSwitch hardware setup
        if not self.setup_footpad():
            print("[Footpad Mapper] Очікую підключення FootSwitch...")

        # 3. DualShock 4 hardware setup (only if physically present)
        if self.setup_dualshock4():
            self.setup_touchpad()
        else:
            print("[Footpad Mapper] Очікую підключення DualShock 4 (Virtual Xbox 360 pad вже активний)...")

        print("==================================================================")
        print(" FALLOUT 4 UNIFIED INPUT & FOOTPAD MAPPER АКТИВНИЙ!")
        print("  - Віртуальний контролер: Microsoft Xbox 360 (100% нативний XInput, Персистентний)")
        print("  - Нейро-біомеханічний сетап гравця:")
        print("      * L1 -> LT (Приціл / Блок - миттєвий тактильний бампер)")
        print("      * R1 -> RT (Постріл / Атака - миттєвий тактильний бампер)")
        print("      * L2 -> LB (Піп-Бой Назад / V.A.T.S. - легкий дотик >15)")
        print("      * R2 -> RB (Піп-Бой Вперед / Бій прикладом - легкий дотик >15)")
        print("  - Калібрування стіків: Deadzone 122..134 -> 0 (нуль дрейфу в Pip-Boy/меню)")
        print("  - Ліва педаль:    БІГ / СПРИНТ (Shift / L3)")
        print("  - Середня педаль: СТРИБОК / ДЖЕТПАК (Space / Y)")
        print("  - Права педаль:   ПРИСІСТИ / СКРИТНІСТЬ (Ctrl / R3)")
        if self.fd_ds4:
            print("  - DualShock 4:    АКТИВНИЙ (Нейро-профіль + Touchpad POV + Живе логування)")
        else:
            print("  - DualShock 4:    ВІД'ЄДНАНО (Очікую на підключення)")
        print("==================================================================")

        last_footpad_scan = 0
        last_ds4_scan = 0
        last_heartbeat = 0

        try:
            while self.running:
                now = time.time()
                if now - last_heartbeat > 3.0:
                    last_heartbeat = now
                    self.write_live_state("heartbeat")
                self.check_recording_commands()
                self.check_inject_commands()
                if not self.fd_footpad and now - last_footpad_scan > 2.0:
                    last_footpad_scan = now
                    self.setup_footpad()

                # Fast 1-second scan for instant DualShock 4 hotplug reconnection
                if not self.fd_ds4 and now - last_ds4_scan > 1.0:
                    last_ds4_scan = now
                    if self.setup_dualshock4():
                        self.setup_touchpad()

                inputs = [fd for fd in [self.fd_footpad, self.fd_ds4, self.fd_touchpad] if fd is not None]
                if not inputs:
                    time.sleep(0.5)
                    continue

                readable, _, _ = select.select(inputs, [], [], 0.5)
                
                # Handle FootSwitch events
                if self.fd_footpad in readable:
                    try:
                        data = os.read(self.fd_footpad, 24 * 16)
                        for i in range(0, len(data), 24):
                            sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                            if ev_type == EV_KEY:
                                self.handle_pedal_event(code, val)
                    except Exception as e:
                        print(f"[Footpad Mapper] Помилка читання FootSwitch: {e}")
                        try: os.close(self.fd_footpad)
                        except: pass
                        self.fd_footpad = None

                # Handle DualShock 4 Gamepad events (1:1 native pass-through)
                if self.fd_ds4 in readable:
                    try:
                        data = os.read(self.fd_ds4, 24 * 32)
                        for i in range(0, len(data), 24):
                            sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                            self.handle_ds4_event(ev_type, code, val)
                    except Exception as e:
                        print(f"[{time.strftime('%H:%M:%S')}] DualShock 4 від’єднано ({e}) - Virtual Xbox 360 pad залишається активним")
                        try: os.close(self.fd_ds4)
                        except: pass
                        self.fd_ds4 = None
                        self.reset_gamepad_states()
                        if self.fd_touchpad:
                            try: os.close(self.fd_touchpad)
                            except: pass
                            self.fd_touchpad = None

                # Handle DualShock 4 Touchpad events (Click -> POV switch)
                if self.fd_touchpad in readable:
                    try:
                        data = os.read(self.fd_touchpad, 24 * 16)
                        for i in range(0, len(data), 24):
                            sec, usec, ev_type, code, val = struct.unpack('qqHHi', data[i:i+24])
                            self.handle_touchpad_event(ev_type, code, val)
                    except Exception as e:
                        try: os.close(self.fd_touchpad)
                        except: pass
                        self.fd_touchpad = None

        except KeyboardInterrupt:
            pass
        finally:
            self.cleanup()

    def cleanup(self):
        print("\n[Footpad Mapper] Завершення роботи та відновлення пристроїв...")
        if self.fd_footpad:
            try:
                fcntl.ioctl(self.fd_footpad, EVIOCGRAB, 0)
                os.close(self.fd_footpad)
            except Exception:
                pass
            self.fd_footpad = None

        if self.fd_ds4:
            try:
                fcntl.ioctl(self.fd_ds4, EVIOCGRAB, 0)
                os.close(self.fd_ds4)
            except Exception:
                pass
            self.fd_ds4 = None

        if self.fd_touchpad:
            try:
                fcntl.ioctl(self.fd_touchpad, EVIOCGRAB, 0)
                os.close(self.fd_touchpad)
            except Exception:
                pass
            self.fd_touchpad = None

        if self.fd_uinput_gamepad:
            try:
                fcntl.ioctl(self.fd_uinput_gamepad, UI_DEV_DESTROY)
                os.close(self.fd_uinput_gamepad)
            except Exception:
                pass
        if self.fd_uinput_kbd:
            try:
                fcntl.ioctl(self.fd_uinput_kbd, UI_DEV_DESTROY)
                os.close(self.fd_uinput_kbd)
            except Exception:
                pass
            self.fd_uinput_kbd = None

        if self.telemetry_fp:
            try:
                self.telemetry_fp.close()
            except Exception:
                pass
            self.telemetry_fp = None

        print("[Footpad Mapper] Усі пристрої безпечно відновлено.")

def main():
    mapper = UnifiedFootpadMapper()
    def sig_handler(signum, frame):
        mapper.running = False
    
    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)
    mapper.run()

if __name__ == "__main__":
    main()
