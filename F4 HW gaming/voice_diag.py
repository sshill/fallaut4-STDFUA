#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Zone Vibe 100 Voice Diagnostics & Ollama Evaluation Tool
--------------------------------------------------------
Єдиний консолідований діагностичний файл для перевірки голосового тракту:
1. Перевірка статусу Bluetooth гарнітури Zone Vibe 100 та переведення в режим HFP.
2. Тестовий запис 4 секунд голосу з мікрофона Zone Vibe 100.
3. Локальна офлайн-транскрипція українською через Vosk Nano.
4. Структурний аналіз репліки моделлю Ollama (qwen2.5-coder:1.5b на E-ядрах).
5. Вивід підсумкової діагностичної картки.
"""

import os
import sys
import time
import math
import wave
import json
import struct
import argparse
import subprocess
import urllib.request
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VENV_SITE = os.path.join(BASE_DIR, ".venv/lib/python3.13/site-packages")
if os.path.exists(VENV_SITE) and VENV_SITE not in sys.path:
    sys.path.insert(0, VENV_SITE)

SCRATCH_DIR = os.path.join(BASE_DIR, "scratch")
VOSK_DIR = os.path.join(BASE_DIR, "models/vosk-model-small-uk-v3-nano")
TEST_WAV = "/tmp/voice_test_diag.wav"

MAC_ADDR = "94:02:30:01:07:1C"
CARD_NAME = f"bluez_card.{MAC_ADDR.replace(':', '_')}"
SOURCE_NAME = f"bluez_source.{MAC_ADDR.replace(':', '_')}.handsfree_head_unit"
SINK_NAME = f"bluez_sink.{MAC_ADDR.replace(':', '_')}.handsfree_head_unit"
OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL_NAME = "qwen2.5-coder:1.5b"

def ensure_audio_profile():
    """Перевіряє та за потреби перемикає Zone Vibe 100 на профіль HFP."""
    try:
        out = subprocess.run(["pactl", "list", "cards"], capture_output=True, text=True, timeout=3).stdout
        if CARD_NAME in out:
            if "Active Profile: handsfree_head_unit" not in out:
                subprocess.run(["pactl", "set-card-profile", CARD_NAME, "handsfree_head_unit"], capture_output=True, timeout=3)
                time.sleep(1)
            subprocess.run(["pactl", "set-source-volume", SOURCE_NAME, "100%"], capture_output=True, timeout=2)
            subprocess.run(["pactl", "set-source-mute", SOURCE_NAME, "0"], capture_output=True, timeout=2)
            return True
    except Exception:
        pass
    return False

def record_mic_sample(duration_sec=4):
    """Записує аудіо з мікрофона Zone Vibe 100."""
    chunk_samples = 1600
    chunk_bytes = chunk_samples * 2
    cmd = [
        "parec",
        f"--device={SOURCE_NAME}",
        "--channels=1",
        "--rate=16000",
        "--format=s16le"
    ]
    raw_bytes = bytearray()
    t_end = time.time() + duration_sec

    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        while time.time() < t_end:
            chunk = proc.stdout.read(chunk_bytes)
            if not chunk:
                break
            raw_bytes.extend(chunk)
        proc.terminate()
        try: proc.wait(timeout=1)
        except Exception: proc.kill()
    except Exception as e:
        return None, 0, 0, str(e)

    pcm_data = bytes(raw_bytes)
    n_samples = len(pcm_data) // 2
    if n_samples == 0:
        return None, 0, 0, "Записано 0 байт"

    samples = struct.unpack(f"<{n_samples}h", pcm_data)
    peak = max(abs(s) for s in samples)
    rms = math.sqrt(sum(s*s for s in samples) / n_samples)

    try:
        with wave.open(TEST_WAV, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(16000)
            w.writeframes(pcm_data)
    except Exception:
        pass

    return pcm_data, rms, peak, None

def transcribe_sample(pcm_data):
    """Розпізнає аудіо українською мовою через Vosk Nano."""
    if not os.path.exists(VOSK_DIR):
        return "", "Модель Vosk не знайдена за шляхом: " + VOSK_DIR

    try:
        import vosk
        vosk.SetLogLevel(-1)
        model = vosk.Model(VOSK_DIR)
        rec = vosk.KaldiRecognizer(model, 16000)
        rec.SetWords(False)
        text_parts = []
        chunk_size = 4000
        for i in range(0, len(pcm_data), chunk_size):
            chunk = pcm_data[i:i + chunk_size]
            if rec.AcceptWaveform(chunk):
                res = json.loads(rec.Result())
                if res.get("text"):
                    text_parts.append(res["text"])
        res = json.loads(rec.FinalResult())
        if res.get("text"):
            text_parts.append(res["text"])
        text = " ".join(text_parts).strip()
        return text, None
    except Exception as e:
        return "", str(e)

def analyze_with_ollama(text):
    """Аналізує текст моделлю Ollama qwen2.5-coder:1.5b."""
    if not text:
        return "Не розпізнано слів або тиша в мікрофоні.", 0

    prompt = (
        f"<|im_start|>system\n"
        f"Ти — тактичний копілот гри Fallout 4. Класифікуй репліку гравця та дай коротку пораду (суворо 1 речення українською мовою).\n"
        f"Приклади:\n"
        f"Репліка: \"треба збудувати генератор і турель у Сенкчуарі\"\n"
        f"Відповідь: [NOTE] Зафіксовано нотатку для поселення: перевірте наявність міді та шестерень.\n"
        f"Репліка: \"набої для дробовика закінчилися лікуйся\"\n"
        f"Відповідь: [TACTICAL] Перемкніться на карабін або пістолет та застосуйте стимулятор.\n"
        f"<|im_end|>\n"
        f"<|im_start|>user\n"
        f"Репліка: \"{text}\"\n"
        f"<|im_end|>\n"
        f"<|im_start|>assistant\n"
    )

    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "options": {
            "num_thread": 2,
            "num_ctx": 384,
            "num_predict": 50,
            "temperature": 0.1,
            "stop": ["<|im_end|>", "\n"]
        }
    }

    t0 = time.time()
    try:
        req = urllib.request.Request(
            OLLAMA_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        dt_ms = int((time.time() - t0) * 1000)
        return data.get("response", "").strip(), dt_ms
    except Exception as e:
        return f"Помилка Ollama: {e}", int((time.time() - t0) * 1000)

def main():
    parser = argparse.ArgumentParser(description="Zone Vibe 100 & Ollama Voice Diagnostic")
    parser.add_argument("--simulate", type=str, default=None, help="Тест Ollama з готовим текстом без запису")
    parser.add_argument("--seconds", type=int, default=5, help="Тривалість запису мікрофона в секундах")
    args = parser.parse_args()

    # Зниження пріоритету (nice +19)
    try: os.nice(19)
    except Exception: pass

    now_str = datetime.now().strftime("%H:%M:%S")

    # Якщо симуляція тексту:
    if args.simulate:
        print(f"Тест аналізу Ollama для тексту: «{args.simulate}»...")
        resp, ms = analyze_with_ollama(args.simulate)
        print(f"[{ms} мс] Відповідь Ollama: {resp}")
        return

    # Перевірка профілю гарнітури
    is_hfp = ensure_audio_profile()

    print("┌" + "─" * 68 + "┐")
    print(f"│  ZONE VIBE 100 & OLLAMA ГОЛОСОВА ДІАГНОСТИКА       [{now_str}]  │")
    print("├" + "─" * 68 + "┤")
    print(f"│  Гарнітура:       Zone Vibe 100 ({MAC_ADDR})                     │")
    print(f"│  Профіль звуку:   {'handsfree_head_unit (HFP, 16 кГц)' if is_hfp else 'Помилка активації HFP':<40} │")
    print(f"│  Мікрофон:        Ніжка мікрофона має бути ОПУЩЕНА вниз (Mute Off) │")
    print("├" + "─" * 68 + "┤")
    print(f"│  🎤 ЗАПИС ГОЛОСУ ({args.seconds} сек)... ГОВОРІТЬ У МІКРОФОН ГАРНІТУРИ          │")
    print("└" + "─" * 68 + "┘")

    print("⏳ Приготуйтеся: сигнал старту пролунає в навушниках через 2 секунди...", flush=True)
    time.sleep(2)

    # Сигнал готовності в гарнітуру перед стартом
    ready_wav = os.path.join(SCRATCH_DIR, "chime_ready.wav")
    note_wav = os.path.join(SCRATCH_DIR, "chime_note.wav")
    try:
        subprocess.run(["paplay", f"--device={SINK_NAME}", ready_wav], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    print(f"🔴 ЗАРАЗ ГОВОРІТЬ У МІКРОФОН ZONE VIBE 100 ({args.seconds} сек)...", flush=True)
    pcm, rms, peak, err = record_mic_sample(duration_sec=args.seconds)
    if err:
        print(f"❌ Помилка запису: {err}")
        sys.exit(1)

    # Сигнал завершення запису
    try:
        subprocess.run(["paplay", f"--device={SINK_NAME}", note_wav], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # Транскрипція
    t_stt_0 = time.time()
    text, stt_err = transcribe_sample(pcm)
    stt_ms = int((time.time() - t_stt_0) * 1000)

    # Ollama
    analysis, ollama_ms = analyze_with_ollama(text)

    print("\n┌" + "─" * 68 + "┐")
    print("│                     РЕЗУЛЬТАТ ОБРОБКИ ГОЛОСУ                       │")
    print("├" + "─" * 68 + "┤")
    print(f"│  Акустика сигналу: RMS: {rms:.1f} / 32768, Пік: {peak:<29} │")
    print(f"│  Vosk Nano STT:   Затримка: {stt_ms} мс                                   │")
    print(f"│  Розпізнаний текст:                                                │")
    text_display = f"«{text}»" if text else "(Тиша або занизький рівень звуку)"
    print(f"│    {text_display:<64}│")
    print("├" + "─" * 68 + "┤")
    print(f"│  🤖 OLLAMA ({MODEL_NAME}, 2xE-cores, {ollama_ms} мс):                         │")
    if len(analysis) > 64:
        print(f"│    {analysis[:64]}│")
        print(f"│    {analysis[64:128]:<64}│")
    else:
        print(f"│    {analysis:<64}│")
    print("└" + "─" * 68 + "┘")

if __name__ == "__main__":
    main()
