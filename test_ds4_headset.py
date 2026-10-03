#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DualShock 4 + 3.5mm Headset Hardware Loopback Tester (v2)
=========================================================
- Plays audio beeps for Start/Stop so the user knows EXACTLY when to speak.
- Converts recorded voice to DualShock 4 native 48kHz Stereo with dynamic boost.
- Plays your voice back into the headset with crystal clarity.
"""

import sys
import time
import math
import wave
import struct
import subprocess

PLAY_DEV = "plughw:CARD=Controller,DEV=0"
REC_DEV = "plughw:CARD=Controller,DEV=0"

def play_beep(freq, duration_s=0.25, volume=20000):
    sample_rate = 48000
    n_samples = int(sample_rate * duration_s)
    path = "/tmp/ds4_beep.wav"
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        data = bytearray()
        for i in range(n_samples):
            t = i / sample_rate
            env = math.sin(math.pi * (i / n_samples)) # Smooth envelope
            val = int(env * volume * math.sin(2 * math.pi * freq * t))
            data.extend(struct.pack("<hh", val, val))
        f.writeframes(data)
    subprocess.run(["aplay", "-D", PLAY_DEV, path], capture_output=True)

def run_test():
    print("================================================================")
    print(" 🎧 ТЕСТ ГАРНІТУРИ DUALSHOCK 4 (ЗІ ЗВУКОВИМИ ПІДКАЗКАМИ)")
    print("================================================================")

    # 1. Start chime
    print("\n1. Грає початковий тестовий акорд у навушниках...")
    play_beep(523.25, 0.2)
    play_beep(659.25, 0.2)
    play_beep(783.99, 0.3)
    time.sleep(0.5)

    # 2. Beep prompt to speak
    print("\n----------------------------------------------------------------")
    print(" 🔊 УВАГА! Зараз пролунає високий сигнал 'БІП'!")
    print(" >>> ОДРАЗУ ПІСЛЯ СИГНАЛУ ГОВОРІТЬ У МІКРОФОН (є 4 секунди) <<<")
    print("----------------------------------------------------------------")
    time.sleep(0.5)
    
    # High start beep
    play_beep(1200.0, 0.35, 22000)

    # 3. Record 4 seconds
    wav_raw = "/tmp/ds4_raw_mic.wav"
    print("🎙️ [ЗАПИС ІДЕ...] Говоріть зараз: 'Тест мікрофона, чую добре!'")
    cmd = ["arecord", "-D", REC_DEV, "-d", "4", "-f", "S16_LE", "-r", "16000", "-c", "1", wav_raw]
    subprocess.run(cmd, capture_output=True)

    # Stop beep
    play_beep(600.0, 0.15, 18000)
    play_beep(400.0, 0.2, 18000)
    print("⏹️ [ЗАПИС ЗУПИНЕНО!]")

    # 4. Process and analyze audio
    with wave.open(wav_raw, "rb") as r:
        nframes = r.getnframes()
        data = r.readframes(nframes)
        samples = struct.unpack(f"<{nframes}h", data) if nframes else []

    if not samples:
        print("❌ Помилка: звук не записано.")
        return

    peak = max(abs(s) for s in samples)
    rms = math.sqrt(sum(s * s for s in samples) / len(samples))
    bars = int(min(rms / 250, 30))
    print(f"\n📊 Рівень гучності: [{'█' * bars}{'░' * (30 - bars)}] (RMS: {rms:.1f}, Пік: {peak})")

    # Gain boost if quiet
    gain = 1.0
    if peak > 0 and peak < 16000:
        gain = min(16000 / peak, 3.5)

    # Convert 16kHz Mono -> 48kHz Stereo for native DS4 DAC
    wav_stereo = "/tmp/ds4_user_voice_48k.wav"
    stereo_data = bytearray()
    for s in samples:
        val = int(max(-32767, min(32767, s * gain)))
        frame = struct.pack("<hh", val, val)
        stereo_data.extend(frame * 3) # 16k -> 48k

    with wave.open(wav_stereo, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(48000)
        w.writeframes(stereo_data)

    # 5. Playback
    print(f"\n🔁 СЛУХАЙТЕ В НАВУШНИКАХ: Відтворення вашого голосу (підсилення x{gain:.1f})...")
    subprocess.run(["aplay", "-D", PLAY_DEV, wav_stereo], capture_output=True)
    print("✅ Відтворення завершено!")
    print("================================================================")

if __name__ == "__main__":
    run_test()
