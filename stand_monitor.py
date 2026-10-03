#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 Research Stand - Smart Telemetry & Health Monitor
===========================================================
Token-efficient, zero-overhead diagnostic aggregator.
Provides instant health analysis of game process, engine scripts,
wine crashes, input devices, and savegame states without overloading
chat context or system memory.
"""

import os
import sys
import json
import glob
import time
import struct
from datetime import datetime

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
SCRATCH_DIR = os.path.join(STAND_DIR, "scratch")
PREFIX_DIR = os.path.join(STAND_DIR, "prefix")
SAVES_DIR = os.path.join(PREFIX_DIR, "drive_c/users/hills/Documents/My Games/Fallout4/Saves")
PAPYRUS_LOG = os.path.join(PREFIX_DIR, "drive_c/users/hills/Documents/My Games/Fallout4/Logs/Script/Papyrus.0.log")
GAME_LOG = os.path.join(SCRATCH_DIR, "game_crash.log")
SENTINEL_STATUS = os.path.join(SCRATCH_DIR, "sentinel_status.json")
SENTINEL_ALERTS = os.path.join(SCRATCH_DIR, "sentinel_alerts.log")

def get_sentinel_state():
    if not os.path.exists(SENTINEL_STATUS):
        return {"active": False, "note": "sentinel_status.json відсутній"}
    try:
        mtime = os.path.getmtime(SENTINEL_STATUS)
        age = time.time() - mtime
        with open(SENTINEL_STATUS, "r", encoding="utf-8") as f:
            data = json.load(f)
        data["file_age_sec"] = round(age, 1)
        data["active"] = age < 10.0
        return data
    except Exception as e:
        return {"active": False, "error": str(e)}

def parse_save_header(path):
    try:
        with open(path, "rb") as f:
            data = f.read(1024)
        if len(data) < 24 or data[:12] != b"FO4_SAVEGAME":
            return None
        save_num = struct.unpack("<I", data[20:24])[0]
        offset = 24
        def read_str(d, off):
            l = struct.unpack("<H", d[off:off+2])[0]
            s = d[off+2:off+2+l].decode("utf-8", errors="ignore")
            return s, off + 2 + l
        player, offset = read_str(data, offset)
        level = struct.unpack("<I", data[offset:offset+4])[0]
        offset += 4
        location, offset = read_str(data, offset)
        game_date, offset = read_str(data, offset)
        mtime = os.path.getmtime(path)
        return {
            "filename": os.path.basename(path),
            "size_mb": round(os.path.getsize(path) / (1024 * 1024), 2),
            "mtime_str": datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S"),
            "mtime_age_min": round((time.time() - mtime) / 60, 1),
            "player": player,
            "level": level,
            "location": location,
            "game_date": game_date
        }
    except Exception:
        return None

def get_latest_saves():
    if not os.path.exists(SAVES_DIR):
        return []
    files = glob.glob(os.path.join(SAVES_DIR, "*.fos"))
    files.sort(key=os.path.getmtime, reverse=True)
    results = []
    for f in files[:3]:
        info = parse_save_header(f)
        if info:
            results.append(info)
    return results

def get_papyrus_summary():
    if not os.path.exists(PAPYRUS_LOG):
        return {"status": "NO_LOG", "events": []}
    try:
        with open(PAPYRUS_LOG, "r", encoding="utf-8", errors="ignore") as f:
            lines = [line.strip() for line in f if line.strip()]
        last_lines = lines[-20:] if len(lines) >= 20 else lines
        events = []
        is_thawing = False
        is_closed = False
        errors = []
        for line in last_lines:
            if "VM is thawing" in line:
                is_thawing = True
            elif "Log closed" in line:
                is_closed = True
            elif "error:" in line:
                clean_err = line.split("error:")[-1].strip()
                if "missing file" not in clean_err:
                    errors.append(clean_err[:90])
        return {
            "total_lines": len(lines),
            "last_thawing": is_thawing,
            "log_closed": is_closed,
            "recent_errors": errors[-3:],
            "tail": last_lines[-4:]
        }
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}

def get_game_crash_log_summary():
    if not os.path.exists(GAME_LOG):
        return {"status": "NO_LOG", "errors": []}
    try:
        mtime = os.path.getmtime(GAME_LOG)
        with open(GAME_LOG, "r", encoding="utf-8", errors="ignore") as f:
            lines = [line.strip() for line in f if line.strip()]
        err_lines = [l for l in lines if any(k in l.lower() for k in ["err:", "page fault", "segfault", "exception", "abort"])]
        return {
            "total_lines": len(lines),
            "mtime_age_min": round((time.time() - mtime) / 60, 1),
            "errors": err_lines[-3:]
        }
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}

def main():
    as_json = "--json" in sys.argv
    sentinel = get_sentinel_state()
    saves = get_latest_saves()
    papyrus = get_papyrus_summary()
    crash_log = get_game_crash_log_summary()

    # Determine health verdict
    latest_save = saves[0] if saves else None
    verdict = "OK"
    advice = "Система стабільна."

    is_running = sentinel.get("game", {}).get("running", False)
    if is_running:
        verdict = "GAME_RUNNING"
        advice = "Fallout 4 зараз активно працює."
    else:
        if latest_save and "Exitsave" in latest_save.get("filename", ""):
            verdict = "CRASH_LOOP_RISK"
            advice = "Останнє збереження — Exitsave. Якщо гра вилітає при «Продовжити», завантажте Autosave3 через «Завантажити»."
        elif not papyrus.get("log_closed", False) and papyrus.get("last_thawing", False):
            verdict = "POSSIBLE_CRASH"
            advice = "Рушій завершився раптово без запису 'Log closed'. Зафіксовано аварійне закриття."

    report = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "verdict": verdict,
        "advice": advice,
        "subsystems": {
            "game_running": is_running,
            "footpad_running": sentinel.get("footpad", {}).get("running", False),
            "copilot_running": sentinel.get("copilot", {}).get("running", False),
            "ds4_connected": sentinel.get("devices", {}).get("ds4", False),
            "footpad_connected": sentinel.get("devices", {}).get("footpad", False),
            "console_copilot": os.path.exists(os.path.join(STAND_DIR, "game_console_copilot.py")),
            "nav_map_bridge": os.path.exists(os.path.join(STAND_DIR, "navigation_map_bridge.py")),
            "stream_watcher": "DISABLED"
        },
        "latest_saves": saves,
        "papyrus": papyrus,
        "engine_log": crash_log
    }

    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return

    # Beautiful compact console output
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BOLD = "\033[1m"
    RESET = "\033[0m"

    v_color = GREEN if verdict in ["OK", "GAME_RUNNING"] else (YELLOW if verdict == "CRASH_LOOP_RISK" else RED)

    print(f"{BOLD}=================================================================={RESET}")
    print(f"{BOLD} 🛰️  FALLOUT 4 STAND TELEMETRY MONITOR ({report['timestamp']}){RESET}")
    print(f" Статус системи: {v_color}{BOLD}[{verdict}]{RESET} — {advice}")
    print(f"{BOLD}------------------------------------------------------------------{RESET}")
    
    sub = report["subsystems"]
    print(f" {BOLD}Підсистеми:{RESET} Гра: {'🟢' if sub['game_running'] else '⚪'} | "
          f"Педалі: {'🟢' if sub['footpad_running'] else '⚪'} | "
          f"Копілот: {'🟢' if sub['copilot_running'] else '⚪'} | "
          f"Консоль: {'🟢' if sub.get('console_copilot') else '⚪'} | "
          f"Навігація (Map): {'🟢' if sub.get('nav_map_bridge') else '⚪'} | "
          f"Стрім-нагляд: ⏹️ [Вимкнено]")
    print(f" {BOLD}Периферія:{RESET} DualShock 4: {'🟢' if sub['ds4_connected'] else '🔴'} | "
          f"FootSwitch: {'🟢' if sub['footpad_connected'] else '🔴'}")

    print(f"{BOLD}------------------------------------------------------------------{RESET}")
    print(f" {BOLD}Останні збереження:{RESET}")
    for idx, s in enumerate(saves, 1):
        tag = "🔴 [АВАРІЙНИЙ СЕЙВ?]" if "Exitsave" in s['filename'] else "🟢 [СТАБІЛЬНИЙ]"
        print(f"   {idx}. {BOLD}{s['filename']}{RESET} ({s['size_mb']} MB, {s['mtime_age_min']} хв тому)")
        print(f"      Локація: {s['location']} | Ігровий час: {s['game_date']} | {tag}")

    print(f"{BOLD}------------------------------------------------------------------{RESET}")
    print(f" {BOLD}Скриптовий рушій (Papyrus):{RESET}")
    print(f"   Стан логу: {'Штатно закрито' if papyrus.get('log_closed') else 'Аварійний обрив (не закрито)'} | Всього рядків: {papyrus.get('total_lines', 0)}")
    if papyrus.get("recent_errors"):
        print(f"   Останні скриптові помилки:")
        for err in papyrus["recent_errors"]:
            print(f"     ⚠️  {err}")

    if crash_log.get("errors"):
        print(f"{BOLD}------------------------------------------------------------------{RESET}")
        print(f" {BOLD}Системні помилки Wine/DXVK:{RESET}")
        for err in crash_log["errors"]:
            print(f"     ❌ {err}")

    print(f"{BOLD}=================================================================={RESET}")

if __name__ == "__main__":
    main()
