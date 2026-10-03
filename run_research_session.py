#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Multimodal Research Session Recorder
------------------------------------
Синхронізований запис 4 активних каналів:
1. Chiaki Stream (кадри подій гри)
2. DualShock 4 (моторика, тремор 8-12 Гц, стіки, кнопки)
3. Гарнітура (аудіодоріжка коментарів Think-Aloud)
4. Єдиний часовий лог (мілісекундна синхронізація)
"""

import os
import sys
import time
import struct
import json
import zlib
import math
import subprocess
import threading
from datetime import datetime

SESSION_DIR = "/home/hills/Documents/fallaut/screens/session"
VOICE_FILE = os.path.join(SESSION_DIR, "session_voice.wav")
TELEMETRY_LOG = os.path.join(SESSION_DIR, "session_telemetry.jsonl")
SUMMARY_FILE = os.path.join(SESSION_DIR, "session_summary.json")

# Кнопки DualShock 4
BUTTON_NAMES = {
    0: "Cross (X)",
    1: "Circle (O)",
    2: "Triangle (Y)",
    3: "Square (X-box X)",
    4: "L1",
    5: "R1",
    6: "L2_click",
    7: "R2_click",
    8: "Share",
    9: "Options",
    10: "PS",
    11: "L3",
    12: "R3"
}

def make_png(width, height, rgb_data):
    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    raw = b""
    row_bytes = width * 3
    for y in range(height):
        raw += b"\x00" + rgb_data[y * row_bytes : (y + 1) * row_bytes]
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    idat = zlib.compress(raw, 4)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")

def find_game_window(timeout_sec=60):
    start = time.time()
    while time.time() - start < timeout_sec:
        try:
            p = subprocess.run(["xwininfo", "-root", "-tree"], capture_output=True, text=True)
            for line in p.stdout.splitlines():
                if "antigravity" in line.lower():
                    continue
                if '"Fallout4"' in line or '"fallout4.exe"' in line or "Chiaki | Stream" in line:
                    parts = line.strip().split()
                    if parts and parts[0].startswith("0x"):
                        return parts[0]
        except Exception:
            pass
        time.sleep(1.0)
    return None

def capture_window(win_id, output_path):
    tmp_xwd = f"/tmp/cap_{win_id}.xwd"
    res = subprocess.run(["xwd", "-id", win_id, "-out", tmp_xwd], capture_output=True)
    if res.returncode != 0 or not os.path.exists(tmp_xwd):
        return False, 0, 0
    try:
        with open(tmp_xwd, "rb") as f:
            data = f.read()
        os.remove(tmp_xwd)

        header_size = struct.unpack(">I", data[0:4])[0]
        pixmap_width = struct.unpack(">I", data[16:20])[0]
        pixmap_height = struct.unpack(">I", data[20:24])[0]
        bits_per_pixel = struct.unpack(">I", data[44:48])[0]
        bytes_per_line = struct.unpack(">I", data[48:52])[0]
        ncolors = struct.unpack(">I", data[76:80])[0]

        offset = header_size + ncolors * 12
        raw_pixels = data[offset:]

        rgb = bytearray(pixmap_width * pixmap_height * 3)
        idx = 0
        stride = bytes_per_line
        for y in range(pixmap_height):
            row = raw_pixels[y * stride : y * stride + pixmap_width * (bits_per_pixel // 8)]
            for x in range(pixmap_width):
                px_offset = x * 4 if bits_per_pixel == 32 else x * 3
                rgb[idx] = row[px_offset + 2]   # R
                rgb[idx+1] = row[px_offset + 1] # G
                rgb[idx+2] = row[px_offset]     # B
                idx += 3

        png_bytes = make_png(pixmap_width, pixmap_height, bytes(rgb))
        with open(output_path, "wb") as f:
            f.write(png_bytes)
        return True, pixmap_width, pixmap_height
    except Exception:
        return False, 0, 0

class SessionRecorder:
    def __init__(self, duration_sec=180):
        self.duration_sec = duration_sec
        self.running = False
        self.start_time = None
        self.audio_proc = None
        self.win_id = None
        
        # Моторика
        self.axes = [0] * 8
        self.buttons = [0] * 13
        self.right_stick_history = [] # для розрахунку тремору (RX, RY)
        self.motor_events = []
        self.keyframes = []
        self.lock = threading.Lock()

    def start_audio(self):
        try:
            if os.path.exists(VOICE_FILE):
                os.remove(VOICE_FILE)
            self.audio_proc = subprocess.Popen([
                "parec", "--file-format=wav", VOICE_FILE
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"[Аудіо] Запис голосу з гарнітури активовано -> {VOICE_FILE}")
        except Exception as e:
            print(f"[Аудіо] Помилка старту parec: {e}")

    def stop_audio(self):
        if self.audio_proc:
            try:
                self.audio_proc.terminate()
                self.audio_proc.wait(timeout=2)
            except Exception:
                self.audio_proc.kill()
            print("[Аудіо] Запис гарнітури завершено.")

    def run(self):
        os.makedirs(SESSION_DIR, exist_ok=True)
        print("Очікування вікна гри (Chiaki або Fallout 4)...")
        self.win_id = find_game_window(timeout_sec=90)
        if not self.win_id:
            print("ПОМИЛКА: Вікно гри не знайдено за 90 сек! Перевірте запуск гри.")
            return

        print(f"Знайдено вікно гри ({self.win_id}).")
        
        # Відкриваємо джойстик
        try:
            js_fd = os.open("/dev/input/js0", os.O_RDONLY | os.O_NONBLOCK)
            print("[Джойстик] /dev/input/js0 успішно підключено (опитування 100 Гц).")
        except Exception as e:
            print(f"[Джойстик] Помилка відкриття js0: {e}")
            return

        self.running = True
        self.start_time = time.time()
        self.start_audio()

        # Відкриваємо файл логу телеметрії
        log_f = open(TELEMETRY_LOG, "w", encoding="utf-8")
        
        # Перший базовий скріншот
        first_frame = os.path.join(SESSION_DIR, "frame_000_baseline.png")
        capture_window(self.win_id, first_frame)
        self.keyframes.append({"elapsed": 0.0, "file": "frame_000_baseline.png", "reason": "baseline"})

        print(f"\n=======================================================")
        print(f"   ТЕСТОВИЙ НАУКОВИЙ СЕАНС РОЗПОЧАТО! (Тривалість: {self.duration_sec} сек)")
        print(f"   Говоріть у гарнітуру та керуйте в грі DualShock 4")
        print(f"   Для дострокового завершення натисніть Ctrl+C")
        print(f"=======================================================\n")

        last_periodic_capture = time.time()
        last_event_capture = 0.0
        last_tremor_calc = time.time()
        current_tremor_index = 0.0

        try:
            while self.running:
                now = time.time()
                elapsed = now - self.start_time
                if elapsed >= self.duration_sec:
                    print(f"\nЧас сесії вийшов ({self.duration_sec} сек).")
                    break

                # 1. Читаємо події джойстика
                event_occurred = False
                event_desc = None

                while True:
                    try:
                        data = os.read(js_fd, 8)
                        if len(data) == 8:
                            t, val, tp, num = struct.unpack("IhBB", data)
                            if tp & 0x02: # Осі
                                if num < 8:
                                    self.axes[num] = val
                                    # Відхилення правого стіка для тремору
                                    if num in [3, 4]:
                                        self.right_stick_history.append((now, self.axes[3], self.axes[4]))
                            elif tp & 0x01: # Кнопка
                                if num < 13:
                                    prev = self.buttons[num]
                                    self.buttons[num] = val
                                    if val == 1 and prev == 0:
                                        btn_name = BUTTON_NAMES.get(num, f"Button_{num}")
                                        event_occurred = True
                                        event_desc = f"BTN_DOWN_{btn_name}"
                    except BlockingIOError:
                        break

                # 2. Розрахунок мікротремору прицілу кожні 200 мс (дисперсія RX/RY)
                if now - last_tremor_calc >= 0.2:
                    last_tremor_calc = now
                    # фільтруємо історію за останні 500 мс
                    self.right_stick_history = [p for p in self.right_stick_history if now - p[0] <= 0.5]
                    if len(self.right_stick_history) >= 5:
                        rx_vals = [p[1] for p in self.right_stick_history]
                        ry_vals = [p[2] for p in self.right_stick_history]
                        mean_rx = sum(rx_vals) / len(rx_vals)
                        mean_ry = sum(ry_vals) / len(ry_vals)
                        var = sum((x - mean_rx)**2 + (y - mean_ry)**2 for x, y in zip(rx_vals, ry_vals)) / len(rx_vals)
                        current_tremor_index = round(math.sqrt(var), 2)

                # 3. Запис у мілісекундний лог
                record = {
                    "timestamp": round(elapsed, 3),
                    "left_stick": [self.axes[0], self.axes[1]],
                    "right_stick": [self.axes[3], self.axes[4]],
                    "l2_trigger": self.axes[2],
                    "r2_trigger": self.axes[5],
                    "aim_tremor_index": current_tremor_index,
                    "event": event_desc
                }
                log_f.write(json.dumps(record) + "\n")

                # 4. Скріншот за подією (Event-driven) або періодично (кожні 10 сек)
                should_capture = False
                capture_reason = ""

                if event_occurred and (now - last_event_capture >= 0.5):
                    should_capture = True
                    capture_reason = event_desc
                    last_event_capture = now
                elif now - last_periodic_capture >= 8.0:
                    should_capture = True
                    capture_reason = "periodic_interval"
                    last_periodic_capture = now

                if should_capture and len(self.keyframes) < 80: # розширений ліміт для бойової сесії
                    frame_name = f"frame_{int(elapsed):03d}s_{capture_reason.replace(' ', '_').replace('(', '').replace(')', '')}.png"
                    frame_path = os.path.join(SESSION_DIR, frame_name)
                    ok, w, h = capture_window(self.win_id, frame_path)
                    if ok:
                        self.keyframes.append({"elapsed": round(elapsed, 2), "file": frame_name, "reason": capture_reason})
                        # Оновлюємо latest.png
                        import shutil
                        shutil.copyfile(frame_path, "/home/hills/Documents/fallaut/screens/latest.png")
                        print(f"[{round(elapsed, 1)}s] Подія: {capture_reason} -> Кадр: {frame_name} | Тремор стіка: {current_tremor_index}")

                time.sleep(0.01) # 100 Гц опитування

        except KeyboardInterrupt:
            print("\nСеанс зупинено користувачем (Ctrl+C).")
        finally:
            self.running = False
            os.close(js_fd)
            log_f.close()
            self.stop_audio()

        # Підсумковий звіт сесії
        total_time = round(time.time() - self.start_time, 1)
        voice_size = os.path.getsize(VOICE_FILE) if os.path.exists(VOICE_FILE) else 0

        summary = {
            "session_type": "Multimodal Research Test",
            "duration_sec": total_time,
            "total_keyframes": len(self.keyframes),
            "voice_file": "session_voice.wav",
            "voice_size_bytes": voice_size,
            "telemetry_file": "session_telemetry.jsonl",
            "keyframes": self.keyframes
        }

        with open(SUMMARY_FILE, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)

        print("\n=======================================================")
        print(f"   СЕАНС УСПІШНО ЗАВЕРШЕНО! ({total_time} сек)")
        print(f"   Аудіо коментарів: {voice_size / 1024:.1f} КБ ({VOICE_FILE})")
        print(f"   Ключових кадрів:  {len(self.keyframes)} шт")
        print(f"   Лог телеметрії:   {TELEMETRY_LOG}")
        print(f"=======================================================\n")

if __name__ == "__main__":
    dur = 1800 # 30 хвилин за замовчуванням для живого геймплею
    if len(sys.argv) > 1:
        dur = int(sys.argv[1])
    recorder = SessionRecorder(duration_sec=dur)
    recorder.run()
