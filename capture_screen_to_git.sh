#!/usr/bin/env bash
# ==============================================================================
# Fallout Stand: Канонічний скрипт захоплення екрана та фіксації в Git
# Стандарт Регламенту v0.7.1 / AGENTS.md (Розділ 4)
# ==============================================================================
set -euo pipefail

STAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREENS_DIR="${STAND_DIR}/screens"
TARGET_IMG="${SCREENS_DIR}/latest.png"
REASON="${1:-inspect game state}"

mkdir -p "${SCREENS_DIR}"

# 1. Збереження кадру на диск хоста через X11
export DISPLAY="${DISPLAY:-:0}"
if ! command -v xfce4-screenshooter >/dev/null 2>&1; then
    echo "[capture_screen_to_git] ПОМИЛКА: xfce4-screenshooter не знайдено." >&2
    exit 1
fi

xfce4-screenshooter -f -s "${TARGET_IMG}"

if [[ ! -s "${TARGET_IMG}" ]]; then
    echo "[capture_screen_to_git] ПОМИЛКА: Знімок екрана порожній або не створився." >&2
    exit 1
fi

# 2. Локальна фіксація в Git (Git-First Local Access)
git -C "${STAND_DIR}" add -f "${TARGET_IMG}"
git -C "${STAND_DIR}" commit -m "feat(screen): ${REASON} [verified: antigravity]"

echo "[capture_screen_to_git] ⚡ Знімок успішно збережено та зафіксовано в Git: ${TARGET_IMG}"
