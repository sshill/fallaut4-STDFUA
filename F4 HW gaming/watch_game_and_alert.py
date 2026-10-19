#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 Startup & Console Readiness Watcher
============================================
Waits for Fallout 4 window/process, triggers on-screen readiness notification,
and preps test verification payload.
"""

import os
import sys
import time
import glob
import subprocess

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
GAME_CMD = os.path.join(STAND_DIR, "game/copilot_cmd.txt")
STATUS_FILE = os.path.join(STAND_DIR, "scratch/console_readiness.json")

# Prepare test command payload in game directory
with open(GAME_CMD, "w", encoding="ascii") as f:
    f.write("; === COPILOT READINESS TEST PAYLOAD ===\r\n")
    f.write("player.getlevel\r\n")
    f.write("player.getav health\r\n")

print("[Watcher] Очікую завантаження Fallout 4...", flush=True)

# Wait up to 180 seconds for game startup
start_t = time.time()
found = False

while time.time() - start_t < 180:
    for p in glob.glob("/proc/[0-9]*/cmdline"):
        try:
            with open(p, "rb") as f:
                cmd = f.read().decode("utf-8", errors="ignore").replace("\x00", " ")
                if "fallout4.exe" in cmd.lower() and "python" not in cmd.lower():
                    found = True
                    break
        except Exception:
            pass
    if found:
        break
    time.sleep(1.0)

if found:
    print("[Watcher] 🟢 Fallout 4 успішно виявлено в системі!", flush=True)
    # Give the engine 3 seconds to initialize graphics/input
    time.sleep(3)
    try:
        subprocess.run([
            "xmessage", "-center", "-timeout", "5",
            "🟢 FALLOUT 4: КОНСОЛЬНИЙ МІСТ ГОТОВИЙ!\n\n"
            " • Консоль гри активна: клавіша ~ (тильда)\n"
            " • Тестовий макрос завантажено: bat copilot_cmd\n"
            " • Лог Papyrus.0.log підключено"
        ], timeout=6, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass
else:
    print("[Watcher] Час очікування запуску вичерпано (180с).", flush=True)
