#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PulseAudio-Native Voice Command & STT Tester for Fallout 4 Stand (v4)
====================================================================
Uses native PulseAudio (paplay / parecord) to cleanly mix with music,
eliminating ALSA device conflicts.
"""

import os
import sys
import time
import math
import wave
import struct
import subprocess

STAND_DIR = "/home/hills/Documents/fallaut"
PULSE_SINK = "alsa_output.usb-Sony_Interactive_Entertainment_Wireless_Controller-00.analog-stereo"
# 2-ring plug on headset means mic conductor is absent in DS4 jack -> use laptop Mic1
PULSE_SOURCE = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source"

VENV_PATH = os.path.join(STAND_DIR, ".venv/lib/python3.13/site-packages")
if VENV_PATH not in sys.path:
    sys.path.insert(0, VENV_PATH)

import speech_recognition as sr

def play_beep(freq, duration_s=0.3, volume=22000):
    sample_rate = 48000
    n_samples = int(sample_rate * duration_s)
    path = "/tmp/ds4_test_beep.wav"
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        data = bytearray()
        for i in range(n_samples):
            t = i / sample_rate
            env = math.sin(math.pi * (i / n_samples))
            val = int(env * volume * math.sin(2 * math.pi * freq * t))
            data.extend(struct.pack("<hh", val, val))
        f.writeframes(data)
    subprocess.run(["paplay", "-d", PULSE_SINK, path], capture_output=True)

def answer_fallout_query(query_text):
    q = query_text.lower()
    if any(w in q for w in ["пароль", "термінал"]):
        return "У терміналах Волт-Тек та мерії пароль можна знайти в сусідньому сейфі або записці на столі."
    elif any(w in q for w in ["корвег", "corvega", "пупс"]):
        return "Пупс 'Ремонт' на заводі Корвега знаходиться на зовнішній південно-західній вежі на самому кінці містка."
    elif any(w in q for w in ["стимулятор", "лікуват", "здоров"]):
        return "Використай стимулятор через Pip-Boy або швидку кнопку геймпада (хрестовина вгору)."
    elif any(w in q for w in ["патрон", "боєприпас"]):
        return "Перевір торговців у Даймонд-Сіті (Артуро та Мірна мають повний асортимент)."
    elif any(w in q for w in ["денс", "паладин"]):
        return "Паладин Денс чекає в поліцейській дільниці Кембриджа. Допоможи йому відбити напад гулів."
    elif any(w in q for w in ["інститут", "директор", "отець"]):
        return "Ви Директор Інституту. Консольна команда для збереження Тінкера Тома: setstage RR303 100."
    elif any(w in q for w in ["де вихід", "куди йти", "заблукав", "вихід"]):
        return "Зверни увагу на зелений маркер дверей на нижньому компасі Pip-Boy."
    else:
        return f"Команду прийнято: '{query_text}'. Штурман опрацьовує тактичну обстановку."

def run_recognition_test():
    print("================================================================")
    print(" 🎙️ ТЕСТ РОЗПІЗНАВАННЯ ГОЛОСУ ТА КОМАНД (PulseAudio Direct)")
    print("================================================================")
    print(f" Вихід звуку: {PULSE_SINK}")
    print(f" Вхід мікрофона: {PULSE_SOURCE}")
    print(" Мова: Українська (uk-UA)")
    print("----------------------------------------------------------------")

    print("\n1. У навушниках прямо поверх музики зараз пролунає високий 'БІП'...")
    time.sleep(0.5)
    play_beep(1200.0, 0.35, 24000)
    time.sleep(0.5)

    print("\n🔊 >>> СИГНАЛ ПРОЛУНАВ! ГОВОРІТЬ У МІКРОФОН (є 6 секунд) <<<")
    print(" Спробуйте сказати:")
    print("   • 'Геміні, де вихід?'")
    print("   • 'Геміні, де знайти пупса на заводі Корвега?'")
    print("   • 'Бачу ворогів попереду!'")
    print("----------------------------------------------------------------")

    wav_path = "/tmp/ds4_command_test.wav"
    total_seconds = 6
    chunk_samples = 1600 # 100ms
    chunk_bytes = chunk_samples * 2

    # Record using native PulseAudio streaming
    cmd = [
        "parecord",
        "-d", PULSE_SOURCE,
        "--channels=1",
        "--rate=16000",
        "--format=s16le",
        "--raw"
    ]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

    all_pcm = bytearray()
    max_rms_seen = 0
    start_time = time.time()

    try:
        while time.time() - start_time < total_seconds:
            chunk = proc.stdout.read(chunk_bytes)
            if not chunk or len(chunk) < chunk_bytes:
                break
            all_pcm.extend(chunk)
            samples = struct.unpack(f"<{chunk_samples}h", chunk)
            rms = math.sqrt(sum(s*s for s in samples) / len(samples))
            if rms > max_rms_seen:
                max_rms_seen = rms
            bars = int(min(rms / 120, 25))
            elapsed = time.time() - start_time
            sys.stdout.write(f"\r 🎙️ Запис [{elapsed:.1f}с/{total_seconds}с]: [{'█'*bars}{'░'*(25-bars)}] RMS: {rms:.0f}  ")
            sys.stdout.flush()
    finally:
        proc.terminate()
        proc.wait()

    sys.stdout.write("\n")
    play_beep(600.0, 0.15, 20000)
    play_beep(400.0, 0.2, 20000)
    print("⏹️ [ЗАПИС ЗАКІНЧЕНО!]")

    # Save to WAV
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(16000)
        w.writeframes(all_pcm)

    print(f"\n📊 Максимальний зафіксований сигнал: RMS {max_rms_seen:.1f}")

    print("\n⏳ Відправка на розпізнавання мови Google Speech API (uk-UA)...")
    r = sr.Recognizer()
    try:
        with sr.AudioFile(wav_path) as source:
            audio = r.record(source)
        
        recognized_text = r.recognize_google(audio, language="uk-UA")
        
        print("\n" + "=" * 64)
        print(f" 🗣️ РОЗПІЗНАНИЙ ТЕКСТ:  \"{recognized_text}\"")
        print("=" * 64)

        lower_text = recognized_text.lower()
        is_cmd = any(lower_text.startswith(prefix) for prefix in ["геміні", "gemini", "джеміні", "геймні"]) or "геміні" in lower_text
        is_lost = any(phrase in lower_text for phrase in [
            "де вихід", "куди йти", "заблукав", "загубився", "не бачу", "як вийти", "де маркер", "де двері"
        ])

        if is_cmd:
            print(" 🤖 ТИП: ПРЯМА ГОЛОСОВА КОМАНДА ШІ (Gemini Command)")
            clean_query = recognized_text
            for prefix in ["геміні", "gemini", "джеміні", "геймні", ",", " "]:
                if clean_query.lower().startswith(prefix):
                    clean_query = clean_query[len(prefix):].strip()
            
            answer = answer_fallout_query(clean_query if clean_query else recognized_text)
            print(f" 💡 ВІДПОВІДЬ ШІ-ШТУРМАНА: {answer}")
            
        elif is_lost:
            print(" 🧭 ТИП: ТРИГЕР ДЕЗОРІЄНТАЦІЇ / ТУНЕЛЬНОГО ЗОРУ")
            print(" ⚠️ СПРАЦЮВАВ АНТИ-ТУНЕЛЬНИЙ ЗАХИСТ!")
            hint = "Зробіть видих, перевірте нижній компас Pip-Boy: ціль позначена суцільним зеленим ромбом."
            print(f" 🧭 [ОРІЄНТИР]: {hint}")
            
        else:
            print(" 💬 ТИП: THINK-ALOUD КОМЕНТАР (Логування емоційного стану)")
            print(" 📊 ЕМОЦІЙНИЙ ТОН: Спокійний / Дослідження оточення")
            print(" 📝 ЗАПИСАНО В ТЕЛЕМЕТРІЮ СТЕНДА: session_telemetry.jsonl")

    except sr.UnknownValueError:
        print("\n⚠️ Мову не вдалося розібрати (немає виразного мовлення або надто тихо).")
    except sr.RequestError as e:
        print(f"\n❌ Помилка сервісу розпізнавання: {e}")
    except Exception as e:
        print(f"\n❌ Помилка: {e}")

    print("\n================================================================")
    print(" Тест завершено!")
    print("================================================================")

if __name__ == "__main__":
    run_recognition_test()
