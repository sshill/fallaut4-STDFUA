#!/usr/bin/env bash
# ==============================================================================
# Fallout 4 GOTY Research Stand - Native Linux Launcher
# Architecture: Intel Core 3 100U (Raptor Lake-U, i915 / Mesa 25.0.7 Iris/ANV)
# Pipeline: Direct3D 11 -> DXVK 2.6 -> Vulkan 1.4 + MangoHud Overlay
# Controller: Sony DualShock 4 v2 (evdev / DirectInput / XInput)
# ==============================================================================

set -e

STAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# SINGLETON GUARD & INSTANT OSD FEEDBACK
# ==============================================================================
LOCK_FILE="/tmp/fallout4_stand.lock"
exec 200>"${LOCK_FILE}"
if ! flock -n 200; then
    # Перевірка: чи дійсно гра Fallout4 або wineserver активні?
    if pgrep -f "Fallout4.exe" >/dev/null 2>&1 || pgrep -f "wineserver" >/dev/null 2>&1; then
        notify-send -u low -t 4000 -i "${STAND_DIR}/fallout4.png" "⏳ Fallout 4 вже запущено" "Гра вже виконується у фоні. Будь ласка, перемкніться на вікно гри." 2>/dev/null || true
        aplay -D default "${STAND_DIR}/scratch/chime_note.wav" 200>&- 2>/dev/null || true &
        echo "[Launcher] Fallout 4 вже працює в системі."
        exit 0
    else
        echo "[Launcher] Виявлено застаріле блокування без активного процесу Fallout 4. Автоматично знімаю лок..."
        rm -f "${LOCK_FILE}" 2>/dev/null || true
        exec 200>"${LOCK_FILE}"
        flock -n 200 || true
    fi
fi

# Миттєвий візуальний та акустичний відгук на клік гравця
notify-send -u normal -t 6000 -i "${STAND_DIR}/fallout4.png" "🎮 Fallout 4 GOTY" "Запуск рушія гри... Будь ласка, зачекайте завантаження." 2>/dev/null || true
aplay -D default "${STAND_DIR}/scratch/chime_note.wav" 200>&- 2>/dev/null || true &

export DISPLAY="${DISPLAY:-:0.0}"
export WINEPREFIX="${STAND_DIR}/prefix"
export WINEARCH=win64
# Wine debug logging: capture critical errors while filtering benign fixmes and avoiding SEH flood
export WINEDEBUG="err+all,fixme-all"
export GAME_LOG="${STAND_DIR}/scratch/game_crash.log"

# Controller environment: ensure SDL keeps input active in background
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Controller: Ignore raw physical Sony DualShock 4 and FootSwitch at the SDL2 driver level!
# This guarantees Wine/SDL NEVER creates a secondary or conflicting joystick for DualShock 4 or Footpad,
# even when the controller is disconnected and reconnected during gameplay.
export SDL_GAMECONTROLLER_IGNORE_DEVICES="0x054c/0x09cc,0x054c/0x05c4,0x3553/0xb001"
export SDL_JOYSTICK_IGNORE_DEVICES="0x054c/0x09cc,0x054c/0x05c4,0x3553/0xb001"
unset SDL_GAMECONTROLLERCONFIG 2>/dev/null || true

# Remove scrambled in-game ControlMap_Custom.txt to restore clean standard bindings
if [ -f "${WINEPREFIX}/drive_c/users/hills/Documents/My Games/Fallout4/ControlMap_Custom.txt" ]; then
    rm -f "${WINEPREFIX}/drive_c/users/hills/Documents/My Games/Fallout4/ControlMap_Custom.txt" 2>/dev/null || true
fi

# Activate MangoHud Vulkan layer cleanly
export MANGOHUD=1

# DXVK optimizations for Intel Raptor Lake iGPU
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="${STAND_DIR}/cache"
export DXVK_CONFIG_FILE="${STAND_DIR}/game/dxvk.conf"
mkdir -p "${DXVK_STATE_CACHE_PATH}"

# Performance optimizations: Boost CPU governor if allowed
if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
fi

# Disable XFCE window compositing during gameplay to eliminate stuttering & latency
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
trap 'xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true' EXIT

# Ensure Papyrus log directory exists for Antigravity live telemetry monitoring
export PAPYRUS_LOG_DIR="${WINEPREFIX}/drive_c/users/hills/Documents/My Games/Fallout4/Logs/Script"
mkdir -p "${PAPYRUS_LOG_DIR}"
touch "${PAPYRUS_LOG_DIR}/Papyrus.0.log"

# Audio routing: Enable DualShock 4 3.5mm headset jack (Full Stereo Output + Close-mic Input)
DS4_CARD=$(pactl list cards short 2>/dev/null | grep -i "Sony.*Wireless_Controller" | awk '{print $2}' | head -n 1)
if [ -n "${DS4_CARD}" ]; then
    pactl set-card-profile "${DS4_CARD}" output:analog-stereo+input:analog-mono 2>/dev/null || \
    pactl set-card-profile "${DS4_CARD}" pro-audio 2>/dev/null || true
fi

DS4_SINK=$(pactl list sinks short 2>/dev/null | grep -i "Sony.*Wireless_Controller" | awk '{print $2}' | head -n 1)
DS4_SOURCE=$(pactl list sources short 2>/dev/null | grep -i "Sony.*Wireless_Controller" | awk '{print $2}' | head -n 1)

