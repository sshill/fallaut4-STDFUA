#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LinX CGM ADB Bridge (Channel 4: Metabolic / Glucose Telemetry)
-------------------------------------------------------------
Зчитує дані з сенсора LinX (Microtech AiDEX X) через Android Debug Bridge по Wi-Fi / USB.

Функціонал:
1. Автоматичне виявлення та підключення смартфона V Max Plus по Wi-Fi (192.168.0.122:5555) / USB.
2. Безперервний фоновий парсинг телеметрії Mars Xlog (AiDEX_YYYYMMDD.xlog).
3. Розрахунок швидкості зміни глюкози dG/dt (ммоль/л/хв) за 1 хв та 5 хв.
4. Оцінка вегетативно-метаболічного статусу (HPA axis stress / acute cortisol spike).
5. Збереження живого стану в scratch/cgm_live.json для Ollama, Копілота та Master Hub.
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
from datetime import datetime, timedelta

PACKAGE_NAME = "com.microtech.aidexx.mgdl"
DEFAULT_TRANSMITTER_SN = "22222FUWDN"
TRANSMITTER_MAC = "40:38:02:E9:10:DE"
DEFAULT_WIFI_ENDPOINT = "192.168.0.122:5555"
SCRATCH_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scratch")
LIVE_STATE_PATH = os.path.join(SCRATCH_DIR, "cgm_live.json")

