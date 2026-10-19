#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Motorics Control Run Runner & Analyzer
--------------------------------------
Проведення стандартизованих контрольних прогонів мікромоторики (DualShock 4 250 Гц):
1. Активація високочастотного стрімінгу через кільцевий буфер footpad_mapper.py.
2. Проведення тесту під час геймплею (базовий спокій або динамічний бій).
3. Розрахунок наукових біомедичних метрик:
   - Індекс мікротремору прицілу (Aim Tremor Index, 8-12 Гц).
   - Психомоторна латентність (час реакції L1 -> R1).
   - Стабільність нульової зони та центрів стіків.
"""

import os
import sys
import time
import json
import math
import argparse
from datetime import datetime

STAND_DIR = os.path.dirname(os.path.abspath(__file__))
LIVE_STATE_FILE = os.path.join(STAND_DIR, "scratch/footpad_live.json")
CMD_FILE = os.path.join(STAND_DIR, "scratch/telemetry_record.cmd")
DEFAULT_SESSION_DIR = os.path.join(STAND_DIR, "screens/session")

def check_mapper_live(max_age_sec=5.0):
    if not os.path.exists(LIVE_STATE_FILE):
        return False, "Файл стану scratch/footpad_live.json не знайдено."
    try:
        with open(LIVE_STATE_FILE, "r", encoding="utf-8") as f:
            st = json.load(f)
        age = time.time() - st.get("updated_at", 0)
        if age > max_age_sec:
            return False, f"Сервіс footpad_mapper не оновлювався {age:.1f} сек (можливо зупинений)."
        if not st.get("has_ds4", False):
            return False, "DualShock 4 не підключено або не захоплено мапером."
        return True, st
    except Exception as e:
        return False, f"Помилка читання стану: {e}"

def start_recording(target_jsonl):
    cmd = {
        "action": "start",
        "output_file": target_jsonl,
        "timestamp": time.time()
    }
    with open(CMD_FILE, "w", encoding="utf-8") as f:
        json.dump(cmd, f)
    # Зачекати поки мапер прочитає команду
    for _ in range(15):
        if not os.path.exists(CMD_FILE):
            break
        time.sleep(0.1)

def stop_recording():
    cmd = {
        "action": "stop",
        "timestamp": time.time()
    }
    with open(CMD_FILE, "w", encoding="utf-8") as f:
        json.dump(cmd, f)
    for _ in range(15):
        if not os.path.exists(CMD_FILE):
            break
        time.sleep(0.1)

def analyze_telemetry(telemetry_file, mode, duration_sec):
    if not os.path.exists(telemetry_file):
        return None

    records = []
    with open(telemetry_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    records.append(json.loads(line))
                except Exception:
                    pass

    if not records:
        return None

    total_samples = len(records)
    actual_duration = records[-1]["timestamp"] - records[0]["timestamp"] if total_samples > 1 else duration_sec
    effective_hz = round(total_samples / actual_duration, 1) if actual_duration > 0 else 0

    # Тремор прицілу (aim_tremor_index)
    tremor_vals = [r.get("aim_tremor_index", 0.0) for r in records if "aim_tremor_index" in r]
    mean_tremor = round(sum(tremor_vals) / len(tremor_vals), 2) if tremor_vals else 0.0
    max_tremor = round(max(tremor_vals), 2) if tremor_vals else 0.0
    
    # Відхилення стіків у спокої (центр LX, LY, RX, RY)
    rx_vals = [r["right_stick"][0] for r in records if "right_stick" in r]
    ry_vals = [r["right_stick"][1] for r in records if "right_stick" in r]
    lx_vals = [r["left_stick"][0] for r in records if "left_stick" in r]
    ly_vals = [r["left_stick"][1] for r in records if "left_stick" in r]

    # Аналіз подій та психомоторної латентності
    events = [r for r in records if r.get("event")]
    aim_events = [r for r in events if "L1_Aim" in r["event"]]
    fire_events = [r for r in events if "R1_Fire" in r["event"]]

    # Латентність: затримка між L1_Aim (DOWN) та R1_Fire (DOWN)
    latencies = []
    for aim in aim_events:
        if "DOWN" in aim["event"]:
            aim_t = aim["timestamp"]
            # шукаємо найближчий постріл після прицілу в межах 2.5 сек
            fires = [f for f in fire_events if "DOWN" in f["event"] and 0 < (f["timestamp"] - aim_t) <= 2.5]
            if fires:
                latencies.append(round((fires[0]["timestamp"] - aim_t) * 1000, 1)) # мс

    mean_latency_ms = round(sum(latencies) / len(latencies), 1) if latencies else None

    summary = {
        "session_mode": mode,
        "recorded_at": datetime.now().isoformat(),
        "duration_sec": round(actual_duration, 2),
        "total_samples": total_samples,
        "effective_sampling_hz": effective_hz,
        "micro_motorics": {
            "mean_aim_tremor_index": mean_tremor,
            "peak_aim_tremor_index": max_tremor,
            "tremor_classification": (
                "Низький / Стан релаксації" if mean_tremor < 5.0 else
                "Помірний / Робоча концентрація" if mean_tremor < 15.0 else
                "Високий / Симпатичне напруження або втома"
            )
        },
        "psychomotor_latency": {
            "aim_to_fire_events_count": len(latencies),
            "mean_reaction_time_ms": mean_latency_ms,
            "min_reaction_time_ms": min(latencies) if latencies else None,
            "max_reaction_time_ms": max(latencies) if latencies else None
        },
        "event_counts": {
            "aim_l1_count": len([e for e in aim_events if "DOWN" in e["event"]]),
            "fire_r1_count": len([e for e in fire_events if "DOWN" in e["event"]]),
            "total_button_events": len(events)
        }
    }

    return summary

def main():
    parser = argparse.ArgumentParser(description="Контрольний прогін мікромоторики DualShock 4 у Fallout 4")
    parser.add_argument("--duration", type=int, default=60, help="Тривалість контрольного прогону в секундах (дефолт: 60)")
    parser.add_argument("--mode", choices=["calm", "combat"], default="calm", help="Режим тесту: 'calm' (спокій) або 'combat' (бій)")
    parser.add_argument("--output-dir", type=str, default=DEFAULT_SESSION_DIR, help="Каталог збереження результатів")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)
    telemetry_path = os.path.join(args.output_dir, "session_telemetry.jsonl")
    summary_path = os.path.join(args.output_dir, "session_summary.json")

    print("\n==================================================================")
    print("  СТЕНД FALLOUT 4: КОНТРОЛЬНИЙ ПРОГІН МІКРОМОТОРИКИ (250 Гц)")
    print(f"  Режим:      {'СПОКІЙ / БАЗОВА ЛІНІЯ' if args.mode == 'calm' else 'ДИНАМІЧНИЙ БІЙ / СТРЕС-ТЕСТ'}")
    print(f"  Тривалість: {args.duration} секунд")
    print(f"  Файл:       {telemetry_path}")
    print("==================================================================\n")

    # 1. Перевірка статусу мапера
    ok, st = check_mapper_live()
    if not ok:
        print(f"❌ ПОМИЛКА: {st}")
        print("Переконайтеся, що footpad_mapper.py запущено і контролер активний.")
        sys.exit(1)

    print("✅ footpad_mapper активний. Підключення до Ring Buffer встановлено.")
    print(f"   Поточний індекс тремору: {st.get('aim_tremor_index', 0.0)}")
    print(f"   Буфер семплів у RAM:     {st.get('buffer_len', 0)} / 1000")
    print("\n[Підготовка] 3... 2... 1... СТАРТ ЗАПИСУ!")

    # 2. Старт запису
    start_recording(telemetry_path)
    start_time = time.time()

    try:
        while True:
            elapsed = time.time() - start_time
            if elapsed >= args.duration:
                break
            
            rem = int(args.duration - elapsed)
            # Зчитуємо поточний live стан
            _, cur_st = check_mapper_live()
            cur_tremor = cur_st.get("aim_tremor_index", 0.0) if isinstance(cur_st, dict) else 0.0
            
            # Прогрес-бар
            bar_len = 25
            filled = int(bar_len * (elapsed / args.duration))
            bar = "█" * filled + "░" * (bar_len - filled)
            
            sys.stdout.write(f"\r  [{bar}] {rem:02d}с | Тремор прицілу: {cur_tremor:5.2f} | Запис триває... ")
            sys.stdout.flush()
            time.sleep(0.5)

    except KeyboardInterrupt:
        print("\n\n⚠️ Прогін перервано користувачем.")

    finally:
        # 3. Зупинка запису
        stop_recording()
        time.sleep(0.5)
        print("\n\n⏹️ Запис завершено. Обробка та спектральний аналіз даних...")

    # 4. Аналіз та формування звіту
    summary = analyze_telemetry(telemetry_path, args.mode, args.duration)
    if not summary:
        print("❌ Не вдалося зчитати записи телеметрії.")
        sys.exit(1)

    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    print("\n==================================================================")
    print("  ЗВІТ КОНТРОЛЬНОГО ПРОГОНУ МІКРОМОТОРИКИ")
    print("==================================================================")
    print(f"  • Тривалість запису:          {summary['duration_sec']} сек")
    print(f"  • Всього зібрано семплів:     {summary['total_samples']} (Ефективна частота: {summary['effective_sampling_hz']} Гц)")
    print(f"  • Середній тремор прицілу:    {summary['micro_motorics']['mean_aim_tremor_index']}")
    print(f"  • Піковий сплеск тремору:     {summary['micro_motorics']['peak_aim_tremor_index']}")
    print(f"  • Класифікація стану:         {summary['micro_motorics']['tremor_classification']}")
    
    lat = summary["psychomotor_latency"]
    if lat["mean_reaction_time_ms"]:
        print(f"  • Психомоторна реакція L1->R1: {lat['mean_reaction_time_ms']} мс (мінімум: {lat['min_reaction_time_ms']} мс)")
    else:
        print(f"  • Психомоторна реакція L1->R1: Не зафіксовано парних циклів приціл-постріл")

    print(f"  • Зафіксовано подій кнопок:   {summary['event_counts']['total_button_events']}")
    print(f"  • Повний звіт збережено в:    {summary_path}")
    print("==================================================================\n")

if __name__ == "__main__":
    main()