if [ -n "${DS4_SINK}" ]; then
    pactl set-default-sink "${DS4_SINK}" 2>/dev/null || true
    echo " Audio Output: DualShock 4 3.5mm Headset Jack (${DS4_SINK})"
else
    # Fallback to Bluetooth Zone Vibe if DualShock audio is absent
    ZONE_VIBE_SINK=$(pactl list sinks short 2>/dev/null | grep -E "bluez_sink.*(94_02_30|Zone)" | awk '{print $2}' | head -n 1)
    if [ -n "${ZONE_VIBE_SINK}" ]; then
        pactl set-default-sink "${ZONE_VIBE_SINK}" 2>/dev/null || true
        echo " Audio Output: Zone Vibe 100 (${ZONE_VIBE_SINK})"
    fi
fi

if [ -n "${DS4_SOURCE}" ]; then
    pactl set-default-source "${DS4_SOURCE}" 2>/dev/null || true
    echo " Audio Input: DualShock 4 3.5mm Headset Microphone (${DS4_SOURCE})"
fi

echo "=================================================================="
echo " Starting Fallout 4 GOTY (v1.10.163.0) Stand Instance"
echo " Display: ${DISPLAY}"
echo " Wine: $(wine --version)"
echo " WINEPREFIX: ${WINEPREFIX}"
echo " GPU Target: Intel Raptor Lake-U (ANV Vulkan 1.4 + DXVK 2.6)"
echo " Audio Output: ${ZONE_VIBE_SINK:-Default PulseAudio Sink}"
echo " Papyrus Log: ${PAPYRUS_LOG_DIR}/Papyrus.0.log"
echo " Crash & Engine Log: ${GAME_LOG}"
# Automatically configure display: Fullscreen on external monitor if connected, or framed window if not
python3 "${STAND_DIR}/configure_display.py"

# Clean up any lingering background daemons from previous sessions
pkill -f footpad_mapper.py 2>/dev/null || true
pkill -f voice_copilot_service.py 2>/dev/null || true
pkill -f voice_motor_telemetry_service.py 2>/dev/null || true
sleep 0.2

# Voice services disabled to prevent CPU/GPU throttling & maintain max FPS
# (Reserved for future external co-processor architecture)
# python3 "${STAND_DIR}/voice_copilot_service.py" > "${STAND_DIR}/scratch/copilot.log" 2>&1 &
# COPILOT_PID=$!

# Ensure /dev/uinput is writable (self-healing permissions check)
if [ ! -w /dev/uinput ]; then
    echo " [Self-Healing] /dev/uinput не має прав на запис. Автоматично оновлюю права через sudo..."
    sudo -n chmod 666 /dev/uinput 2>/dev/null || true
fi

# Start Footpad Input Mapper Daemon in background (Left: Sprint, Middle: Jetpack, Right: Crouch, Touchpad: POV)
python3 "${STAND_DIR}/footpad_mapper.py" 200>&- > "${STAND_DIR}/scratch/footpad.log" 2>&1 &
FOOTPAD_PID=$!

# Verify footpad_mapper is running and initialized properly
sleep 0.5
if ! kill -0 "${FOOTPAD_PID}" 2>/dev/null; then
    echo " [УВАГА] footpad_mapper.py не зміг запуститися з першої спроби. Відновлюю права..."
    sudo -n chmod 666 /dev/uinput 2>/dev/null || true
    python3 "${STAND_DIR}/footpad_mapper.py" 200>&- > "${STAND_DIR}/scratch/footpad.log" 2>&1 &
    FOOTPAD_PID=$!
    sleep 0.5
fi

# Disable DS4 Touchpad from acting as an X11 mouse pointer (prevents cursor jumping and focus loss)
xinput disable "Sony Interactive Entertainment Wireless Controller Touchpad" 2>/dev/null || true

cleanup() {
    # CRITICAL SAFETY: Never kill footpad_mapper if Fallout4 is still running!
    if pgrep -f "Fallout4.exe" >/dev/null 2>&1; then
        echo "[Launcher Safety] Fallout4.exe все ще працює у фоні! footpad_mapper залишається активним."
        return
    fi
    kill "${FOOTPAD_PID}" 2>/dev/null || true
    pkill -f footpad_mapper.py 2>/dev/null || true
    xinput enable "Sony Interactive Entertainment Wireless Controller Touchpad" 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true
}
trap cleanup EXIT

echo " Footpad Mapper: Active (Left=Sprint, Middle=Jetpack, Right=Crouch)"
echo "=================================================================="

# Drop filesystem cache to maximize available physical RAM for Wine and Intel iGPU
sync
echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true

cd "${STAND_DIR}/game"
wine ./Fallout4.exe "$@" 200>&- >> "${GAME_LOG}" 2>&1 &

# Robust synchronization: wait up to 30s for Fallout4 or wineserver to appear
echo " Очікую завантаження рушія Fallout 4..."
for i in $(seq 1 30); do
    if pgrep -f "Fallout4.exe" >/dev/null 2>&1 || pgrep -f "wineserver" >/dev/null 2>&1; then
        echo " Fallout 4 успішно виявлено в системі (ітерація $i)."
        break
    fi
    sleep 1
done

# Keep launcher alive throughout the entire gameplay session until game fully closes
while pgrep -f "Fallout4.exe" >/dev/null 2>&1 || pgrep -f "wineserver" >/dev/null 2>&1; do
    sleep 1
done

echo " Fallout 4 завершив роботу. Виконую штатне очищення..."
