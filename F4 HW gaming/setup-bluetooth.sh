#!/bin/bash
set -e

echo "=== 1. Видалення помилкового файлу репозиторію additional.list ==="
if [ -f /etc/apt/sources.list.d/additional.list ]; then
    rm -v /etc/apt/sources.list.d/additional.list
    echo "Файл additional.list успішно видалено."
fi

echo "=== 2. Перевірка та оновлення /etc/apt/sources.list ==="
cat <<'EOF' > /etc/apt/sources.list
# Основний репозиторій Debian 12
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

# Оновлення безпеки (security)
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

# Важливі швидкі оновлення (updates)
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

echo "=== 3. Оновлення списків пакетів ==="
apt update

echo "=== 4. Встановлення Bluetooth-аудіо та графічного менеджера ==="
apt install -y pulseaudio-module-bluetooth blueman

echo "=== 5. Перезапуск служби Bluetooth ==="
systemctl restart bluetooth

echo "=== 6. Запуск трей-аплету та перезапуск звуку для користувача hills ==="
su hills -c "pulseaudio -k 2>/dev/null || true; nohup blueman-applet >/dev/null 2>&1 &"

echo "============================================================"
echo "Готово! У системному треї (біля годинника) з'явився значок Bluetooth."
