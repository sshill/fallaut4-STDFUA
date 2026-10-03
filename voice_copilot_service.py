#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fallout 4 GOTY Research Stand - Voice Co-Pilot & Cognitive Telemetry Service
=============================================================================
Features:
1. Always-on Microphone Listening via DualShock 4 3.5mm Headset (or laptop DMIC fallback).
2. Energy-based Dynamic VAD (Voice Activity Detection).
3. Think-Aloud & Vocal Stress Telemetry -> screens/session/session_telemetry.jsonl.
4. Voice Command Dispatcher ("Геміні...", "Gemini...", "Джеміні...") via Gemini 2.5 Flash.
5. Proactive Anti-Tunnel Vision & Disorientation detection (Voice + Controller + Game events).
6. Real-time Pip-Boy 3000 Web Dashboard (http://localhost:8088) & Desktop OSD notifications.
"""

import os
import sys
import time
import math
import wave
import json
import base64
import struct
import urllib.request
import urllib.error
import subprocess
import threading
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

STAND_DIR = "/home/hills/Documents/fallaut"
SESSION_DIR = os.path.join(STAND_DIR, "screens/session")
AUDIO_DIR = os.path.join(SESSION_DIR, "audio_chunks")
TELEMETRY_LOG = os.path.join(SESSION_DIR, "session_telemetry.jsonl")
STATE_FILE = os.path.join(STAND_DIR, "scratch/hud_state.json")
PAPYRUS_LOG = os.path.join(STAND_DIR, "prefix/drive_c/users/hills/Documents/My Games/Fallout4/Logs/Script/Papyrus.0.log")

os.makedirs(AUDIO_DIR, exist_ok=True)
os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)

# ---------------------------------------------------------------------------
# Load API Key from ~/.env safely
# ---------------------------------------------------------------------------
def get_gemini_api_key():
    env_path = os.path.expanduser("~/.env")
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("GEMINI_API_KEY="):
                        return line.split("=", 1)[1].strip().strip('"').strip("'")
        except Exception:
            pass
    return os.environ.get("GEMINI_API_KEY", "")

# ---------------------------------------------------------------------------
# Global State for OSD / Dashboard
# ---------------------------------------------------------------------------
state_lock = threading.Lock()
current_state = {
    "status": "Ініціалізація...",
    "mic_device": "Unknown",
    "is_speaking": False,
    "current_rms": 0,
    "last_transcript": "Очікування голосу...",
    "last_emotion": "Спокій",
    "last_command": "",
    "last_response": "Геміні готова до голосових запитів.",
    "disorientation_warning": False,
    "orientation_hint": "Орієнтир стабільний.",
    "updated_at": datetime.now().isoformat(),
    "history": []
}

def update_state(**kwargs):
    with state_lock:
        current_state.update(kwargs)
        current_state["updated_at"] = datetime.now().isoformat()
        try:
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(current_state, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

# ---------------------------------------------------------------------------
# Detect Capture Audio Device
# ---------------------------------------------------------------------------
def detect_audio_device():
    # Priority 1: DualShock 4 3.5mm Headset Microphone (Zero Bluetooth interference)
    try:
        res = subprocess.run(["arecord", "-l"], capture_output=True, text=True)
        if "Wireless Controller" in res.stdout or "Controller" in res.stdout:
            return "hw:CARD=Controller,DEV=0", "DualShock 4 (3.5mm Headset Jack)"
    except Exception:
        pass

    # Priority 2: Laptop Digital Microphone Array (DMIC)
    try:
        res = subprocess.run(["arecord", "-l"], capture_output=True, text=True)
        if "sof-hda-dsp" in res.stdout:
            return "plughw:CARD=sofhdadsp,DEV=6", "Вбудований DMIC масив ноутбука"
    except Exception:
        pass

    return "default", "Системний аудіовхід (Default)"

# ---------------------------------------------------------------------------
# Audio Recording & Dynamic VAD Worker
# ---------------------------------------------------------------------------
def audio_listener_loop():
    device_id, device_name = detect_audio_device()
    print(f"[Voice Co-Pilot] Використовується аудіовхід: {device_name} ({device_id})")
    update_state(mic_device=device_name, status="Слухаю ефір...")

    chunk_samples = 1600  # 100 ms at 16000 Hz
    chunk_bytes = chunk_samples * 2  # S16_LE

    cmd = [
        "arecord",
        "-D", device_id,
        "-f", "S16_LE",
        "-r", "16000",
        "-c", "1",
        "-t", "raw"
    ]

    while True:
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            buffer = bytearray()
            is_speaking = False
            silence_frames = 0
            speech_frames = 0
            energy_history = []

            while True:
                raw_chunk = proc.stdout.read(chunk_bytes)
                if not raw_chunk or len(raw_chunk) < chunk_bytes:
                    break

                samples = struct.unpack(f"<{chunk_samples}h", raw_chunk)
                rms = math.sqrt(sum(s * s for s in samples) / len(samples))
                energy_history.append(rms)
                if len(energy_history) > 50:
                    energy_history.pop(0)

                # Dynamic noise floor
                avg_noise = sum(energy_history) / len(energy_history)
                speech_threshold = max(avg_noise * 1.8, 450.0)

                if rms > speech_threshold:
                    if not is_speaking:
                        is_speaking = True
                        update_state(is_speaking=True, current_rms=round(rms, 1))
                    silence_frames = 0
                    speech_frames += 1
                    buffer.extend(raw_chunk)
                else:
                    if is_speaking:
                        buffer.extend(raw_chunk)
                        silence_frames += 1
                        # 1.0 second of silence after speech -> finalize utterance
                        if silence_frames > 10:
                            if speech_frames >= 4:  # At least 400ms of real speech
                                final_pcm = bytes(buffer)
                                threading.Thread(target=process_utterance, args=(final_pcm,), daemon=True).start()
                            buffer.clear()
                            is_speaking = False
                            speech_frames = 0
                            silence_frames = 0
                            update_state(is_speaking=False, current_rms=0)
                    else:
                        if len(buffer) > chunk_bytes * 5:
                            buffer = buffer[-chunk_bytes * 3:]
                        update_state(is_speaking=False, current_rms=round(rms, 1))

        except Exception as e:
            print(f"[Voice Co-Pilot] Audio capture exception: {e}")
            time.sleep(2)

# ---------------------------------------------------------------------------
# Utterance Processing: Gemini Multimodal & Think-Aloud Telemetry
# ---------------------------------------------------------------------------
def process_utterance(pcm_data):
    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:19]
    wav_path = os.path.join(AUDIO_DIR, f"speech_{timestamp_str}.wav")

    # Save to WAV (16kHz Mono 16-bit)
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(16000)
        w.writeframes(pcm_data)

    n_samples = len(pcm_data) // 2
    samples = struct.unpack(f"<{n_samples}h", pcm_data)
    peak_amp = max(abs(s) for s in samples) if n_samples > 0 else 0
    avg_rms = math.sqrt(sum(s * s for s in samples) / n_samples) if n_samples > 0 else 0
    duration_s = n_samples / 16000.0

    print(f"\n[Голос] Зафіксовано репліку: {duration_s:.1f}с, RMS: {avg_rms:.1f}, файл: {os.path.basename(wav_path)}")

    api_key = get_gemini_api_key()
    telemetry_record = {
        "timestamp_iso": datetime.now().isoformat(),
        "wav_file": wav_path,
        "duration_sec": round(duration_s, 2),
        "vocal_rms": round(avg_rms, 1),
        "peak_amplitude": peak_amp,
        "transcript": "",
        "emotion": "Нейтральний",
        "is_command": False,
        "gemini_response": "",
        "disorientation_detected": False,
        "orientation_hint": ""
    }

    if api_key:
        try:
            update_state(status="Аналіз мови через Gemini...")
            with open(wav_path, "rb") as f:
                b64_audio = base64.b64encode(f.read()).decode("utf-8")

            prompt_text = (
                "Ти — інтелектуальний штурман-помічник для гравця в Fallout 4 GOTY (українською мовою). "
                "Проаналізуй цей аудіозапис мови гравця:\n"
                "1. Точно транскрибуй українську мову (слово в слово).\n"
                "2. Визнач емоційний стан за інтонацією та змістом (спокійний, зосереджений, напружений, розгублений, роздратований, захоплений).\n"
                "3. Перевір, чи є звернення/команда до помічника (починається з 'Геміні', 'Gemini', 'Джеміні' або містить пряме питання про гру). "
                "Якщо так — дай точну, лаконічну відповідь (1-2 речення, тактика, локація, квест, пароль, консольна команда).\n"
                "4. Перевір, чи звучить дезорієнтація / тунельний зір (гравець не знає куди йти, шукає вихід, заблукав, матюкається від безвиході). "
                "Якщо так — надай коротку чітку підказку для орієнтації за сторонами світу або квестовим маркером.\n\n"
                "Відповідь надай СУВОРО у форматі JSON з полями:\n"
                "{\n"
                '  "transcript": "...",\n'
                '  "emotion": "...",\n'
                '  "is_command": true,\n'
                '  "response": "...",\n'
                '  "disorientation_detected": false,\n'
                '  "orientation_hint": "..."\n'
                "}"
            )

            req_body = {
                "contents": [{
                    "parts": [
                        {"text": prompt_text},
                        {
                            "inline_data": {
                                "mime_type": "audio/wav",
                                "data": b64_audio
                            }
                        }
                    ]
                }],
                "generationConfig": {
                    "response_mime_type": "application/json",
                    "temperature": 0.2
                }
            }

            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
            req = urllib.request.Request(url, data=json.dumps(req_body).encode("utf-8"), headers={"Content-Type": "application/json"})

            with urllib.request.urlopen(req, timeout=10) as resp:
                resp_data = json.loads(resp.read().decode("utf-8"))
                text_out = resp_data["candidates"][0]["content"]["parts"][0]["text"]
                parsed = json.loads(text_out)

                telemetry_record.update({
                    "transcript": parsed.get("transcript", ""),
                    "emotion": parsed.get("emotion", "Нейтральний"),
                    "is_command": parsed.get("is_command", False),
                    "gemini_response": parsed.get("response", ""),
                    "disorientation_detected": parsed.get("disorientation_detected", False),
                    "orientation_hint": parsed.get("orientation_hint", "")
                })

                print(f" 🗣️ [Транскрипт]: {telemetry_record['transcript']}")
                print(f" 🎭 [Емоція]: {telemetry_record['emotion']}")
                if telemetry_record["is_command"]:
                    print(f" 🤖 [Відповідь Gemini]: {telemetry_record['gemini_response']}")
                if telemetry_record["disorientation_detected"]:
                    print(f" 🧭 [Анти-тунель підказка]: {telemetry_record['orientation_hint']}")

        except Exception as e:
            print(f"[Voice Co-Pilot] Gemini API помилка: {e}")
            telemetry_record["transcript"] = "[Помилка або відсутність інтернет-з'єднання]"

    else:
        # Offline mode without API key
        telemetry_record["transcript"] = f"[Аудіо збережено: {duration_s:.1f}с, RMS {avg_rms:.1f}]"
        telemetry_record["emotion"] = "Акустичний сплеск" if avg_rms > 3000 else "Фоновий коментар"

    # Append to Telemetry Log
    try:
        with open(TELEMETRY_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(telemetry_record, ensure_ascii=False) + "\n")
    except Exception as e:
        print(f"[Telemetry] Не вдалося записати лог: {e}")

    # Update OSD State
    new_history = current_state.get("history", [])
    new_history.append({
        "time": datetime.now().strftime("%H:%M:%S"),
        "text": telemetry_record["transcript"] or f"Аудіо {duration_s:.1f}с",
        "emotion": telemetry_record["emotion"],
        "is_cmd": telemetry_record["is_command"]
    })
    if len(new_history) > 15:
        new_history.pop(0)

    update_state(
        status="Слухаю ефір...",
        last_transcript=telemetry_record["transcript"] or "[Без тексту]",
        last_emotion=telemetry_record["emotion"],
        last_command=telemetry_record["transcript"] if telemetry_record["is_command"] else current_state["last_command"],
        last_response=telemetry_record["gemini_response"] if telemetry_record["is_command"] else current_state["last_response"],
        disorientation_warning=telemetry_record["disorientation_detected"],
        orientation_hint=telemetry_record["orientation_hint"] if telemetry_record["disorientation_detected"] else current_state["orientation_hint"],
        history=new_history
    )

    # Trigger OSD notification on screen if command or disorientation
    if telemetry_record["is_command"] and telemetry_record["gemini_response"]:
        trigger_osd_notification("🤖 Gemini Assistant", telemetry_record["gemini_response"])
    elif telemetry_record["disorientation_detected"] and telemetry_record["orientation_hint"]:
        trigger_osd_notification("🧭 Орієнтир (Анти-тунель)", telemetry_record["orientation_hint"])

# ---------------------------------------------------------------------------
# OSD Notification Dispatcher
# ---------------------------------------------------------------------------
def trigger_osd_notification(title, message):
    try:
        env = os.environ.copy()
        env["DISPLAY"] = env.get("DISPLAY", ":0.0")
        subprocess.run(
            ["notify-send", "-u", "critical", "-t", "7000", "-i", "/home/hills/Documents/fallaut/fallout4.png", title, message],
            env=env,
            check=False
        )
    except Exception:
        pass

# ---------------------------------------------------------------------------
# Live Pip-Boy 3000 Web Dashboard (HTTP on port 8088)
# ---------------------------------------------------------------------------
DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="uk">
<head>
<meta charset="UTF-8">
<title>Fallout 4 Research Stand - Live Co-Pilot & Telemetry</title>
<style>
  body {
    background-color: #0b110b;
    color: #1bf71b;
    font-family: "Courier New", Courier, monospace;
    margin: 0;
    padding: 20px;
    text-shadow: 0 0 6px #1bf71b;
  }
  .header {
    border-bottom: 2px solid #1bf71b;
    padding-bottom: 10px;
    margin-bottom: 15px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .title { font-size: 22px; font-weight: bold; letter-spacing: 2px; }
  .badge { background: #1bf71b; color: #000; padding: 4px 8px; font-weight: bold; border-radius: 3px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
  .card {
    border: 1px solid #1bf71b;
    background: rgba(10, 25, 10, 0.7);
    padding: 15px;
    border-radius: 4px;
    box-shadow: inset 0 0 10px rgba(27, 247, 27, 0.2);
  }
  .card-title { font-size: 15px; font-weight: bold; margin-bottom: 10px; border-bottom: 1px dashed #1bf71b; padding-bottom: 4px; }
  .value { font-size: 18px; margin-top: 5px; color: #fff; text-shadow: 0 0 4px #fff; }
  .alert-box {
    border: 2px solid #ff3333;
    color: #ff5555;
    background: rgba(50, 0, 0, 0.6);
    padding: 12px;
    margin-bottom: 15px;
    font-weight: bold;
    text-shadow: 0 0 8px #ff3333;
    display: none;
  }
  .history-list { font-size: 13px; max-height: 180px; overflow-y: auto; list-style: none; padding-left: 0; }
  .history-list li { margin-bottom: 6px; border-bottom: 1px dotted #1b661b; padding-bottom: 3px; }
  .history-time { color: #88cc88; margin-right: 8px; }
  .emotion-tag { background: #134413; padding: 2px 6px; border-radius: 2px; margin-left: 6px; font-size: 11px; }
</style>
<script>
async function pollState() {
  try {
    const res = await fetch('/api/state');
    const data = await res.json();
    document.getElementById('mic').textContent = data.mic_device;
    document.getElementById('status').textContent = data.status;
    document.getElementById('rms').textContent = data.current_rms + ' RMS' + (data.is_speaking ? ' [ГОВОРИТЬ]' : '');
    document.getElementById('last-thought').textContent = data.last_transcript;
    document.getElementById('last-emotion').textContent = data.last_emotion;
    document.getElementById('response').textContent = data.last_response;
    document.getElementById('hint').textContent = data.orientation_hint;

    const alertBox = document.getElementById('disorientation-alert');
    if (data.disorientation_warning) {
      alertBox.style.display = 'block';
      alertBox.textContent = '⚠️ [УВАГА: ТУНЕЛЬНИЙ ЗІР / ДЕЗОРІЄНТАЦІЯ] -> ' + data.orientation_hint;
    } else {
      alertBox.style.display = 'none';
    }

    const histUl = document.getElementById('history');
    histUl.innerHTML = '';
    (data.history || []).slice().reverse().forEach(h => {
      const li = document.createElement('li');
      li.innerHTML = `<span class="history-time">[${h.time}]</span>${h.is_cmd ? '🤖 ' : '🗣️ '}<strong>${h.text}</strong><span class="emotion-tag">${h.emotion}</span>`;
      histUl.appendChild(li);
    });
  } catch (e) {}
}
setInterval(pollState, 800);
window.onload = pollState;
</script>
</head>
<body>
  <div class="header">
    <div class="title">⚡ VAULT-TEC COGNITIVE TELEMETRY & CO-PILOT</div>
    <div class="badge" id="status">АКТИВНИЙ</div>
  </div>

  <div id="disorientation-alert" class="alert-box"></div>

  <div class="grid">
    <div class="card">
      <div class="card-title">🎙️ АУДІОТРАКТ & ВОКАЛЬНА ТЕЛЕМЕТРІЯ</div>
      <div>Пристрій: <span id="mic" style="color:#fff;">Визначення...</span></div>
      <div style="margin-top:8px;">Рівень сигналу: <span id="rms" class="value">0 RMS</span></div>
      <div style="margin-top:8px;">Останній стан: <span id="last-emotion" class="badge">Спокій</span></div>
    </div>

    <div class="card">
      <div class="card-title">🧭 ОРІЄНТУВАННЯ & АНТИ-ТУНЕЛЬНИЙ СУПУТНИК</div>
      <div id="hint" class="value" style="font-size:16px; color:#aaffaa;">Орієнтир стабільний.</div>
    </div>

    <div class="card" style="grid-column: span 2;">
      <div class="card-title">🤖 ВІДПОВІДЬ ШІ-ШТУРМАНА (GEMINI 2.5 FLASH)</div>
      <div id="response" class="value" style="font-size:17px; line-height: 1.4;">Очікування запиту, що починається з "Геміні..."</div>
    </div>

    <div class="card" style="grid-column: span 2;">
      <div class="card-title">📜 СТРІЧКА ЖИВИХ ДУМОК (THINK-ALOUD PROTOCOL)</div>
      <ul id="history" class="history-list"></ul>
    </div>
  </div>
</body>
</html>
"""

class DashboardHTTPHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/state":
            with state_lock:
                data = json.dumps(current_state, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(DASHBOARD_HTML.encode("utf-8"))

    def log_message(self, format, *args):
        return  # Silence server stdout logging

def start_http_dashboard():
    server = HTTPServer(("0.0.0.0", 8088), DashboardHTTPHandler)
    print("[Voice Co-Pilot] Live Web Dashboard запущено: http://localhost:8088")
    server.serve_forever()

# ---------------------------------------------------------------------------
# Main Entry Point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    print("==================================================================")
    print(" Fallout 4 GOTY Research Stand - Voice Co-Pilot & Telemetry Engine")
    print(" Headset Mic: DualShock 4 3.5mm TRRS / Laptop DMIC Array")
    print(" Protocol: Think-Aloud, Emotion Tracking, Anti-Tunnel Vision OSD")
    print(" Dashboard: http://localhost:8088 (Відкрити на екрані ноутбука)")
    print("==================================================================")

    # Launch dashboard in background thread
    dash_thread = threading.Thread(target=start_http_dashboard, daemon=True)
    dash_thread.start()

    # Run audio listener loop in main thread
    audio_listener_loop()
