<div align="center">

# ⚡ Autonomous Multimodal Cyber-Physical Telemetry Platform & Digital Therapeutics Stand

**Closed-Loop Virtual Cognitive Stress Induction Engine | 1-ms Deterministic Telemetry Bus | AFU Veterans Neuro-Rehabilitation**  
**Автономна мультимодальна кіберфізична платформа телеметрії | 1-мс детерміністична шина | Цифрова нейрореабілітація ветеранів ЗСУ**

---

[![Linux Kernel](https://img.shields.io/badge/Kernel-evdev%20%7C%20uinput-orange?logo=linux)](https://kernel.org)
[![C Interceptor](https://img.shields.io/badge/C-LD__PRELOAD%20hidraw-blue?logo=c)](hide_hidraw.c)
[![Deterministic Bus](https://img.shields.io/badge/Telemetry-1--ms%20Deterministic%20Bus-green)](proto/telemetry_bus.proto)
[![ICD Protobuf](https://img.shields.io/badge/ICD-Protocol%20Buffers%20v3-purple?logo=google)](proto/telemetry_bus.proto)
[![Graphics](https://img.shields.io/badge/Graphics-Vulkan%201.3%20%7C%20FSR%2060FPS-red?logo=vulkan)](launch_fallout4.sh)
[![Sensors](https://img.shields.io/badge/BLE%20GATT-Polar%20H10%20%7C%20CGM%20LinX-lightgrey?logo=bluetooth)](cgm_adb_bridge.py)
[![CI / HIL](https://img.shields.io/badge/CI%20%2F%20HIL-Headless%20Emulation-success?logo=githubactions)](ci/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

### 🏛️ Executive & Architectural Artifacts / Ключові інженерні документи
[ 📄 **Bioengineering Case Study (PDF)** ](Bioengineering_Work_Example_Serhii_Khylevych.pdf) &nbsp;|&nbsp; 
[ 🏗️ **Hardware Stand Architecture Spec** ](hardware_stand_setup_and_architecture.md) &nbsp;|&nbsp; 
[ 📐 **PlantUML Architecture Diagram** ](architecture_diagram.puml)  
[ 📜 **Interface Control Document (ICD Proto)** ](proto/telemetry_bus.proto) &nbsp;|&nbsp; 
[ 🧪 **HIL Mock Feeder Benchmark** ](tests/mock_hardware_feeder.py) &nbsp;|&nbsp; 
[ 🗺️ **Grand Campaign Expansion Model** ](grand_campaign_expansion_model.md)

---

### 🌐 Мова / Language Selector
[ 🇺🇦 **Українська версія** ](#ukrainian) &nbsp;|&nbsp; [ 🇬🇧 **English Version** ](#english)

---
</div>

<a name="ukrainian"></a>
# 🇺🇦 Українська версія

## 1. 🏗️ Архітектура кіберфізичної платформи (System Architecture)

Комплекс спроектовано як високопродуктивну, детерміністичну **апаратно-програмну платформу реального часу** для дослідження когнітивних навантажень, нейромоторного тремору та вегетативних реакцій людини в замкненому контурі зворотного зв'язку (Closed-Loop Bio-Feedback).

Як керований навантажувальний симулятор застосовується віртуальне середовище *Fallout 4* (Creation Engine), що працює під керуванням **Linux Debian 13** через шар трансляції Wine/Proton із композитором **Gamescope** та апаратним масштабуванням **AMD FSR (Vulkan 1.3)** для гарантії монолітних 60 FPS без затримок черги рендерингу.

```
+-----------------------------------------------------------------------------------+
|                           ФІЗИЧНИЙ ШАР (HARDWARE LAYER)                           |
|  +--------------------+  +--------------------+  +--------------------+  +-----+  |
|  |   Polar H10 ECG    |  |    LinX CGM        |  |  DualShock 4 USB   |  | USB |  |
|  |  (BLE GATT 1-ms RR)|  | (ADB/BLE Глікемія) |  | (evdev 250 Гц стіки)|  |Pedal|  |
|  +---------+----------+  +---------+----------+  +---------+----------+  +--+--+  |
+------------|-----------------------|-----------------------|----------------|-----+
             |                       |                       |                |
             v                       v                       v                v
+-----------------------------------------------------------------------------------+
|                  ШАР ПЕРЕХОПЛЕННЯ ТА ДРАЙВЕРІВ ЯДРА (KERNEL LAYER)                |
|  * hide_hidraw.so: низькорівневий C-перехоплювач (LD_PRELOAD) для ізоляції USB     |
|  * footpad_mapper.py: обробник подій Linux evdev/uinput з нульовим оверхедом      |
|  * Синхронізація: ядровий таймер високої точності CLOCK_MONOTONIC_RAW (1-мс шкала)|
+------------------------------------+----------------------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------------------+
|               ДЕПРЕДИКАТИВНА ШИНА ТЕЛЕМЕТРІЇ (proto/telemetry_bus.proto)          |
|  * Формальний контракт ICD (Protocol Buffers v3)                                  |
|  * stand_monitor.py: агрегація RR/RMSSD, індексу Баєвського, тремору та глікемії  |
|  * Бюджет затримки обробки: Mean < 20 мкс, P99 джиттер < 0.005 мс                 |
+------------------------------------+----------------------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------------------+
|         КЕРОВАНИЙ КОГНІТИВНИЙ СИМУЛЯТОР (CLOSED-LOOP SIMULATION WORKLOAD)          |
|  * Bethesda Creation Engine (Fallout 4 @ Linux Wine / Gamescope / Vulkan 1.3 FSR)  |
|  * Двостороння синхронізація: двоекранний стенд (1080p60 TV + Research Dashboard) |
|  * Papyrus Event Stream: маркування фізіологічних сплесків бойовими івентами      |
+-----------------------------------------------------------------------------------+
```

---

## 2. 📜 Формальний контракт шини (ICD) та апаратна емуляція (HIL)

Для забезпечення промислової надійності, відсутності затримок та модульної інтеграції в репозиторії реалізовано:

1. **Interface Control Document (ICD):** [`proto/telemetry_bus.proto`](proto/telemetry_bus.proto)
   * Формальний контракт 1-мс бінарного телеметричного кадру.
   * Передає: `timestamp_raw_ns`, `ecg_rr_ms`, `hrv_rmssd`, `stress_index` (Баєвського), `cgm_glucose_mmol`, координати аналогових стіків `motor_axis_x/y`, спектральну частоту мікротремору `aim_jitter_hz` (8–12 Гц), маску педалей `foot_pedal_mask` та ідентифікатор ігрової події `engine_event_id`.
2. **Hardware-in-the-Loop (HIL) Headless Benchmark:** [`tests/mock_hardware_feeder.py`](tests/mock_hardware_feeder.py)
   * Емулює роботу повного апаратного комплексу без фізичних датчиків та Bluetooth.
   * Перевіряє детермінізм таймінгу, цілісність серіалізації/десеріалізації та відповідність SLA ($P_{99} \text{ jitter} < 2.5$ мс).
   * **Запуск тесту:**
     ```bash
     python3 tests/mock_hardware_feeder.py --frames 1000 --rate-hz 250
     ```
3. **Автоматизований CI/CD конвеєр:** [`ci/ci.yml`](ci/ci.yml)
   * Виконує автоматичну валідацію синтаксису схеми Protobuf через `protoc`.
   * Здійснює компіляційний аудит вихідних Python-модулів платформи.
   * Запускає HIL-тест на headless-віртуальних машинах GitHub Actions.

---

## 3. 🎯 Місія цифрової терапії (Digital Therapeutics / DTx)

Програмно-апаратний комплекс розроблено як науково-терапевтичний стенд для **ветеранів Збройних Сил України (ЗСУ)** та цивільних осіб, які пережили бойові травми, вибухові хвилі або хронічний психотравмуючий стрес (ПТСР).

### Терапевтичний механізм:
* **Відновлення локусу контролю (Agency Restoration):** Бойовий стрес провокує руйнування суб'єктивного контролю над подіями та виснаження осі HPA. Роль **«Hands-on Architect» (Верховного Директора та Архітектора Співдружності)** реконструює відчуття тотальної агентності, структурованості та передбачуваності світу.
* **Вхід у стан потоку (Flow State) та спалювання кортизолу:** Інтенсивна системно-інженерна діяльність блокує патологічну активність зони румінацій мозку (Default Mode Network, DMN) і посилює парасимпатичний тонус блукаючого нерва (зростання показника HRV RMSSD).
* **Специфікація клінічного кейсу:** Повний науково-медичний опис платформи опубліковано у документі **[Bioengineering Work Example (PDF)](Bioengineering_Work_Example_Serhii_Khylevych.pdf)**.

---

## 4. 🗺️ Генеральний дизайн розширення (Grand Campaign Expansion Model)

Канонічний сюжет *Fallout 4* штучно нав'язує взаємне знищення фракцій. Дана модель впроваджує **єдиний геополітичний театр Співдружності**, де гравець виступає як **«Hands-on Architect»**, консолідуючи всі сили у складі **Об'єднаної Армії Співдружності (ОАС)** проти спільного зовнішнього ворога — **Альянсу**.

```
                                  [ СТАВКА ДИРЕКТОРАТА / ГРАВЕЦЬ ]
                                                  │
         ┌────────────────────────────────────────┼────────────────────────────────────────┐
         ▼                                        ▼                                        ▼
[ ВІЙСЬКОВО-ОПЕРАТИВНИЙ СЕКТОР ]       [ ЦИВІЛЬНО-ЛОГІСТИЧНИЙ СЕКТОР ]          [ НАУКОВО-ТЕХНОЛОГІЧНИЙ СЕКТОР ]
• Братство Сталі (ВПС та Ліберті Прайм) • Мер Даймонд-Сіті (Пайпер Райт)        • Заступник з НДДКР: Кюрі (Curie)
• QRF Мисливці Інституту (X6-88)        • Медіа-холдинг (Тревіс + Срібний Плащ)  • Лабораторія біохімії (Ліззі Ваєт)
• Артилерія Мінітменів (Ронні Шоу)      • Торгова мережа караванів (Кесслер)     • Конструкторське бюро РЕБ (Тінкер Том)
• Прикордонна охорона (Престон Ґарві)   • Стратегічні резерви (Кодсворт)         • Ядерні системи та флот (ДіМА)
• Підземний Корпус Гулів (Хенкок)       • Детективна юстиція (Нік Валентайн)     • Військово-польова медицина (Нерая)
• ВМС і підводний флот («Янцзи-31»)                                              • НДІ генетики ВРЕ (Д-р Вірджил)
• Снайпери Операторів (Маккріді)                                                 • Кібернетика та Автоматрони (Ада)
• Штурмовики CQB Зграї (Кейт)
• Трьохкомпонентний Радіаційний Корпус
  (Супермутанти + Діти Атома + Звірі через Псину)
• Мобільна бронекавалерія (Атомні Коти)
• Іноземний Легіон (Стрільці)
• Береговий бастіон (Барні Рук, Салем)
```

### 11 Секторальних формувань ОАС:
1. **Братство Сталі (Бойове крило, ВПС та Ліберті Прайм):**
   * *Паладин Денс:* Моральний лідер, Новий Лицарський Кодекс (захист мирних, відмова від геноциду). Відновлення бази Національної Гвардії (`DN053`) зі Скриптором Гейлен.
   * *Доктрина «Анти-Ямато» (Ліберті Прайм «Оптімус»):* 5-ешелонна парасолька захисту (ВПС Денса, РЕБ Ади/Тома, периметр ніг Зграї/Паладинів, контрснайпери Маккріді). Прайм виступає стратегічною приманкою для виманювання важкої техніки Альянсу під удари мортир.
   * *Проєкт «Чинук»:* Важкий десантний гвинтокрил (Інграм + Advanced Systems) для перекидання підрозділів у силовій броні та мутантів.
2. **Підземка (The Railroad — Кібер-РЕБ та Чорні Операції):**
   * *Тінкер Том:* Контр-глушники проти квантових реле Альянсу, тактичне шифрування зв'язку.
   * *Дікон:* Глибока тилова розвідка (Black Ops), дезінформація та диверсії.
   * *Дездемона:* Мережа агентурно-торгової контррозвідки.
3. **Інститут (Науково-технологічний авангард та QRF):**
   * *Кюрі (Curie):* Перший заступник Директора з НДДКР із мандатом координації всіх вчених Співдружності.
   * *Мисливці Gen-3 та X6-88:* Загони швидкого реагування (QRF) — миттєві телепортаційні перехвати диверсантів без детонацій для людей.
   * *Реформація Інституту:* Демонтаж карального SRB (Джастін Айо), вихід на поверхню, цивільні медичні біотехнології.
4. **Мінітмени (Артилерійський корпус та Прикордонний щит):**
   * *Ронні Шоу:* Артилерійський Корпус форту «Замок» (централізована мережа мортир для артпідготовки за викликом офіцерів ОАС).
   * *Престон Ґарві:* Прикордонна охорона півночі (Сенкчуарі — Зімонджа), коридори з Ядер-Світом.
   * *Стерджес:* Інженерна модернізація радіовеж та ретрансляторів.
5. **Добросусідство та Підземний Корпус Гулів (Тіньовий фронт):**
   * *Джон Хенкок та Слог (Вайзман):* Контроль підземних комунікацій (метро MBTA, зливові колектори).
   * *Бета-хвильова інтеграція диких гулів:* Керування зграями диких гулів через синхронізацію бета-хвиль для раптових штурмів (Hyper-Speed CQB).
6. **Військово-Морські Сили ДіМА (Акадія, Фар-Гарбор & Субмарина «Янцзи-31»):**
   * *База «Ядро» (The Nucleus):* Підземний сухий док із атомним реактором для ремонту субмарин.
   * *Синти-підводники:* Екіпаж Акадії, стійкий до радіації реактора та автономний без кисню.
   * *Флагман «Янцзи-31»:* Капітан Цзао передає командування штабу ДіМА; балістичні ракети формують протидесантний щит Атлантики.
   * *Старий Лонгфелло:* Командувач морського ополчення Острова.
7. **Ядер-Світ (Буферний Західний Щит: Оператори та Зграя):**
   * *Портер Ґейдж:* Логістичний комендант вузла монорейки.
   * *Снайпери (Роберт Маккріді):* Контрснайперська парасолька дахів, далекобійна ліквідація офіцерів ворога.
   * *Штурмовики CQB (Кейт):* Штурмові групи зачистки вузьких бункерів.
   * *Токсикологія (Ліззі Ваєт):* Сироватки переконання «Persuasion-X» та стимулятори «Operator Focus».
8. **Трьохкомпонентний Радіаційний Штурмовий Корпус (Сяюче Море):**
   * *Супермутанти (Верховний Вождь Силач та Д-р Вірджил):* Стабілізуючий штам «ВРЕ-7/C» повертає мутантам розум та військову дисципліну зі збереженням сили і 100% радіо-імунітету. Силач очолює Раду Вождів Півдня.
   * *Діти Атома (Проповідник, Зилот Ріхтер, Мати Ізольда):* Офіцери зв'язку, навігація радіаційними коридорами, онфілд-супорт та польова радіо-терапія.
   * *Бойові Звірі Співдружності:* Радіаційні гончаки, яо-гаї та штурмові кігті смерті (імунітет 20–100+ рад/с). **Керування та дисциплінування здійснюється через Псину (Dogmeat) як Вівчара-Альфу** разом із Мезоном.
   * *Доктрина «Удар з Епіцентру»:* Облога підземної цитаделі Альянсу у Сентинел-Сайт прямо крізь епіцентр ядерного шторму.
9. **Периферія та Охорона Караванів:**
   * *Атомні Коти (Зік):* Мобільна бронекавалерія, швидкісний тюнінг екзоскелетів.
   * *Стрільці:* Ліквідація зрадників-командирів, амністія та перетворення на Іноземний Легіон Директората.
   * *Барні Рук (Салем):* Автоматизована квантова берегова мережа «Реба».
   * *Кесслер (Банкер-Гілл) та Кодсворт (Сенкчуарі):* Торгова караванна логістика та стратегічний облік арсеналів.
   * *Пайпер Райт:* Законний мер Даймонд-Сіті, об'єднаний медіа-холдинг (радіо Тревіса + Срібний Плащ).
10. **Інженерно-бойовий регламент (Мульти-сетап 2x):**
   * Ліміт сцени: 14–18 активних акторів (7 бійців ОАС + 7 ворогів + Гравець + Ада) для збереження монолітних 60 FPS.
   * Гравець як Верховний Оркестратор через тактичний радіо-канал Піп-Боя та Recon-маркери.
11. **Bio-Feedback регулювання темпу:**
   * Автоматичне коригування спавну та складності під керуванням RMSSD датчика Polar H10.

---

## 5. 🛠️ Статус розробки та беклог модулів

| Модуль / Мод | Версія | Призначення | Поточний статус |
| :--- | :---: | :--- | :--- |
| **`proto/telemetry_bus.proto`** | `v1.0` | Формальний контракт 1-мс телеметричного кадру шини. | **Готово:** Повна валідація синтаксису, інтегровано в CI. |
| **`tests/mock_hardware_feeder.py`** | `v1.0` | HIL емуляційний тест та бенчмарк джиттера без заліза. | **Готово:** Проходить тестування із затримкою $<20$ мкс. |
| **`ci/ci.yml`** | `v1.0` | Автоматизований CI/CD конвеєр перевірки коду та ICD. | **Готово:** Налаштовано автоматичний запуск на GitHub. |
| **`RexfordRomance`** | `v0.2` | Розширена сюжетна та романтична лінія (Hotel Rexford). | **Готово:** Усунуто збій зв'язування сцени `MagnoliaMorningTopic`. |
| **`EllieRomance`** | `v0.2` | Сюжетна та романтична лінія Еллі Перкінс. | **Готово:** Ліквідовано зависання консольної ін'єкції у детективному агентстві. |
| **`MercyRecruitment`** | `v0.1` | Система вербування лідерів Стрільців (Шеллі Тіллер). | **Готово:** Базовий білд плагіна та скрипти Papyrus (`.pex`). |
| **`GentlemanOutfitReskin`** | `v1.0` | Модульний рескін смокінга та костюмів персонажів. | **Готово:** Повністю робочий плагін та генератор збірки. |
| **`f4_pipeline_router.py`** | `v1.1` | Гібридний ШІ-роутер (Ollama + GitHub Models) та Git-пайплайн. | **Готово:** Автоматизація білдів, аудитів та мережевого push. |

---

## 6. 🤝 Ліцензія та участь у проєкті

Проєкт відкрито для дослідників, ветеранів та розробників на умовах **[MIT License](LICENSE)**.

---
---

<a name="english"></a>
# 🇬🇧 English Version

## 1. 🏗️ Cyber-Physical Platform Architecture

This project is engineered as a high-performance, deterministic **real-time cyber-physical platform** designed for multimodal research into cognitive load, neuromotor tremor, and autonomic nervous system dynamics in a closed-loop bio-feedback architecture.

As an immersive virtual stress induction engine, the platform integrates *Fallout 4* (Bethesda Creation Engine) running on **Linux Debian 13** via Wine/Proton with **Gamescope** compositing and hardware-accelerated **AMD FSR (Vulkan 1.3)** to lock frame delivery at 60 FPS without rendering pipeline stalls.

```
+-----------------------------------------------------------------------------------+
|                            PHYSICAL SENSOR & ACTUATOR LAYER                       |
|  +--------------------+  +--------------------+  +--------------------+  +-----+  |
|  |   Polar H10 ECG    |  |    LinX CGM        |  |  DualShock 4 USB   |  | USB |  |
|  |  (BLE GATT 1-ms RR)|  |  (ADB/BLE Glucose) |  | (evdev 250 Hz axes)|  |Pedal|  |
|  +---------+----------+  +---------+----------+  +---------+----------+  +--+--+  |
+------------|-----------------------|-----------------------|----------------|-----+
             |                       |                       |                |
             v                       v                       v                v
+-----------------------------------------------------------------------------------+
|                    KERNEL INTERCEPTION & DRIVER LAYER (LINUX)                     |
|  * hide_hidraw.so: Low-level C interceptor (LD_PRELOAD) for hardware isolation    |
|  * footpad_mapper.py: Zero-overhead Linux evdev / uinput event processing loop    |
|  * Nanosecond timebase: Linux kernel CLOCK_MONOTONIC_RAW (1-ms deterministic bus) |
+------------------------------------+----------------------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------------------+
|               DETERMINISTIC TELEMETRY BUS (proto/telemetry_bus.proto)             |
|  * Formal Interface Control Document (ICD) via Protocol Buffers v3                |
|  * stand_monitor.py: Real-time RR/RMSSD, Baevsky index, tremor, & glucose parsing |
|  * Latency Budget: Mean Ingestion < 20 µs, P99 Schedule Jitter < 0.005 ms         |
+------------------------------------+----------------------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------------------+
|               CLOSED-LOOP VIRTUAL COGNITIVE STRESS INDUCTION WORKLOAD             |
|  * Bethesda Creation Engine (Fallout 4 @ Linux Wine / Gamescope / Vulkan 1.3 FSR) |
|  * Dual-Screen Stand Topology: 1080p60 TV (Stimulus) + Laptop Dashboard (Telemetry)|
|  * Papyrus Event Stream: Real-time correlation between combat events & physiology |
+-----------------------------------------------------------------------------------+
```

---

## 2. 📜 Interface Control Document (ICD) & HIL Emulation Harness

To guarantee mission-critical reliability, sub-millisecond response times, and clean modular decoupling:

1. **Formal Interface Control Document (ICD):** [`proto/telemetry_bus.proto`](proto/telemetry_bus.proto)
   * Defines the 1-ms binary telemetry frame protocol.
   * Transmits: `timestamp_raw_ns`, `ecg_rr_ms`, `hrv_rmssd`, `stress_index` (Baevsky), `cgm_glucose_mmol`, normalized stick coordinates `motor_axis_x/y`, aim micro-tremor frequency `aim_jitter_hz` (8–12 Hz), foot switch bitmask `foot_pedal_mask`, and game event ID `engine_event_id`.
2. **Hardware-in-the-Loop (HIL) Headless Feeder:** [`tests/mock_hardware_feeder.py`](tests/mock_hardware_feeder.py)
   * Emulates the complete multi-sensor hardware array in headless CI runners without physical devices or root permissions.
   * Audits scheduling jitter, binary packing roundtrip integrity, and strict SLA compliance ($P_{99} \text{ jitter} < 2.5$ ms).
   * **Execution Command:**
     ```bash
     python3 tests/mock_hardware_feeder.py --frames 1000 --rate-hz 250
     ```
3. **Automated CI/CD Workflow:** [`ci/ci.yml`](ci/ci.yml)
   * Verifies Protobuf schema compilation using `protoc`.
   * Performs compilation syntax audits on all Python platform services.
   * Executes headless HIL benchmark runs on GitHub Actions runners.

---

## 3. 🎯 Digital Therapeutics (DTx) Mission

The platform serves as a digital neuro-rehabilitation and cognitive recovery apparatus designed for **Armed Forces of Ukraine (AFU) veterans** and civilians suffering from combat trauma, blast wave exposure, or chronic Post-Traumatic Stress Disorder (PTSD).

### Therapeutic Mechanisms:
* **Agency Restoration:** Combat-induced trauma destabilizes internal locus of control and exhausts the hypothalamic-pituitary-adrenal (HPA) axis. Taking on the role of the **"Hands-on Architect" (Supreme Director and Architect of the Commonwealth)** systematically rebuilds subjective predictability, structure, and total environmental agency.
* **Flow State Induction & Cortisol Burn-off:** Deep immersive architectural gameplay halts rumination within the brain's Default Mode Network (DMN), restoring vagal parasympathetic tone (verified by increased RMSSD heart rate variability).
* **Clinical Case Specification:** A detailed scientific assessment is documented in the **[Bioengineering Work Example (PDF)](Bioengineering_Work_Example_Serhii_Khylevych.pdf)**.

---

## 4. 🗺️ Grand Campaign Expansion Model

Overcoming the artificial faction mutual-destruction constraints of *Fallout 4*, this model introduces a **unified geopolitical Commonwealth theater**, positioning the player as the **"Hands-on Architect"** uniting all factions under the **United Commonwealth Army (UCA)** against an external technological invader — **The Alliance**.

```
                                [ DIRECTORATE HEADQUARTERS / PLAYER ]
                                                  │
         ┌────────────────────────────────────────┼────────────────────────────────────────┐
         ▼                                        ▼                                        ▼
[ MILITARY & OPERATIONAL SECTOR ]       [ CIVILIAN & LOGISTICS SECTOR ]          [ SCIENCE & TECHNOLOGY SECTOR ]
• Brotherhood of Steel (AF & Prime)     • Mayor of Diamond City (Piper Wright)   • Deputy for R&D: Curie (Curie)
• QRF Courser Units (X6-88)             • Media Conglomerate (Travis + Shroud)   • Toxicology Lab (Lizzie Wyath)
• Minutemen Artillery (Ronnie Shaw)     • Caravan Supply Network (Kessler)       • EW Engineering Bureau (Tinker Tom)
• Northern Frontier (Preston Garvey)    • Strategic Reserves (Codsworth)         • Nuclear Systems & Fleet (DiMA)
• Subterranean Ghoul Corps (Hancock)    • Detective Justice (Nick Valentine)     • Field Trauma Medicine (Neriah)
• Naval Fleet & Submarine (Yangtze-31)                                           • FEV Genetics Institute (Virgil)
• Operator Snipers (RJ MacCready)                                                • Cybernetics & Automatrons (Ada)
• Pack CQB Shock Troops (Cait)
• Tri-Component Radiation Corps
  (Supermutants + Children of Atom + Beasts via Dogmeat)
• Mobile Armored Cavalry (Atom Cats)
• Foreign Legion (Gunners)
• Coastal Bastion (Barney Rook, Salem)
```

### 11 Sectoral Modules of the UCA:
1. **Brotherhood of Steel (Strike Wing, Heavy Aviation & Liberty Prime):**
   * *Paladin Danse:* Moral leader, author of the New Knightly Code (protecting civilians, rejecting genocide). Restores National Guard Training Annex (`DN053`) with Scribe Haylen.
   * *"Anti-Yamato" Doctrine (Liberty Prime "Optimus"):* 5-tier protective umbrella (Danse's CAS, Ada/Tom's EW/Cyber shield, Pack/Paladin perimeter defense, MacCready's counter-snipers). Prime acts as strategic bait, drawing heavy armor into Minutemen artillery kill-zones.
   * *Project "Chinook":* Heavy tandem-rotor dropship (Ingram + Advanced Systems) for tactical deployment of Power Armor shock troops and supermutants.
2. **The Railroad (Cyber-EW & Black Operations):**
   * *Tinker Tom:* Counter-jammers targeting Alliance quantum relays, full-spectrum encrypted communications.
   * *Deacon:* Rear-echelon reconnaissance (Black Ops), disinformation, and munitions sabotage.
   * *Desdemona:* Clandestine intelligence and trade observation network.
3. **The Institute (Advanced R&D Vanguard & QRF):**
   * *Curie (Curie):* First Deputy Director for Advanced R&D with supreme oversight over all Commonwealth laboratories.
   * *Courser Quick Reaction Force (QRF) — X6-88:* Instant quantum teleportation intercepts against hostile breach squads.
   * *Institute Reformation:* Dismantling the punitive Synth Retention Bureau, surfacing above ground, and deploying peaceful water purification and medicine.
4. **Minutemen (Artillery Corps & Frontier Border Guard):**
   * *Ronnie Shaw:* Artillery Corps commander at The Castle (coordinated network of long-range mortars on call for all allied commanders).
   * *Preston Garvey:* Northern Frontier border guard (Sanctuary to Zimonja), demarcating transit zones with Nuka-World.
   * *Sturges:* Engineering modernization of radio repeaters and relay towers.
5. **Goodneighbor & Subterranean Ghoul Corps (Underground Front):**
   * *John Hancock & The Slog (Wiseman):* Mastery over Greater Boston's underground arteries (MBTA subway tunnels, storm drains).
   * *Beta-Wave Feral Ghoul Integration:* Synchronized brainwave patterns allowing deployment of feral hordes as rapid CQB shock ambushes.
6. **DiMA's Naval Forces (Acadia, Far Harbor & Submarine "Yangtze-31"):**
   * *"The Nucleus" Submarine Base:* Drydock and reactor-powered naval overhaul station.
   * *Synthetic Submariners:* Radiation-immune, oxygen-independent synth crew.
   * *Flagship "Yangtze-31":* Captain Zao cedes command to DiMA; nuclear ballistic missiles form an Atlantic anti-amphibious defense screen.
   * *Old Longfellow:* Maritime coastal militia commander.
7. **Nuka-World (Western Buffer Shield: Operators & The Pack):**
   * *Porter Gage:* Logistics commander of the Nuka-Express monorail network.
   * *Sniper Corps (Robert Joseph MacCready):* Rooftop overwatch, long-range silenced elimination of Alliance officers.
   * *CQB Assault Corps (Cait):* Fortified bunker breach tactics in close quarters.
   * *Toxicology Lab (Lizzie Wyath):* "Persuasion-X" non-lethal submission aerosols and combat stimulants.
8. **Tri-Component Radiation Assault Corps (The Glowing Sea):**
   * *Supermutant Vanguard (High Warlord Strong & Dr. Virgil):* Stabilized "FEV-7/C" strain restores cognition, speech, and tactical discipline while retaining 100% radiation immunity. Strong leads the Southern Warlords Council.
   * *Children of Atom (Preacher, Grand Zealot Richter, Mother Isolde):* Tactical communications, radiation corridor navigators, field radiation therapy, and gamma suppressive fire.
   * *Beasts of the Commonwealth:* Irradiated hounds, glowing yao guai, and deathclaws. **Beast discipline and combat coordination is directed by Dogmeat as the Alpha Shepherd** paired with Mason.
   * *"Epicenter Strike" Doctrine:* Sustained siege of the Alliance's underground fortress at Sentinel Site directly through catastrophic radiation storms.
9. **Periphery Formations & Caravan Security:**
   * *Atom Cats (Zeke):* Armored cavalry patrol battalion, highway security, high-speed power armor tuning.
   * *Gunners:* Purging rogue commanders; general amnesty transforming personnel into the Directorate's Foreign Legion.
   * *Barney Rook (Salem):* Automated quantum-targeted "Reba" coastal defense battery.
   * *Kessler (Bunker Hill) & Codsworth (Sanctuary):* Rapid-deployment caravan supply network and munitions accounting.
   * *Piper Wright:* Duly elected Mayor of Diamond City, director of the unified public radio network.
10. **Engine Combat Architecture (Symmetrical 2x Multi-Setup):**
   * Strict 14–18 actor scene budget (7 allies + 7 enemies + Player + Ada) maintaining solid 60 FPS without Papyrus script stalls.
   * Player as Supreme Battlefield Orchestrator via Pip-Boy Tactical Command Channel and Recon Designators.
11. **Bio-Feedback Pacing:**
   * Real-time dynamic encounter difficulty modulation driven by Polar H10 RMSSD heart rate variability.

---

## 5. 🛠️ Platform Components & Development Backlog

| Component / Module | Version | Purpose | Status |
| :--- | :---: | :--- | :--- |
| **`proto/telemetry_bus.proto`** | `v1.0` | Formal 1-ms deterministic telemetry frame ICD. | **Complete:** Fully validated schema, integrated in CI. |
| **`tests/mock_hardware_feeder.py`** | `v1.0` | Headless HIL emulation harness & jitter benchmark. | **Complete:** Fully passing, $<20$ µs mean latency. |
| **`ci/ci.yml`** | `v1.0` | GitHub Actions CI workflow for ICD & HIL verification. | **Complete:** Configured for automated push/PR runs. |
| **`RexfordRomance`** | `v0.2` | Extended narrative arc for Hotel Rexford. | **Complete:** Resolved SCEN subtype binding fault. |
| **`EllieRomance`** | `v0.2` | Ellie Perkins romance and companion arc. | **Complete:** Fixed interior cell console stall in detective agency. |
| **`MercyRecruitment`** | `v0.1` | Gunner recruitment system and unique perks. | **Complete:** Compiled Papyrus scripts (`.pex`) and `.esp` baseline. |
| **`GentlemanOutfitReskin`** | `v1.0` | Tuxedo reskin and modular visual overrides. | **Complete:** Functional mod and automated build script. |
| **`f4_pipeline_router.py`** | `v1.1` | Hybrid AI Router (Ollama + GitHub Models) & Git manager. | **Complete:** Automated builds, audits, and remote push. |

---

## 6. 🤝 Contributing & License

This project is open-source under the **[MIT License](LICENSE)**. Contributions from researchers, veterans, modders, and systems engineers are welcome.
