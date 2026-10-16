---
name: '⚡ Task: Cyber-Physical & Telemetry Platform'
about: Завдання з телеметрії, Linux-драйверів, сенсорів BLE або детерміністичної шини
title: '[HW]: '
labels: ['hardware', 'telemetry', 'linux-kernel', 'help wanted']
assignees: ''
---

### 📡 Цільова підсистема
<!-- Наприклад: proto/telemetry_bus.proto, footpad_mapper.py, hide_hidraw.c, cgm_adb_bridge.py -->
- **Компонент:** 
- **Мова / Протокол:** C / Python / Protocol Buffers v3 / Linux evdev

### 📋 Опис задачі
<!-- Чіткий опис необхідних змін, оптимізацій або інтеграцій нового обладнання -->

### ⏱️ Вимоги до детермінізму та SLA
- **Цільова затримка (Latency Budget):** Mean < 20 µs / $P_{99} \text{ jitter} < 2.5$ ms
- **Частота опитування (Hz):** 250 Гц / 1000 Гц

### 🧪 Верифікація без заліза (Headless HIL)
- Команда для запуску емуляційного тесту:
  ```bash
  python3 tests/mock_hardware_feeder.py --frames 1000 --rate-hz 250
  ```

### ✅ Критерії прийомки (Definition of Done)
- [ ] Схема Protobuf валідується через `protoc` без попереджень.
- [ ] HIL-бенчмарк проходить на headless Linux без дедлоків та перевищення лімітів затримки.
- [ ] Python-скрипти проходять компіляцію синтаксису `python3 -m py_compile ...`.
