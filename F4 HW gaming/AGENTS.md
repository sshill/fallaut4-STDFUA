# AGENTS.md — Fallout 4 Hardware & Runtime (F4 HW gaming)

Доповнює ядро Hybrid-IDE (`~/.gemini/config/plugins/hybrid-ide/rules/AGENTS.md`) та диспетчер `fallaut/AGENTS.md`.

## 1. Апаратний комплекс та стек
- **Призначення:** Низьколатентний ввід/вивід (HID), аудіо-моніторинг та Wine 10 / DXVK 2.6.
- **Компоненти:**
  * **Геймпад:** DualShock 4 v2 (BT HID, інтегрований аудіо-тракт, `connect_ps4.sh`, `test_ds4_headset.py`).
  * **Педальний блок:** USB HID педалі (`footpad_mapper.py`, `calibrate_pedals.py`, `test_footpad.py`, `footpad_config.json`).
  * **HID-фільтрація:** `hide_hidraw.c` проти подвійного вводу в Wine/XInput (`test_xinput.py`).
  * **OSD & Voice Copilot:** `show_hud_toast.py`, `show_pedal_letters.py`, `stand_monitor.py`, `voice_copilot_service.py`.

## 2. Інженерні стандарти (Cyber-Physical Contracts)
- **Symlink Shield:** Усі утиліти зберігаються у `F4 HW gaming/`. У корені `fallaut/` діють відносні симлінки для 100% сумісності з `launch_fallout4.sh` та `.desktop`. Заборонено видаляти симлінки.
- **Низьколатентні черги:** Опитування педалей та сервісів — без блокувань (latency <= 5 мс).
- **Host-First:** Доступ до HID (`/dev/hidraw*`, `/dev/input/*`) та аудіо через `BypassSandbox: true`.

## 3. Матриця арбітражу
- Стандартні перевірки: Antigravity Supervisor + Principal Systems Architect.
- Ескалація: Якщо потрібні модифікації Papyrus чи рушія — завдання передається до `F4 modding/`.
