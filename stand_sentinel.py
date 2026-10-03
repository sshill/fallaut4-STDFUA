#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 Research Stand - Realtime Health & Sentinel Watchdog
=============================================================
Continuously monitors all stand subsystems:
  1. Fallout4.exe (Wine DirectX / Vulkan game process)
  2. footpad_mapper.py (Virtual Xbox 360 controller & FootSwitch daemon)
  3. voice_copilot_service.py (Telemetry & AI co-pilot daemon)
  4. Physical USB hardware (Sony DualShock 4 & PCsensor FootSwitch)
  5. Error logs (scratch/footpad.log, scratch/copilot.log)

Instant Alerting:
  - If any critical module or USB device drops while the game is running,
    immediately sends an X11 desktop notification (notify-send) to the user's
    laptop screen so the player can safely pause/stop without frustration.
  - Maintains live health status in scratch/sentinel_status.json.
  - Appends alerts to scratch/sentinel_alerts.log.
"""

import os
import sys
import glob
import time
import json
import fcntl
import signal
import subprocess

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
STATUS_FILE = os.path.join(STAND_DIR, "scratch/sentinel_status.json")
ALERTS_LOG = os.path.join(STAND_DIR, "scratch/sentinel_alerts.log")
FOOTPAD_LOG = os.path.join(STAND_DIR, "scratch/footpad.log")
COPILOT_LOG = os.path.join(STAND_DIR, "scratch/copilot.log")

os.makedirs(os.path.join(STAND_DIR, "scratch"), exist_ok=True)

def send_desktop_notification(title, message, urgency="critical"):
    env = os.environ.copy()
    env["DISPLAY"] = ":0.0"
    env["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/run/user/1000/bus"
    icon = "dialog-error" if urgency == "critical" else "dialog-warning"
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "-i", icon, title, message],
            env=env,
            timeout=2,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

def find_processes():
    my_pid = os.getpid()
    procs = {}
    for p in glob.glob("/proc/[0-9]*"):
        try:
            pid = int(os.path.basename(p))
            if pid == my_pid:
                continue
            with open(p + "/cmdline", "rb") as f:
                cmd = f.read().decode("utf-8", errors="ignore").replace("\x00", " ")
                if "Fallout4.exe" in cmd and "python" not in cmd:
                    procs["fallout4"] = pid
                elif "footpad_mapper.py" in cmd and pid != my_pid and "grep" not in cmd:
                    procs["footpad"] = pid
                elif "voice_copilot_service.py" in cmd and pid != my_pid and "grep" not in cmd:
                    procs["copilot"] = pid
        except Exception:
            pass
    return procs

def check_usb_devices():
    ds4 = False
    footpad = False
    for p in glob.glob("/dev/input/event*"):
        try:
            fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
            buf = bytearray(256)
            fcntl.ioctl(fd, 0x82004506, buf)
            name = buf.split(bytes([0]))[0].decode("utf-8", errors="ignore")
            os.close(fd)
            if "Sony" in name and ("Wireless Controller" in name or "DualShock" in name) and "Touchpad" not in name:
                ds4 = True
            elif "PCsensor" in name and "Keyboard" in name:
                footpad = True
        except Exception:
            pass
    return {"ds4": ds4, "footpad": footpad}

def log_alert(level, message):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{ts}] [{level}] {message}\n"
    print(entry.strip(), flush=True)
    try:
        with open(ALERTS_LOG, "a", encoding="utf-8") as f:
            f.write(entry)
    except Exception:
        pass

def check_log_errors(filepath, max_lines=20):
    if not os.path.exists(filepath):
        return []
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()[-max_lines:]
        errors = [l.strip() for l in lines if "Traceback" in l or "Error" in l or "Exception" in l]
        return errors
    except Exception:
        return []

def check_and_enforce_display():
    try:
        env = dict(os.environ, DISPLAY=":0.0")
        out = subprocess.check_output(["xrandr", "--query"], env=env, timeout=1).decode("utf-8")
        if "HDMI-1 connected" in out and "eDP-1 connected" in out:
            # Desired state: HDMI-1 at +0+0 primary, eDP-1 at +1920+0
            if "HDMI-1 connected primary 1920x1080+0+0" not in out or "eDP-1 connected 1920x1080+1920+0" not in out:
                subprocess.run(
                    ["xrandr", "--output", "HDMI-1", "--mode", "1920x1080", "--pos", "0x0", "--primary",
                     "--output", "eDP-1", "--mode", "1920x1080", "--pos", "1920x0"],
                    env=env, timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                subprocess.run(["xfconf-query", "-c", "xfce4-panel", "-p", "/panels/panel-1/output-name", "-s", "eDP-1"], env=env, timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                subprocess.run(["xfconf-query", "-c", "xfce4-panel", "-p", "/panels/panel-2/output-name", "-s", "eDP-1"], env=env, timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                log_alert("INFO", "Автоматично відновлено топологію: Samsung зліва (+0+0, primary), лаптоп праворуч (+1920+0)")
    except Exception:
        pass

def main():
    print(f"[{time.strftime('%H:%M:%S')}] Fallout Stand Sentinel активний. Моніторинг запущено...", flush=True)
    check_and_enforce_display()
    
    running = True
    def sig_handler(sig, frame):
        nonlocal running
        running = False
    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    was_game_running = False
    was_footpad_running = False
    was_copilot_running = False
    was_ds4_connected = True
    was_footpad_connected = True
    recent_alerts = []

    while running:
        try:
            procs = find_processes()
            devs = check_usb_devices()
            now = time.time()
            ts_str = time.strftime('%H:%M:%S')

            game_pid = procs.get("fallout4")
            footpad_pid = procs.get("footpad")
            copilot_pid = procs.get("copilot")

            is_game_running = game_pid is not None
            is_footpad_running = footpad_pid is not None
            is_copilot_running = copilot_pid is not None
            is_ds4_connected = devs["ds4"]
            is_footpad_connected = devs["footpad"]

            new_alerts = []

            # 1. Game lifecycle events
            if is_game_running and not was_game_running:
                log_alert("INFO", f"Fallout 4 запущено (PID: {game_pid})")
                send_desktop_notification("Fallout Stand", f"Fallout 4 успішно запущено (PID: {game_pid})", urgency="normal")
            elif not is_game_running and was_game_running:
                log_alert("INFO", "Fallout 4 зупинено / завершено")
                send_desktop_notification("Fallout Stand", "Fallout 4 завершено", urgency="normal")

            # 2. Critical failures while game is running
            if is_game_running:
                if not is_footpad_running:
                    msg = "КРИТИЧНИЙ ЗБІЙ: footpad_mapper.py не активний під час гри! АВТОВІДНОВЛЕННЯ..."
                    log_alert("CRITICAL", msg)
                    send_desktop_notification("УВАГА: ЗБІЙ КЕРУВАННЯ!", "footpad_mapper.py впав! Автоматично відновлюю...", urgency="critical")
                    new_alerts.append({"time": ts_str, "level": "CRITICAL", "msg": msg})
                    try:
                        with open(FOOTPAD_LOG, "a") as f_out:
                            p = subprocess.Popen([sys.executable, os.path.join(STAND_DIR, "footpad_mapper.py")], stdout=f_out, stderr=subprocess.STDOUT)
                            log_alert("INFO", f"footpad_mapper.py успішно реанімовано (PID: {p.pid})")
                            is_footpad_running = True
                            footpad_pid = p.pid
                            send_desktop_notification("ВІДНОВЛЕНО", "Керування footpad_mapper відновлено!", urgency="normal")
                    except Exception as e:
                        log_alert("ERROR", f"Не вдалося реанімувати footpad_mapper: {e}")

                if was_ds4_connected and not is_ds4_connected:
                    msg = "КРИТИЧНО: DualShock 4 від'єднано від USB!"
                    log_alert("CRITICAL", msg)
                    send_desktop_notification("УВАГА: ГЕЙМПАД ВІД'ЄДНАНО!", "DualShock 4 від'єднано від USB! Зупиніть гру!", urgency="critical")
                    new_alerts.append({"time": ts_str, "level": "CRITICAL", "msg": msg})

                if was_footpad_connected and not is_footpad_connected:
                    msg = "КРИТИЧНО: Педалі FootSwitch від'єднано від USB!"
                    log_alert("CRITICAL", msg)
                    send_desktop_notification("УВАГА: ПЕДАЛІ ВІД'ЄДНАНО!", "Педалі PCsensor від'єднано від USB!", urgency="critical")
                    new_alerts.append({"time": ts_str, "level": "CRITICAL", "msg": msg})

                if was_copilot_running and not is_copilot_running:
                    msg = "Попередження: voice_copilot_service.py зупинився"
                    log_alert("WARNING", msg)
                    send_desktop_notification("Попередження", "voice_copilot_service.py зупинився", urgency="normal")
                    new_alerts.append({"time": ts_str, "level": "WARNING", "msg": msg})

            # Check log files for errors
            footpad_errs = check_log_errors(FOOTPAD_LOG)
            copilot_errs = check_log_errors(COPILOT_LOG)

            if new_alerts:
                recent_alerts = (new_alerts + recent_alerts)[:10]

            # Save state to json for agent queries
            status = {
                "game": {"running": is_game_running, "pid": game_pid},
                "footpad": {"running": is_footpad_running, "pid": footpad_pid, "errors": footpad_errs[-2:] if footpad_errs else []},
                "copilot": {"running": is_copilot_running, "pid": copilot_pid, "errors": copilot_errs[-2:] if copilot_errs else []},
                "devices": {"ds4": is_ds4_connected, "footpad": is_footpad_connected},
                "recent_alerts": recent_alerts,
                "updated_at": now,
                "updated_str": ts_str
            }
            try:
                with open(STATUS_FILE, "w", encoding="utf-8") as f:
                    json.dump(status, f, indent=2)
            except Exception:
                pass

            was_game_running = is_game_running
            was_footpad_running = is_footpad_running
            was_copilot_running = is_copilot_running
            was_ds4_connected = is_ds4_connected
            # Enforce Samsung on LEFT (+0+0) and Laptop on RIGHT (+1920+0)
            check_and_enforce_display()

            time.sleep(2.0)
        except Exception as e:
            time.sleep(2.0)

    print(f"[{time.strftime('%H:%M:%S')}] Sentinel зупинено.", flush=True)

if __name__ == "__main__":
    main()