class LinxCGMBridge:
    def __init__(self, target_device: str = None, transmitter_sn: str = DEFAULT_TRANSMITTER_SN):
        self.requested_device = target_device
        self.device = None
        self.sn = transmitter_sn
        self.resolve_target_device()

    def resolve_target_device(self) -> str:
        """Визначає найкращий доступний ADB пристрій (Wi-Fi у пріоритеті, USB як fallback)."""
        if self.requested_device:
            self.device = self.requested_device
            return self.device

        # Перевіряємо поточний список пристроїв
        try:
            res = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=4)
            lines = [line.strip().split() for line in res.stdout.strip().splitlines()[1:] if line.strip()]
            devices = {parts[0]: parts[1] for parts in lines if len(parts) >= 2}
        except Exception:
            devices = {}

        # 1. Пріоритет: Wi-Fi endpoint
        if DEFAULT_WIFI_ENDPOINT in devices and devices[DEFAULT_WIFI_ENDPOINT] == "device":
            self.device = DEFAULT_WIFI_ENDPOINT
            return self.device

        # Спроба підключитися по Wi-Fi, якщо він ще не підключений
        try:
            subprocess.run(["adb", "connect", DEFAULT_WIFI_ENDPOINT], capture_output=True, text=True, timeout=3)
            res = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=3)
            lines = [line.strip().split() for line in res.stdout.strip().splitlines()[1:] if line.strip()]
            devices = {parts[0]: parts[1] for parts in lines if len(parts) >= 2}
            if DEFAULT_WIFI_ENDPOINT in devices and devices[DEFAULT_WIFI_ENDPOINT] == "device":
                self.device = DEFAULT_WIFI_ENDPOINT
                return self.device
        except Exception:
            pass

        # 2. Пріоритет: V Max Plus по USB
        for dev, state in devices.items():
            if state == "device" and ("VMAX" in dev or "vmax" in dev.lower()):
                self.device = dev
                return self.device

        # 3. Fallback: будь-який активний пристрій
        for dev, state in devices.items():
            if state == "device":
                self.device = dev
                return self.device

        self.device = None
        return None

    def run_adb(self, cmd_args: list, timeout: int = 5, capture_binary: bool = False):
        """Виконує adb команду із прив'язкою до обраного пристрою."""
        if not self.device:
            self.resolve_target_device()
        if not self.device:
            raise RuntimeError("Жоден Android пристрій не підключений через ADB")

        full_cmd = ["adb", "-s", self.device] + cmd_args
        if capture_binary:
            return subprocess.run(full_cmd, capture_output=True, timeout=timeout)
        else:
            return subprocess.run(full_cmd, capture_output=True, text=True, timeout=timeout)

    def is_connected(self) -> bool:
        """Перевіряє доступність обраного пристрою."""
        if not self.device:
            self.resolve_target_device()
        if not self.device:
            return False
        try:
            res = self.run_adb(["get-state"], timeout=3)
            return res.stdout.strip() == "device"
        except Exception:
            return False

    def read_xlog_telemetry(self) -> dict:
        """
        Зчитує та розпаковує лог Tencent Mars Xlog з пам'яті смартфону.
        Повертає історію вимірювань, останнє значення, dG/dt та вегетативний статус.
        """
        result = {
            "success": False,
            "readings": [],
            "latest_reading": None,
            "dG_dt_1min": 0.0,
            "dG_dt_5min": 0.0,
            "hpa_status": "quiescent",
            "error": None
        }

        try:
            # Знаходимо останній актуальний xlog файл
            find_cmd = ["shell", "ls -1t /sdcard/Android/data/com.microtech.aidexx.mgdl/files/aidex/log/AiDEX_*.xlog 2>/dev/null | head -n 1"]
            res = self.run_adb(find_cmd, timeout=3)
            log_path = res.stdout.strip()
            if not log_path or "No such" in log_path:
                result["error"] = "Xlog файл не знайдено на смартфоні"
                return result

            # Зчитуємо хвіст файлу (64KB - достатньо для останніх ~50 вимірювань)
            tail_cmd = ["exec-out", "tail", "-c", "65536", log_path]
            tail_res = self.run_adb(tail_cmd, timeout=5, capture_binary=True)
            tail_data = tail_res.stdout

            # Якщо з хвоста не вдалося отримати блоки, робимо fallback на pull
            records = self._decompress_xlog_chunks(tail_data)
            if not records:
                temp_pull = "/tmp/cgm_temp.xlog"
                self.run_adb(["pull", log_path, temp_pull], timeout=6)
                if os.path.exists(temp_pull):
                    with open(temp_pull, "rb") as f:
                        records = self._decompress_xlog_chunks(f.read())
                    try:
                        os.remove(temp_pull)
                    except Exception:
                        pass

            if not records:
                result["error"] = "Не вдалося декомпресувати блоки Mars Xlog"
                return result

            full_text = "".join(records)
            # Шукаємо відправки AapsBroadcastSender
            # Формат: [I][2026-10-02 +3.0 17:09:56.819]...[AapsBroadcastSender Sent glucose data to AAPS: value=11.5, unit=mmol/L, trend=Flat
            pattern = re.compile(
                r'\[(\d{4}-\d{2}-\d{2})\s+\+\d+\.\d+\s+(\d{2}:\d{2}:\d{2}\.\d+)\].*?AapsBroadcastSender Sent glucose data to AAPS: value=([\d\.]+),\s*unit=([^,]+),\s*trend=([^,]+)'
            )
            matches = pattern.findall(full_text)
            if not matches:
                result["error"] = "Вимірювання AapsBroadcastSender не знайдені в декомпресованому лозі"
                return result

            parsed_readings = []
            for date_part, time_part, val_str, unit, trend in matches:
                try:
                    dt = datetime.strptime(f"{date_part} {time_part}", "%Y-%m-%d %H:%M:%S.%f")
                    val = float(val_str)
                    parsed_readings.append({
                        "datetime": dt,
                        "time_str": dt.strftime("%Y-%m-%d %H:%M:%S"),
                        "glucose": val,
                        "unit": unit.strip(),
                        "trend": trend.strip()
                    })
                except Exception:
                    continue

            if not parsed_readings:
                result["error"] = "Помилка парсингу часових міток"
                return result

            # Сортуємо по часу (останні в кінці)
            parsed_readings.sort(key=lambda x: x["datetime"])
            result["readings"] = parsed_readings
            latest = parsed_readings[-1]
            result["latest_reading"] = latest
            result["success"] = True

            # Розрахунок швидкості зміни (dG/dt)
            if len(parsed_readings) >= 2:
                prev = parsed_readings[-2]
                dt_min = (latest["datetime"] - prev["datetime"]).total_seconds() / 60.0
                if 0.2 <= dt_min <= 5.0:
                    dG = latest["glucose"] - prev["glucose"]
                    result["dG_dt_1min"] = round(dG / dt_min, 4)

            # Розрахунок за 5 хвилин
            if len(parsed_readings) >= 5:
                ref_5min = parsed_readings[-5]
                dt_5min = (latest["datetime"] - ref_5min["datetime"]).total_seconds() / 60.0
                if 2.0 <= dt_5min <= 10.0:
                    dG_5 = latest["glucose"] - ref_5min["glucose"]
                    result["dG_dt_5min"] = round(dG_5 / dt_5min, 4)

            # Оцінка HPA axis / нейроендокринного стресу
            dg_dt = result["dG_dt_1min"]
            if dg_dt > 0.08:
                result["hpa_status"] = "acute_cortisol_spike"
            elif dg_dt > 0.03:
                result["hpa_status"] = "moderate_rise"
            elif dg_dt < -0.08:
                result["hpa_status"] = "rapid_fall"
            elif dg_dt < -0.03:
                result["hpa_status"] = "slight_fall"
            else:
                result["hpa_status"] = "quiescent"

        except Exception as e:
            result["error"] = str(e)

        return result

    def _decompress_xlog_chunks(self, data: bytes) -> list:
        """Розпаковує сирі байти Tencent Mars Xlog (magic 0x09)."""
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
                text = dec.decompress(chunk).decode('utf-8', errors='ignore')
                records.append(text)
                offset += header_len + length + 1
            except Exception:
                offset += 1

        return records

    def get_ble_stats(self) -> dict:
        """Зчитує активність Bluetooth LE сканера та прийом пакетів через dumpsys bluetooth_manager."""
        try:
            out = self.run_adb(["shell", "dumpsys", "bluetooth_manager"], timeout=4).stdout
            is_scanning = "com.microtech.aidexx.mgdl" in out and "Scan" in out
            packets = 0
            scans = re.findall(r"Filter (\d+) results", out)
            if scans:
                packets = int(scans[-1])
            is_bonded = self.sn in out or "LinX" in out
            return {
                "active_scanner": is_scanning,
                "packets_last_cycle": packets,
                "bonded_device": is_bonded
            }
        except Exception as e:
            return {"active_scanner": False, "packets_last_cycle": 0, "bonded_device": False, "error": str(e)}

    def get_active_alerts(self) -> list:
        """Перевіряє наявність сповіщень чи помилок у системній шторці."""
        alerts = []
        try:
            out = self.run_adb(["shell", "dumpsys", "notification", "--noredact"], timeout=4).stdout
            for m in re.finditer(r"android\.text=String \(([^)]+)\)", out):
                text = m.group(1)
                if any(kw in text for kw in ["Сигнал", "втрачено", "сенсор", "помилка", "батаре"]):
                    alerts.append(text)
        except Exception:
            pass
        return list(set(alerts))

    def read_ui_display(self) -> dict:
        """Зчитує віджети UI додатку LinX, якщо інтерфейс доступний на екрані."""
        try:
            out = self.run_adb(["shell", "uiautomator dump /sdcard/linx_ui.xml >/dev/null 2>&1 && cat /sdcard/linx_ui.xml"], timeout=6).stdout
            
            def get_attr(res_id, attr="text"):
                m = re.search(rf'<node\b[^>]*\bresource-id=\"[^\"]*{res_id}\"[^>]*>', out)
                if m:
                    am = re.search(rf'\b{attr}=\"([^\"]*)\"', m.group(0))
                    if am:
                        return am.group(1).strip()
                return None

            return {
                "display_value": get_attr("tv_glucose_value"),
                "value_time": get_attr("tv_value_time"),
                "sensor_life": get_attr("tv_sensor_remain_time") or "",
                "highest": get_attr("tv_info_highest_value"),
                "lowest": get_attr("tv_info_lowest_value"),
                "tir": get_attr("tv_info_tir_value"),
            }
        except Exception:
            return {}

    def get_telemetry(self) -> dict:
        """Формує консолідований зріз телеметрії CGM."""
        now_epoch_ms = int(time.time() * 1000)
        iso_time = datetime.now().isoformat()

        if not self.is_connected():
            return {
                "timestamp_epoch_ms": now_epoch_ms,
                "iso_time": iso_time,
                "status": "DISCONNECTED",
                "device": self.device,
                "error": "Смартфон V Max Plus не підключено або ADB не авторизовано"
            }

        ble = self.get_ble_stats()
        alerts = self.get_active_alerts()
        xlog = self.read_xlog_telemetry()

        # Зчитуємо поточний віджет UI
        ui = self.read_ui_display()

        glucose_val = None
        trend = "Unknown"
        unit = "mmol/L"
        reading_time = ""

        # Пріоритет 1: Живий екран UI (якщо доступний і валідний)
        ui_raw = ui.get("display_value")
        if ui_raw and ui_raw != "--":
            try:
                glucose_val = float(ui_raw.replace(",", "."))
                reading_time = ui.get("value_time") or "Щойно"
                state = "ACTIVE_STREAMING"
            except ValueError:
                pass

        # Доповнення або основа з Xlog
        if xlog.get("success") and xlog.get("latest_reading"):
            latest = xlog["latest_reading"]
            trend = latest["trend"]
            unit = latest["unit"]
            if glucose_val is None:
                glucose_val = round(latest["glucose"], 2)
                reading_time = latest["time_str"]
            state = "ACTIVE_STREAMING"
        elif glucose_val is None:
            state = "WAITING_DATA"

        telemetry = {
            "timestamp_epoch_ms": now_epoch_ms,
            "iso_time": iso_time,
            "status": "CONNECTED",
            "state": state,
            "device": self.device,
            "sensor": {
                "name": "LinX CGM (AiDEX X)",
                "transmitter_sn": self.sn,
                "mac_address": TRANSMITTER_MAC,
                "ble_scanning": ble.get("active_scanner", False),
                "ble_packet_rate_30s": ble.get("packets_last_cycle", 0),
                "bonded": ble.get("bonded_device", False),
                "sensor_life": ui.get("sensor_life", "")
            },
            "glucose": {
                "value_mmol": glucose_val,
                "unit": unit,
                "trend": trend,
                "reading_time": reading_time,
                "dG_dt_1min": xlog.get("dG_dt_1min", 0.0),
                "dG_dt_5min": xlog.get("dG_dt_5min", 0.0),
                "hpa_status": xlog.get("hpa_status", "quiescent"),
                "highest": ui.get("highest"),
                "lowest": ui.get("lowest"),
                "tir": ui.get("tir"),
                "history_points": len(xlog.get("readings", []))
            },
            "alerts": alerts
        }

        # Зберігаємо живий стан для зовнішніх споживачів
        self.save_live_state(telemetry)
        return telemetry

    def save_live_state(self, telemetry: dict):
        """Зберігає живий зріз телеметрії у scratch/cgm_live.json."""
        try:
            os.makedirs(SCRATCH_DIR, exist_ok=True)
            tmp_path = LIVE_STATE_PATH + ".tmp"
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(telemetry, f, indent=2, ensure_ascii=False)
            os.replace(tmp_path, LIVE_STATE_PATH)
        except Exception:
            pass

