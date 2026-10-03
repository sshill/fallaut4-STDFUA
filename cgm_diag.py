#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LinX CGM Consolidated Diagnostic Tool & Ollama Edge Assessor
------------------------------------------------------------
Єдиний консолідований файл повної діагностики для Antigravity ("Always Allow").
Виконує повний цикл:
1. Перевірка та авто-підключення Wi-Fi ADB (192.168.0.122:5555).
2. Зчитування живого зрізу сенсора (UI віджет + декомпресія Mars Xlog).
3. Розрахунок темпу зміни dG/dt та вегетативного статусу HPA-осі.
4. Оновлення scratch/cgm_live.json.
5. Локальний інференс Ollama (qwen2.5-coder:1.5b на 2 E-ядрах).
6. Запис у scratch/edge_assessments.jsonl.
7. Відображення наочної діагностичної картини в терміналі.
"""

import os
import re
import sys
import time
import json
import zlib
import struct
import argparse
import subprocess
import urllib.request
import urllib.error
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SCRATCH_DIR = os.path.join(BASE_DIR, "scratch")
CGM_LIVE_PATH = os.path.join(SCRATCH_DIR, "cgm_live.json")
ASSESSMENTS_PATH = os.path.join(SCRATCH_DIR, "edge_assessments.jsonl")

WIFI_ENDPOINT = "192.168.0.122:5555"
TRANSMITTER_SN = "22222FUWDN"
TRANSMITTER_MAC = "40:38:02:E9:10:DE"
OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL_NAME = "qwen2.5-coder:1.5b"

def run_adb(cmd_args, device=WIFI_ENDPOINT, timeout=5, binary=False):
    full_cmd = ["adb", "-s", device] + cmd_args
    if binary:
        return subprocess.run(full_cmd, capture_output=True, timeout=timeout)
    return subprocess.run(full_cmd, capture_output=True, text=True, timeout=timeout)

def ensure_device_connected():
    try:
        res = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=3)
        if WIFI_ENDPOINT not in res.stdout or f"{WIFI_ENDPOINT}\tdevice" not in res.stdout:
            subprocess.run(["adb", "connect", WIFI_ENDPOINT], capture_output=True, text=True, timeout=3)
            res = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=3)
            if f"{WIFI_ENDPOINT}\tdevice" in res.stdout:
                return WIFI_ENDPOINT
        else:
            return WIFI_ENDPOINT
        
        # Fallback to any USB device
        lines = [line.strip().split() for line in res.stdout.strip().splitlines()[1:] if line.strip()]
        for dev, state in lines:
            if state == "device":
                return dev
    except Exception:
        pass
    return None

def decompress_xlog(data: bytes):
    offset = 0
    header_len = 73
    records = []
    data_len = len(data)
    while offset < data_len:
        if data[offset] != 0x09:
            offset += 1
            continue
        if offset + header_len > data_len:
            break
        length = struct.unpack_from('<I', data, offset + 5)[0]
        if length <= 0 or length > 65536 or offset + header_len + length > data_len:
            offset += 1
            continue
        chunk = bytes(data[offset + header_len : offset + header_len + length])
        try:
            dec = zlib.decompressobj(-zlib.MAX_WBITS)
            records.append(dec.decompress(chunk).decode('utf-8', errors='ignore'))
            offset += header_len + length + 1
        except Exception:
            offset += 1
    return records

def fetch_telemetry(device):
    t0 = time.time()
    res = {
        "status": "DISCONNECTED",
        "device": device,
        "glucose": None,
        "trend": "Unknown",
        "reading_time": "Невідомо",
        "dG_dt_1min": 0.0,
        "dG_dt_5min": 0.0,
        "hpa_status": "quiescent",
        "sensor_life": "",
        "highest": None,
        "lowest": None,
        "tir": None,
        "ble_packets": 0,
        "history_count": 0,
        "latency_ms": 0
    }

    if not device:
        return res

    res["status"] = "CONNECTED"

    # 1. Спроба зчитати живий екранний віджет (найактуальніше значення "Щойно")
    try:
        ui_raw = run_adb(["shell", "uiautomator dump /sdcard/linx_ui.xml >/dev/null 2>&1 && cat /sdcard/linx_ui.xml"], device=device, timeout=5).stdout
        def get_attr(res_id, attr="text"):
            m = re.search(rf'<node\b[^>]*\bresource-id=\"[^\"]*{res_id}\"[^>]*>', ui_raw)
            if m:
                am = re.search(rf'\b{attr}=\"([^\"]*)\"', m.group(0))
                if am:
                    return am.group(1).strip()
            return None

        val_text = get_attr("tv_glucose_value")
        if val_text and val_text != "--":
            try:
                res["glucose"] = float(val_text.replace(",", "."))
                res["reading_time"] = get_attr("tv_value_time") or "Щойно"
            except ValueError:
                pass
        
        res["sensor_life"] = get_attr("tv_sensor_remain_time") or ""
        res["highest"] = get_attr("tv_info_highest_value")
        res["lowest"] = get_attr("tv_info_lowest_value")
        res["tir"] = get_attr("tv_info_tir_value")
    except Exception:
        pass

    # 2. Зчитування бінарного логу Xlog для кінетики (dG/dt) та історії
    try:
        tail_data = run_adb(["exec-out", "tail", "-c", "65536", "/sdcard/Android/data/com.microtech.aidexx.mgdl/files/aidex/log/AiDEX_20261002.xlog"], device=device, timeout=4, binary=True).stdout
        records = decompress_xlog(tail_data)
        if records:
            full_text = "".join(records)
            pattern = re.compile(
                r'\[(\d{4}-\d{2}-\d{2})\s+\+\d+\.\d+\s+(\d{2}:\d{2}:\d{2}\.\d+)\].*?AapsBroadcastSender Sent glucose data to AAPS: value=([\d\.]+),\s*unit=([^,]+),\s*trend=([^,]+)'
            )
            matches = pattern.findall(full_text)
            parsed = []
            for date_part, time_part, val_str, unit, trend in matches:
                try:
                    dt = datetime.strptime(f"{date_part} {time_part}", "%Y-%m-%d %H:%M:%S.%f")
                    parsed.append({"dt": dt, "val": float(val_str), "trend": trend.strip(), "unit": unit.strip()})
                except Exception:
                    continue

            parsed.sort(key=lambda x: x["dt"])
            res["history_count"] = len(parsed)

            if parsed:
                latest = parsed[-1]
                res["trend"] = latest["trend"]
                if res["glucose"] is None:
                    res["glucose"] = round(latest["val"], 2)
                    res["reading_time"] = latest["dt"].strftime("%H:%M:%S")

                # Розрахунок швидкості dG/dt за останніми точками
                if len(parsed) >= 2:
                    p_prev = parsed[-2]
                    dt_min = (latest["dt"] - p_prev["dt"]).total_seconds() / 60.0
                    if 0.2 <= dt_min <= 5.0:
                        res["dG_dt_1min"] = round((latest["val"] - p_prev["val"]) / dt_min, 4)

                if len(parsed) >= 5:
                    p_5 = parsed[-5]
                    dt_5 = (latest["dt"] - p_5["dt"]).total_seconds() / 60.0
                    if 2.0 <= dt_5 <= 10.0:
                        res["dG_dt_5min"] = round((latest["val"] - p_5["val"]) / dt_5, 4)
    except Exception:
        pass

    # Якщо глюкоза отримана наживо з UI, перераховуємо dG/dt відносно попереднього збереженого зрізу
    try:
        if os.path.exists(CGM_LIVE_PATH) and res["glucose"] is not None:
            with open(CGM_LIVE_PATH, "r", encoding="utf-8") as f:
                prev_live = json.load(f)
            prev_g = prev_live.get("glucose", {}).get("value_mmol")
            prev_t = prev_live.get("timestamp_epoch_ms")
            if prev_g is not None and prev_t and prev_g != res["glucose"]:
                dt_min = (int(time.time() * 1000) - prev_t) / 60000.0
                if 0.1 <= dt_min <= 15.0:
                    res["dG_dt_1min"] = round((res["glucose"] - prev_g) / dt_min, 4)
    except Exception:
        pass

    # Класифікація стресу HPA
    dg = res["dG_dt_1min"]
    if dg > 0.08:
        res["hpa_status"] = "acute_cortisol_spike"
    elif dg > 0.03:
        res["hpa_status"] = "moderate_rise"
    elif dg < -0.08:
        res["hpa_status"] = "rapid_fall"
    elif dg < -0.03:
        res["hpa_status"] = "slight_fall"
    else:
        res["hpa_status"] = "quiescent"

    # BLE активність
    try:
        bt_out = run_adb(["shell", "dumpsys", "bluetooth_manager"], device=device, timeout=3).stdout
        scans = re.findall(r"Filter (\d+) results", bt_out)
        if scans:
            res["ble_packets"] = int(scans[-1])
    except Exception:
        pass

    res["latency_ms"] = int((time.time() - t0) * 1000)

    # Збереження живого стану у scratch/cgm_live.json
    try:
        os.makedirs(SCRATCH_DIR, exist_ok=True)
        live_data = {
            "timestamp_epoch_ms": int(time.time() * 1000),
            "iso_time": datetime.now().isoformat(),
            "status": res["status"],
            "state": "ACTIVE_STREAMING" if res["glucose"] is not None else "WAITING_DATA",
            "device": res["device"],
            "sensor": {
                "name": "LinX CGM (AiDEX X)",
                "transmitter_sn": TRANSMITTER_SN,
                "mac_address": TRANSMITTER_MAC,
                "ble_packet_rate_30s": res["ble_packets"],
                "sensor_life": res["sensor_life"]
            },
            "glucose": {
                "value_mmol": res["glucose"],
                "unit": "mmol/L",
                "trend": res["trend"],
                "reading_time": res["reading_time"],
                "dG_dt_1min": res["dG_dt_1min"],
                "dG_dt_5min": res["dG_dt_5min"],
                "hpa_status": res["hpa_status"],
                "highest": res["highest"],
                "lowest": res["lowest"],
                "tir": res["tir"],
                "history_points": res["history_count"]
            }
        }
        tmp_p = CGM_LIVE_PATH + ".tmp"
        with open(tmp_p, "w", encoding="utf-8") as f:
            json.dump(live_data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_p, CGM_LIVE_PATH)
    except Exception:
        pass

    return res

def query_ollama_edge(telemetry):
    val = telemetry.get("glucose")
    if val is None:
        return {"assessment": "Дані глюкози недоступні для аналізу.", "eval_ms": 0}

    prompt = (
        f"<|im_start|>system\n"
        f"You are a tactical cyber-physical metabolic biometrics copilot. Provide directly in 1 short sentence the metabolic state and player combat focus.<|im_end|>\n"
        f"<|im_start|>user\n"
        f"Glucose: {val:.2f} mmol/L (Trend: {telemetry['trend']}). dG/dt: {telemetry['dG_dt_1min']:+.3f} mmol/L/min. HPA state: {telemetry['hpa_status']}.\n"
        f"Tactical Assessment:<|im_end|>\n"
        f"<|im_start|>assistant\n"
    )

    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "options": {
            "num_thread": 2,
            "num_ctx": 256,
            "num_predict": 40,
            "temperature": 0.1,
            "stop": ["<|im_end|>", "\n", "Input:"]
        }
    }

    t0 = time.time()
    try:
        req = urllib.request.Request(
            OLLAMA_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        eval_ms = int((time.time() - t0) * 1000)
        resp_text = data.get("response", "").strip()

        # Запис у edge_assessments.jsonl
        rec = {
            "timestamp_epoch_ms": int(time.time() * 1000),
            "iso_time": datetime.now().isoformat(),
            "reading_time": telemetry["reading_time"],
            "glucose_mmol": val,
            "trend": telemetry["trend"],
            "dG_dt_1min": telemetry["dG_dt_1min"],
            "hpa_status": telemetry["hpa_status"],
            "edge_model": MODEL_NAME,
            "eval_time_ms": eval_ms,
            "assessment": resp_text
        }
        with open(ASSESSMENTS_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")

        return {"assessment": resp_text, "eval_ms": eval_ms}
    except Exception as e:
        return {"assessment": f"Ollama edge offline/busy: {e}", "eval_ms": int((time.time() - t0) * 1000)}

def display_diag_card(t, ollama_res):
    now_str = datetime.now().strftime("%H:%M:%S")
    val_str = f"{t['glucose']:.2f} mmol/L" if t['glucose'] is not None else "--"
    dg_str = f"{t['dG_dt_1min']:+.4f} mmol/L/min"

    print("┌" + "─" * 68 + "┐")
    print(f"│  LINX CGM TELEMETRY & OLLAMA EDGE DIAGNOSTICS      [{now_str}]  │")
    print("├" + "─" * 68 + "┤")
    print(f"│  Пристрій ADB:    {t['device']:<20} Статус: {t['status']:<15}       │")
    print(f"│  Затримка Wi-Fi:  {t['latency_ms']} мс               BLE пакети: {t['ble_packets']:<15} │")
    print("├" + "─" * 68 + "┤")
    print(f"│  ГЛЮКОЗА:         {val_str:<18} Тренд:  {t['trend']:<15}      │")
    print(f"│  Час виміру:      {t['reading_time']:<18} dG/dt:  {dg_str:<15}      │")
    print(f"│  Статус стресу:   {t['hpa_status']:<30}                   │")
    if t.get("highest"):
        print(f"│  Доба:            Max {t['highest']} | Min {t['lowest']} | TIR {t['tir']:<5}  {t['sensor_life']} │")
    print("├" + "─" * 68 + "┤")
    print(f"│  🤖 OLLAMA EDGE ({MODEL_NAME}, 2xE-cores, {ollama_res['eval_ms']} мс):               │")
    wrap_text = f"\"{ollama_res['assessment']}\""
    if len(wrap_text) > 64:
        print(f"│  {wrap_text[:64]}  │")
        print(f"│  {wrap_text[64:128]:<66}│")
    else:
        print(f"│  {wrap_text:<66}│")
    print("└" + "─" * 68 + "┘")

def main():
    parser = argparse.ArgumentParser(description="LinX CGM Consolidated Diagnostic Tool")
    parser.add_argument("--stream", action="store_true", help="Безперервний стрім")
    parser.add_argument("--interval", type=int, default=15, help="Інтервал стріму в секундах")
    args = parser.parse_args()

    # Знижуємо пріоритет планувальника (nice +19)
    try:
        os.nice(19)
    except Exception:
        pass

    dev = ensure_device_connected()
    if not dev:
        print("❌ ПОМИЛКА: Не вдалося знайти або підключити V Max Plus (192.168.0.122:5555).")
        sys.exit(1)

    if args.stream:
        print(f"📡 Запуск єдиного діагностичного моніторингу ({dev}, інтервал {args.interval}с)...")
        try:
            while True:
                t = fetch_telemetry(dev)
                ol = query_ollama_edge(t)
                display_diag_card(t, ol)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\nМоніторинг зупинено.")
            return

    # За замовчуванням: одиночний повний прогін діагностики
    t = fetch_telemetry(dev)
    ol = query_ollama_edge(t)
    display_diag_card(t, ol)

if __name__ == "__main__":
    main()
