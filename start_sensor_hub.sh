#!/usr/bin/env bash
# ==============================================================================
# Autonomous Multimodal Cyber-Physical Telemetry Platform & Digital Therapeutics Stand
# Canonical Sensor Hub Runner (v0.3)
# Target: Intel Core 3 100U E-Cores (2, 3, 4, 5) with nice +19 priority
# Sensors: FootSwitch (USB HID), DualShock 4 (USB evdev), LinX CGM (Wi-Fi ADB),
#          Dual-Stream Voice (DS4 3.5mm Headset: Stream A RMS + Stream B Share)
# ==============================================================================
set -e

BASE_DIR="/home/hills/Documents/fallaut"
SCRATCH_DIR="/scratch"
cd ""

mkdir -p "" "/screens/session/audio_chunks"

echo "=================================================================="
echo "[Sensor Hub v0.3] Ініціалізація Core Bio-Telemetry Set на E-ядрах..."
echo "=================================================================="

# 1. Hardware Audio Configuration (DualShock 4 Wired 3.5mm Headset Jack)
DS4_CARD=$(pactl list cards short 2>/dev/null | grep -i "Sony.*Wireless_Controller" | awk '{print $2}' | head -n 1)
if [ -n "${DS4_CARD}" ]; then
    echo "[Audio] Налаштування профілю DualShock 4 (output:stereo + input:mono)..."
    pactl set-card-profile "${DS4_CARD}" output:analog-stereo+input:analog-mono 2>/dev/null ||     pactl set-card-profile "${DS4_CARD}" output:analog-stereo+input:mono-fallback 2>/dev/null || true
    pactl set-source-volume alsa_input.usb-Sony_Interactive_Entertainment_Wireless_Controller-00.mono-fallback 100% 2>/dev/null || true
    pactl set-source-mute alsa_input.usb-Sony_Interactive_Entertainment_Wireless_Controller-00.mono-fallback 0 2>/dev/null || true
else
    echo "[Audio] УВАГА: DualShock 4 не знайдено на USB. Перевірте фізичне підключення!"
fi

# 2. Inhibit screensaver and blanking
xset s off -dpms 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/presentation-mode -s true --create -t bool 2>/dev/null || true

# 3. Clean up older daemon instances
pkill -f "footpad_mapper.py" 2>/dev/null || true
pkill -f "cgm_adb_bridge.py" 2>/dev/null || true
pkill -f "dual_voice_telemetry_service.py" 2>/dev/null || true
pkill -f "voice_ollama_service.py" 2>/dev/null || true
sleep 0.5

# 4. Self-healing permissions for /dev/uinput
if [ ! -w /dev/uinput ]; then
    echo "[Input] Оновлення прав /dev/uinput..."
    sudo -n chmod 666 /dev/uinput 2>/dev/null || true
fi

# 5. Start FootSwitch + DualShock 4 Mapper on E-cores
echo "[Sensor 1/3] Запуск footpad_mapper.py (E-ядра 2,3,4,5, nice +19)..."
nohup nice -n 19 taskset -c 2,3,4,5 python3 "/footpad_mapper.py" > "/footpad.log" 2>&1 &
FOOTPAD_PID=$!

# 6. Start LinX CGM ADB Bridge (Wi-Fi 60s sampling) on E-cores
echo "[Sensor 2/3] Запуск cgm_adb_bridge.py (E-ядра 2,3,4,5, nice +19)..."
nohup nice -n 19 taskset -c 2,3,4,5 python3 "/cgm_adb_bridge.py" > "/cgm_bridge.log" 2>&1 &
CGM_PID=$!

# 7. Start Dual-Stream Voice Telemetry (Stream A: RMS Exclamation + Stream B: Share Note)
echo "[Sensor 3/3] Запуск dual_voice_telemetry_service.py (E-ядра 2,3,4,5, nice +19)..."
nohup nice -n 19 taskset -c 2,3,4,5 python3 "/dual_voice_telemetry_service.py" --daemon > "/dual_voice.log" 2>&1 &
VOICE_PID=$!

sleep 1

# 8. Feedback Chime & OSD
paplay "/chime_ready.wav" 2>/dev/null || aplay "/chime_ready.wav" 2>/dev/null || true
notify-send -u normal -t 4000 -i "/fallout4.png" "⚡ Core Bio-Telemetry Stand (v0.3)" "Хаб активовано на E-ядрах 2,3,4,5. P-ядра 0,1 вільні для Fallout 4." 2>/dev/null || true

echo "=================================================================="
echo "[УСПІХ] Усі сенсорні служби стенда активні на E-ядрах:"
echo "  - footpad_mapper (PID: $FOOTPAD_PID)"
echo "  - cgm_adb_bridge (PID: $CGM_PID)"
echo "  - dual_voice_telemetry (PID: $VOICE_PID)"
echo "  - Log: scratch/consolidated_voice_telemetry.jsonl"
echo "=================================================================="
