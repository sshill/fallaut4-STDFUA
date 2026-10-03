#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Multi-Microphone Diagnostic Probe
=================================
Simultaneously records 3 seconds from:
1. DualShock 4 3.5mm Headset Jack
2. Laptop Built-in DMIC Array
3. Laptop 3.5mm Combo Jack
Shows live peak and RMS for each to find where your voice is coming in!
"""

import sys
import time
import math
import wave
import struct
import subprocess

DEVICES = [
    ("DualShock 4 (3.5mm Jack)", "plughw:CARD=Controller,DEV=0"),
    ("Ноутбук (Вбудований DMIC)", "plughw:CARD=sofhdadsp,DEV=6"),
    ("Ноутбук (Роз'єм 3.5 мм)", "plughw:CARD=sofhdadsp,DEV=0")
]

print("================================================================")
print(" 🔍 ДІАГНОСТИКА МІКРОФОНІВ: ПОШУК АКТИВНОГО СИГНАЛУ")
print("================================================================")
print(" Зараз розпочнеться 3-секундний запис з усіх входів одночасно.")
print(" >>> ПОСТУКАЙТЕ ПО МІКРОФОНУ АБО СКАЖІТЬ ГУЧНО: 'РАЗ, ДВА, ТРИ!' <<<")
print("================================================================")
time.sleep(0.5)

procs = []
paths = []

for name, dev in DEVICES:
    path = f"/tmp/probe_{dev.replace(':', '_').replace('=', '_').replace(',', '_')}.wav"
    paths.append((name, dev, path))
    cmd = ["arecord", "-D", dev, "-d", "3", "-f", "S16_LE", "-r", "16000", "-c", "1", path]
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    procs.append(p)

for p in procs:
    p.wait()

print("\n📊 РЕЗУЛЬТАТИ ВЛОВЛЮВАННЯ ЗВУКУ:")
print("-" * 64)

for name, dev, path in paths:
    try:
        with wave.open(path, "rb") as w:
            n = w.getnframes()
            data = w.readframes(n)
            samples = struct.unpack(f"<{len(data)//2}h", data) if n else []
            rms = math.sqrt(sum(s*s for s in samples)/len(samples)) if samples else 0
            peak = max(abs(s) for s in samples) if samples else 0
            bars = int(min(rms / 150, 20))
            meter = "█" * bars + "░" * (20 - bars)
            status = "✅ ЗВУК Є!" if peak > 1500 else "❌ ТИША (немає сигналу)"
            print(f" {name:<26} | [{meter}] RMS: {rms:5.1f} | Пік: {peak:5d} -> {status}")
    except Exception as e:
        print(f" {name:<26} | Помилка: {e}")

print("-" * 64)