def main():
    parser = argparse.ArgumentParser(description="LinX CGM ADB Wi-Fi / USB Telemetry Bridge")
    parser.add_argument("--device", type=str, default=None, help="Конкретний ADB пристрій (наприклад 192.168.0.122:5555)")
    parser.add_argument("--json", action="store_true", help="Вивід одного зрізу в JSON")
    parser.add_argument("--stream", action="store_true", help="Безперервний моніторинг кожні N секунд")
    parser.add_argument("--interval", type=int, default=30, help="Інтервал опитування (за замовчуванням 30 сек)")
    args = parser.parse_args()

    bridge = LinxCGMBridge(target_device=args.device)

    if args.json:
        print(json.dumps(bridge.get_telemetry(), indent=2, ensure_ascii=False))
        return

    if args.stream:
        print(f"📡 Запуск безперервного моніторингу LinX CGM ({bridge.device or 'Auto'}, інтервал: {args.interval} с). Натисніть Ctrl+C для виходу.\n")
        try:
            while True:
                data = bridge.get_telemetry()
                t = data.get("iso_time", "")[11:19]
                state = data.get("state", "UNKNOWN")
                g = data.get("glucose", {})
                val = g.get("value_mmol")
                val_str = f"{val:.2f} {g.get('unit')}" if val is not None else "--"
                dg = g.get("dG_dt_1min", 0.0)
                dg_str = f"dG/dt: {dg:+.3f}" if dg != 0 else "dG/dt:  0.000"
                hpa = g.get("hpa_status", "quiescent")
                packets = data.get("sensor", {}).get("ble_packet_rate_30s", 0)
                alerts = f" | ⚠️ {', '.join(data.get('alerts'))}" if data.get("alerts") else ""

                print(f"[{t}] Стан: {state:<15} | Глюкоза: {val_str:<14} | Тренд: {g.get('trend','?'):<5} | {dg_str} | HPA: {hpa:<18} | BLE: {packets:>2}/30с{alerts}", flush=True)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\nМоніторинг зупинено.")
            return

    # За замовчуванням: тестовий діагностичний замір
    print("=" * 70)
    print("      ТЕСТОВИЙ ЗРІЗ СТАНУ СИСТЕМИ: LINX CGM ADB WI-FI BRIDGE")
    print("=" * 70)
    t0 = time.time()
    data = bridge.get_telemetry()
    dt = round(time.time() - t0, 2)

    if data.get("status") == "DISCONNECTED":
        print(f"❌ ПОМИЛКА: {data.get('error')}")
        sys.exit(1)

    s = data["sensor"]
    g = data["glucose"]

    print(f"Цільовий пристрій:      {data['device']} (затримка зчитування: {dt} с)")
    print(f"Час зрізу:              {data['iso_time']}")
    print(f"Поточний статус:        {data['state']}")
    print("-" * 70)
    print(f"Сенсор:                 {s['name']} (Трансмітер: {s['transmitter_sn']})")
    print(f"MAC-адреса:             {s['mac_address']} (Зв'язано: {'ТАК' if s['bonded'] else 'НІ'})")
    print(f"BLE-сканер Android:     {'АКТИВНИЙ' if s['ble_scanning'] else 'НЕАКТИВНИЙ'}")
    print(f"Інтенсивність пакетів:  {s['ble_packet_rate_30s']} пакетів / 30 сек")
    if s.get("sensor_life"):
        print(f"Залишок ресурсу сенсора: {s['sensor_life']}")
    print("-" * 70)
    print(f"Числове значення:       {g['value_mmol']} {g['unit']}")
    print(f"Тренд глюкози:          {g['trend']}")
    print(f"Швидкість зміни dG/dt:  {g['dG_dt_1min']:+.4f} ммоль/л/хв (5-хв: {g['dG_dt_5min']:+.4f})")
    print(f"Статус стресу (HPA):    {g['hpa_status']}")
    print(f"Час останнього виміру:  {g['reading_time']}")
    print(f"Історичних точок у базі:{g['history_points']}")
    if g.get("highest"):
        print(f"Добові екстремуми:      Найвище: {g['highest']} | Найнижче: {g['lowest']} | TIR: {g['tir']}")
    print("-" * 70)
    if data["alerts"]:
        print(f"⚠️ Активні сповіщення:   {', '.join(data['alerts'])}")
    else:
        print("✅ Помилок чи збоїв зв'язку немає")
    print("=" * 70)
    print(f"✅ Живий зріз записано в: {LIVE_STATE_PATH}\n")

if __name__ == "__main__":
    main()
