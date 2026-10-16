---
name: '🎮 Task: Fallout 4 Modding (Creation Engine)'
about: Завдання з розробки 3D-моделей, квестів, гардероба чи Papyrus-скриптів
title: '[MOD]: '
labels: ['modding', 'creation-engine', 'help wanted']
assignees: ''
---

### 🎯 Цільовий модуль / Staging Directory
<!-- Наприклад: F4 modding/staging_rexford_romance/ або F4 modding/staging_ellie_romance/ -->
- **Каталог:** `F4 modding/staging_...`
- **Плагін ESP:** `... .esp`

### 📋 Опис інженерної або контентної задачі
<!-- Чіткий опис того, що потрібно реалізувати: нова сцена, діалог, 3D меш ліжка, скрипт -->

### 🧩 Залежності та прив'язка FormID
- **Майстер-файли:** `Fallout4.esm` (Index 0) / DLC
- **Ключові FormID:**
  - `0x...` — Актор / Маркер / Меблі

### 🛠️ Необхідний інструментарій
- [ ] Blender / NifSkope (для 3D-мешів та анімацій)
- [ ] Wine 10 + Caprica Compiler v3.9+ (для скриптів Papyrus `.psc` -> `.pex`)
- [ ] Python 3.10+ (для раннерів генерації `build_*_esp.py`)

### ✅ Критерії прийомки (Definition of Done)
- [ ] Вихідний код скрипта скомпільовано через Caprica без жодної помилки.
- [ ] Байткод `.pex` створено у `Scripts/` з розміром > 0 байт.
- [ ] Оновлено тестовий батч-файл `game/copilot_cmd.txt` для перевірки у грі (`bat copilot_cmd`).
- [ ] Додано або оновлено документацію у `README.md` модуля чи `SCENARIO.md`.
