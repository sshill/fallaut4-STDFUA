# 🤝 Посібник контриб'ютора / Contributor Guide
## Fallout 4 Multimodal Telemetry Platform & Grand Modding Stand (`fallaut4-STDFUA`)

[ 🇺🇦 **Українська версія** ](#ukrainian) &nbsp;|&nbsp; [ 🇬🇧 **English Version** ](#english)

---

<a name="ukrainian"></a>
# 🇺🇦 Українська версія

Ласкаво просимо до проєкту **`fallaut4-STDFUA`**!  
Комплекс поєднує два взаємопов'язані домени:
1. **Кіберфізичну платформу нейрореабілітації ветеранів ЗСУ (DTx):** 1-мс детерміністична шина телеметрії (Protocol Buffers v3), низькорівневі Linux-перехоплювачі (`evdev`, `uinput`, `LD_PRELOAD`), біосенсори (Polar H10, CGM LinX) та HIL-емуляція.
2. **Розширення Fallout 4 (Creation Engine):** Скрипти Papyrus, модульні плагіни ESP, динамічний гардероб, квести та модуль повної українізації.

Для того, щоб кожен розробник міг зосередитися на своїй експертизі без зайвого когнітивного навантаження, проєкт розділено на **дві паралельні траєкторії контриб'ютингу**:

```
                              [ fallaut4-STDFUA ]
                                       │
        ┌──────────────────────────────┴──────────────────────────────┐
        ▼                                                             ▼
[ ТРАЄКТОРІЯ А: МОДДИНГ ]                                  [ ТРАЄКТОРІЯ Б: КІБЕРФІЗИКА ]
• Скрипти Papyrus (.psc / .pex)                            • Детерміністична шина (telemetry_bus.proto)
• 3D-моделювання та анімації (Blender / NifSkope)          • Драйвери Linux (evdev, uinput, LD_PRELOAD)
• ESP-плагіни та квести Creation Engine                    • Біосенсори BLE (Polar H10, CGM LinX)
• Модуль українізації та сценарії                          • Headless HIL емуляція та бенчмарки
```

---

## 🛠️ Рекомендоване середовище розробки: Hybrid IDE for Contributors

Для максимальної продуктивності, автоматизованої перевірки синтаксису та AI-оркестрації розроблено спеціалізоване середовище:  
👉 **[sshill/Hybrid-IDE-for-contributirs](https://github.com/sshill/Hybrid-IDE-for-contributirs)**

### Чому варто встановити:
* **Автоматизація перевірок:** Вбудовані перевірки лінтерів, компіляції та тестів на кожному етапі.
* **Ізоляція середовища:** Чисті конфігурації для роботи без ризику конфліктів системних залежностей.
* **ШІ-оркестрація:** Інтеграція з Gemini API та локальною Ollama для підказок та рев'ю коду.

> [!IMPORTANT]
> **Умови розгортання та фінансування (Важливе застереження):**  
> 1. **Самостійне розгортання:** Налаштування робочої станції, інструментів та оточення контриб'ютор виконує самостійно за інструкцією з репозиторію `Hybrid-IDE-for-contributirs`.  
> 2. **Оплата Google Cloud / Gemini API:** Використання рекомендованого пакета Google (Google Cloud / Gemini API) або сторонніх LLM-підписок розробник покриває **повністю самостійно за власний кошт**. Проєкт на поточному етапі не відшкодовує витрати на сторонні хмарні сервіси.

---

## 🎮 Траєкторія А: Геймдев та моддинг Fallout 4 (Creation Engine)

Цей напрям призначений для модмейкерів, 3D-моделістів, сценаристів та розробників Papyrus.

### 1. Архітектура каталогів модів
Кожен мод розробляється в окремому ізольованому staging-каталозі в `F4 modding/`:
* `F4 modding/staging_rexford_romance/` — Романтична сцена Магнолії, постільний сценарій, гардероб (Реліз v1.0).
* `F4 modding/staging_ellie_romance/` — Сюжетна та супутня лінія Еллі Перкінс.
* `F4 modding/staging_mercy_recruitment/` — Система вербування лідерів Стрільців (Шеллі Тіллер).
* `F4 modding/staging_deb_caravan/` — Логістичний нагляд караванів Деб (Банкер-Гілл).
* `F4 modding/staging_vintage_mannequins/` — Модульні манекени та рескіни.

### 2. Інструменти та процес збірки
* **Цільова гра:** Fallout 4 GOTY **v1.10.163.0** (Steam pre-nextgen або GOG). Next-Gen оновлення (1.10.980+) не підтримуються.
* **Компілятор Papyrus:** Використовується **Caprica Compiler v3.9+** під Wine 10:
  ```bash
  # Компіляція скриптів конкретного модуля:
  python3 "F4 modding/staging_rexford_romance/compile_rexford_scripts.py"
  ```
* **Генерація ESP плагіна:**
  ```bash
  python3 "F4 modding/staging_rexford_romance/build_rexford_romance_esp.py"
  ```
* **Автоматичний збір релізного пакету та ШІ-перевірка через Ollama:**
  ```bash
  python3 "F4 modding/f4_pipeline_router.py" --assemble
  ```

### 3. Актуальний беклог завдань з моддингу (Відкриті задачі)
1. 🛌 **Rexford Romance — Двоспальне ліжко Магнолії (3D / Анімація):**
   - **Проблема:** Ванільне ліжко гравця в готелі «Рексфорд» (`0x0010C651`) є одномісним і містить лише 1 маркер взаємодії, через що партнер не може лягти поруч без зсуву колізій.
   - **Задача:** Створення кастомної 3D-моделі двоспального ліжка (`.nif`) зі спареними меблевими маркерами (`LayEntry`/`LaySleep` для обох акторів).
   - **Документація:** Детальний опис стейт-машини у [`F4 modding/staging_rexford_romance/SCENARIO.md`](F4%20modding/staging_rexford_romance/SCENARIO.md).
2. 🕵️ **Ellie Romance — Розширення діалогів:** Написання додаткових гілок реплік та налаштування пакетів супутника.
3. 🎯 **Mercy Recruitment — Прив'язка до майстерні:** Реєстрація Шеллі Тіллер у системі поселень через `WorkshopNPCScript` та `WorkshopParentScript`.

---

## ⚡ Траєкторія Б: Кіберфізичний стенд та системне програмування

Цей напрям призначений для C/Python розробників, спеціалістів із вбудованих систем, протоколів передачі даних та ядра Linux.

### 1. Архітектура апаратного комплексу
* **Формальний контракт шини (ICD):** [`proto/telemetry_bus.proto`](proto/telemetry_bus.proto) (Protocol Buffers v3). Описує 1-мс телеметричний кадр (ЕКГ, RMSSD, індекс Баєвського, глікемія LinX, кути аналогових стіків, тремор 8–12 Гц, педалі).
* **Linux Kernel перехоплювач:** [`hide_hidraw.c`](hide_hidraw.c) — динамічна бібліотека (LD_PRELOAD) для ізоляції USB-пристроїв введення.
* **Обробник подій введення:** [`footpad_mapper.py`](footpad_mapper.py) — обробка Linux `evdev` та трансляція у віртуальні пристрої `uinput`.

### 2. Запуск тестів та емуляції без заліза (Headless HIL)
Вам не потрібні фізичні датчики Polar H10 чи контролери, щоб розробляти код для стенда. Усі тести проходять у headless-режимі:
```bash
# Валідація синтаксису схеми Protobuf:
protoc --proto_path=proto --descriptor_set_out=/dev/null proto/telemetry_bus.proto

# Запуск емулятора датчиків та бенчмарка джиттера (SLA: P99 < 2.5 мс):
python3 tests/mock_hardware_feeder.py --frames 1000 --rate-hz 250
```

### 3. Актуальний беклог завдань із заліза
1. Оптимізація udev-правил для безшовного гарячого підключення педалей.
2. Розширення BLE-парсера для додаткових пульсометрів (Garmin, Wahoo).
3. Розробка візуального дашборда телеметрії для другого монітора на базі Dear PyGui або Qt.

---

## 📐 Загальний Git Workflow та правила оформлення комітів

1. **Форк та гілки:**
   - Створюйте окрему гілку від актуального `main`:
     - `feature/rexford-double-bed`
     - `fix/ellie-dialogue-stall`
     - `hw/polar-h10-reconnect`
2. **Стандарт коміт-повідомлень (Conventional Commits):**
   - `feat(scope): опис змін`
   - `fix(scope): опис виправлення`
   - `docs(scope): оновлення документації`
3. **Критерії готовності (Definition of Done) перед створенням Pull Request:**
   - [ ] Papyrus скрипти скомпільовано через Caprica з **0 помилок** (байткод `.pex` створено в `Scripts/`).
   - [ ] Запущено `python3 tests/mock_hardware_feeder.py` — HIL бенчмарк проходить успішно.
   - [ ] Відсутні непідтверджені сміттєві файли (дампи пам'яті, логи, тимчасові `.bck`).

---
---

<a name="english"></a>
# 🇬🇧 English Version

Welcome to **`fallaut4-STDFUA`**!  
This repository integrates two distinct, symbiotic domains:
1. **Cyber-Physical Neuro-Rehabilitation Platform for AFU Veterans (DTx):** 1-ms deterministic telemetry bus (Protocol Buffers v3), Linux kernel interception (`evdev`, `uinput`, `LD_PRELOAD`), BLE biosensors (Polar H10, LinX CGM), and Headless HIL emulation.
2. **Fallout 4 Total Conversion & Mechanics Stand (Creation Engine):** Papyrus scripts, modular ESP plugins, dynamic wardrobe state-machines, quest logic, and a comprehensive localization subsystem.

To allow contributors to focus directly on their domain of expertise without unnecessary cognitive overhead, the project provides **two distinct contribution tracks**:

```
                              [ fallaut4-STDFUA ]
                                       │
        ┌──────────────────────────────┴──────────────────────────────┐
        ▼                                                             ▼
[ TRACK A: GAME MODDING ]                                  [ TRACK B: CYBER-PHYSICAL ]
• Papyrus scripting (.psc / .pex)                          • Deterministic bus (telemetry_bus.proto)
• 3D modeling & animations (Blender / NifSkope)            • Linux kernel drivers (evdev, uinput, LD_PRELOAD)
• ESP plugins & Creation Engine quests                     • BLE biosensors (Polar H10, CGM LinX)
• Scenario choreography & dynamic wardrobe                 • Headless HIL emulation & benchmarks
```

---

## 🛠️ Recommended Development Environment: Hybrid IDE for Contributors

To maximize engineering velocity, automated syntax auditing, and AI orchestration, we recommend our specialized development suite:  
👉 **[sshill/Hybrid-IDE-for-contributirs](https://github.com/sshill/Hybrid-IDE-for-contributirs)**

### Why Install:
* **Automated Checks:** Built-in linters, compilation hooks, and test runners on every commit.
* **Environment Isolation:** Hermetic configurations to prevent dependency conflicts across host OSes.
* **AI Orchestration:** Gemini API and local Ollama integrations for intelligent completion and policy reviews.

> [!IMPORTANT]
> **Workstation Deployment & Cloud Costs (Mandatory Notice):**  
> 1. **Self-Managed Deployment:** Setting up the workstation, tools, and developer environment is the sole responsibility of the contributor per the setup guide in `Hybrid-IDE-for-contributirs`.  
> 2. **Google Cloud / Gemini API Costs:** The recommended Google package (Google Cloud / Gemini API) or third-party LLM services must be **funded independently by the contributor**. The project does not cover or reimburse these expenses at this stage.

---

## 🎮 Track A: Fallout 4 Game Modding (Creation Engine)

Targeted at modders, 3D artists, narrative designers, and Papyrus scripters.

### 1. Mod Staging Architecture
Each mod is developed within an isolated directory inside `F4 modding/`:
* `F4 modding/staging_rexford_romance/` — Magnolia overnight romance encounter, sleep wardrobe choreography (Release v1.0).
* `F4 modding/staging_ellie_romance/` — Ellie Perkins companion & narrative line.
* `F4 modding/staging_mercy_recruitment/` — Gunner recruitment engine (Shelly Tiller).
* `F4 modding/staging_deb_caravan/` — Deb's Bunker Hill caravan supervisor mechanics.
* `F4 modding/staging_vintage_mannequins/` — Modular mannequin wardrobe overrides.

### 2. Build Pipeline
* **Target Game Build:** Fallout 4 GOTY **v1.10.163.0** (Steam pre-nextgen depot or GOG build `56699004712175290`). Next-Gen builds (1.10.980+) are strictly unsupported due to broken Papyrus hooks.
* **Papyrus Compiler:** **Caprica Compiler v3.9+** running under Wine 10:
  ```bash
  python3 "F4 modding/staging_rexford_romance/compile_rexford_scripts.py"
  ```
* **ESP Generation:**
  ```bash
  python3 "F4 modding/staging_rexford_romance/build_rexford_romance_esp.py"
  ```
* **Full Mod Assembler & AI Validation Pipeline:**
  ```bash
  python3 "F4 modding/f4_pipeline_router.py" --assemble
  ```

### 3. Open Modding Tasks
1. 🛌 **Rexford Romance — Dual-Actor Double Bed Overhaul (3D / Animation):**
   - **Problem:** The vanilla player bed in Hotel Rexford (`0x0010C651`) is single-occupancy with a single interaction marker, preventing simultaneous synchronized sleeping without mesh clipping.
   - **Task:** Create a custom 3D double bed model (`.nif`) featuring paired interaction markers (`LayEntry` / `LaySleep` for both actors).
   - **Documentation:** See full state machine analysis in [`F4 modding/staging_rexford_romance/SCENARIO.md`](F4%20modding/staging_rexford_romance/SCENARIO.md).
2. 🕵️ **Ellie Romance Dialogue Tree Expansion:** Adding additional dialogue branches and companion follower packages.
3. 🎯 **Mercy Recruitment Settlement Hook:** Registering Shelly Tiller with `WorkshopNPCScript` and `WorkshopParentScript`.

---

## ⚡ Track B: Cyber-Physical Platform & Systems Engineering

Targeted at C/Python engineers, embedded systems specialists, Linux kernel developers, and protocol architects.

### 1. Hardware & Driver Architecture
* **Interface Control Document (ICD):** [`proto/telemetry_bus.proto`](proto/telemetry_bus.proto) (Protocol Buffers v3) defining the 1-ms deterministic telemetry frame.
* **Low-level C Interceptor:** [`hide_hidraw.c`](hide_hidraw.c) (`LD_PRELOAD`) for USB device isolation.
* **Input Subsystem:** [`footpad_mapper.py`](footpad_mapper.py) processing Linux `evdev` events into virtual `uinput` devices.

### 2. Running Headless HIL Tests
No physical sensors or controllers are required to contribute:
```bash
# Validate Protobuf schema:
protoc --proto_path=proto --descriptor_set_out=/dev/null proto/telemetry_bus.proto

# Run Hardware-in-the-Loop emulation benchmark (SLA: P99 < 2.5 ms):
python3 tests/mock_hardware_feeder.py --frames 1000 --rate-hz 250
```

---

## 📐 Git Workflow & Contribution Standards

1. Create a descriptive feature branch from `main` (`feature/...`, `fix/...`, `hw/...`).
2. Commit message standard: `feat(scope): description [verified: antigravity]`.
3. Before submitting a PR:
   - Caprica compiles Papyrus with **0 errors**.
   - `python3 tests/mock_hardware_feeder.py` passes cleanly.
   - No untracked build artifacts or memory dumps committed.
