<p align="right">
  <b>Language / Мова:</b>
  <a href="#українська-версія--ukrainian-version">🇺🇦 Українська</a> |
  <a href="#english-version--англійська-версія">🇬🇧 English</a>
</p>
<hr/>

# <a id="українська-версія--ukrainian-version"></a>🇺🇦 Rexford Romance (Hotel Rexford Magnolia Encounter Overhaul)

Модуль для **Fallout 4**, що реалізує динамічну нічну романтичну сцену, зміну гардероба на спідню білизну під час сну та ранковий діалог для Магнолії в готелі «Рексфорд» (Добросусідство).

---

## 1. Структура модуля (Directory Architecture)

```text
staging_rexford_romance/
├── RexfordRomance.esp              # Скомпільований плагін модуля (Fallout4.esm master)
├── build_rexford_romance_esp.py    # Автоматизований Python-генератор плагіна ESP (VMAD)
├── compile_rexford_scripts.py      # Раннер компіляції Papyrus через Caprica під Wine 10
├── SCENARIO.md                     # Повний опис сценарію, стейт-машини та аналіз ліжка
├── README.md                       # Цей документ: інструкція для контриб'юторів
├── Scripts/
│   └── RexfordRomanceEncounterScript.pex   # Скомпільований байткод рушія
└── Source/
    └── RexfordRomanceEncounterScript.psc   # Вихідний код скрипта Papyrus
```

---

## 2. Каталог FormID та зв'язки з Fallout4.esm

Усі об'єкти та зв'язки прив'язані до ванільних записів `Fallout4.esm` (Index 0):

| EditorID / Назва | FormID | Тип | Роль у модулі |
| :--- | :---: | :---: | :--- |
| `RexfordRomanceQuest` | `0x01000800` | `QUST` | Головний квест-контролер сцени сну (`Start Game Enabled`) |
| `DialogueGoodneighbor` | `0x00033582` | `QUST` | Ванільний квест Добросусідства (перевірка `DateComplete`, `MagnoliaFlirt`) |
| `MagnoliaREF` | `0x0002268B` | `ACHR` | Посилання на актора Магнолію |
| `HotelRexfordPlayerBed` | `0x0010C651` | `REFR` | Ліжко гравця в номері готелю Рексфорд (`GoodneighborHotelRexford`) |
| `HotelMagnoliaMarkerREF`| `0x001AD903` | `REFR` | Маркер позиціонування Магнолії в номері |
| `GoodneighborHotelRexford` | `0x00022683` | `CELL` | Клітинка готелю «Рексфорд» |
| `GoodneighborTheThirdRail` | `0x0002263E` | `CELL` | Клітинка клубу «Третя рейка» |
| `GoodneighborMagnoliaSingMarker` | `0x00075EBA` | `REFR` | Маркер мікрофона на сцені клубу (точка повернення) |
| `LoversEmbracePerkSpell` | `0x000F3C1D` | `SPEL` | Закляття баффа «Обійми коханця» (+15% до XP) |
| `MagnoliaGreetScene03` | `0x001AC13B` | `SCEN` | Ванільна ранкова сцена вітання закоханих |
| `ClothesSlinkyDress` / `ClothesMagnoliaDress` | `0x000FD9A8` | `ARMO` | Концертна сукня Магнолії (динамічне зняття/вдягання) |

---

## 3. Інструкція зі збірки (Build Instructions)

### Передумови (Prerequisites)
- **Python 3.10+** на хості Linux.
- **Wine 10** із налаштованим оточенням (префікс у `F4 modding/.wine`).
- **Caprica Compiler v3.9+** (`installer/caprica/Caprica.exe`).

### Крок 1: Збірка ESP плагіна
Генерація бінарника `RexfordRomance.esp` із коректною таблицею VMAD та прив'язкою властивостей:
```bash
python3 "F4 modding/staging_rexford_romance/build_rexford_romance_esp.py"
```

### Крок 2: Компіляція скриптів Papyrus
Компіляція `RexfordRomanceEncounterScript.psc` у байткод `.pex`:
```bash
python3 "F4 modding/staging_rexford_romance/compile_rexford_scripts.py"
```

### Крок 3: Синхронізація з каталогом гри
Скопіюйте скомпільовані файли до `game/Data/`:
```bash
cp "F4 modding/staging_rexford_romance/RexfordRomance.esp" "game/Data/RexfordRomance.esp"
cp "F4 modding/staging_rexford_romance/Scripts/RexfordRomanceEncounterScript.pex" "game/Data/Scripts/RexfordRomanceEncounterScript.pex"
cp "F4 modding/staging_rexford_romance/Source/RexfordRomanceEncounterScript.psc" "game/Data/Scripts/Source/User/RexfordRomanceEncounterScript.psc"
```

---

## 4. Протокол тестування та відладки (In-Game Debug Protocol)

### Консольний батч-файл (`copilot_cmd.txt`)
У корені `game/` налаштовано готовий скрипт пакетної діагностики. У грі натисніть `~` та виконайте:
```text
bat copilot_cmd
```

### Ручні консольні команди перевірки:
1. **Перевірка стану квесту:**
   ```text
   sqv 01000800
   ```
   *Очікуваний результат:* `Running: YES`, змінні `IsPartnerInHotel`, `ActiveHotelPartner`, `IsProcessingSleep = False`.

2. **Перевірка статусу Магнолії та аутфіту:**
   ```text
   prid 0002268b
   showinventory
   ```
   *Очікуваний результат:* наявність сукні `000FD9A8` (знята під час сну, одягнена вранці).

3. **Перевірка баффа «Обійми коханця»:**
   ```text
   player.hasspell 000F3C1D
   ```
   *Очікуваний результат:* `>> 1.00` після сну (без подвоєння).

4. **Перевірка статусу стосунків у Goodneighbor:**
   ```text
   sqv 00033582
   ```
   *Очікуваний результат:* `DateComplete = 1` або `MagnoliaFlirt = 3`.

---

## 5. Відомі особливості та Roadmap

- [x] **Реентрантний замок:** Усунено дублювання викликів `OnPlayerSleepStop`.
- [x] **Захист від дублювання діалогу:** Сцена `MagnoliaGreetScene03` запускається рівно 1 раз.
- [x] **Динамічний гардероб:** Прапорець `abPreventEquip = True` блокує авто-вдягання `DOFT`.
- [ ] **Фікс геометрії ліжка (Bed Model & Dual Actor Layout):** **TBD**. Деталі та архітектурний розбір викладено в [SCENARIO.md](SCENARIO.md).

<br/>
<hr/>
<br/>

# <a id="english-version--англійська-версія"></a>🇬🇧 Rexford Romance (Hotel Rexford Magnolia Encounter Overhaul)

A **Fallout 4** mod implementing a dynamic overnight romantic encounter, dynamic sleep wardrobe (underwear during sleep), and morning lover dialogue for Magnolia in Hotel Rexford (Goodneighbor).

---

## 1. Directory Architecture

```text
staging_rexford_romance/
├── RexfordRomance.esp              # Compiled mod plugin (Fallout4.esm master)
├── build_rexford_romance_esp.py    # Automated Python ESP record & VMAD builder
├── compile_rexford_scripts.py      # Caprica Papyrus build runner under Wine 10
├── SCENARIO.md                     # Comprehensive scenario, state machine & bed analysis
├── README.md                       # This document: contributor & setup guide
├── Scripts/
│   └── RexfordRomanceEncounterScript.pex   # Compiled Papyrus bytecode
└── Source/
    └── RexfordRomanceEncounterScript.psc   # Papyrus source script
```

---

## 2. FormID Registry & Master Cross-References

All references bind directly to vanilla `Fallout4.esm` (Index 0):

| EditorID / Name | FormID | Type | Mod Architecture Role |
| :--- | :---: | :---: | :--- |
| `RexfordRomanceQuest` | `0x01000800` | `QUST` | Master encounter quest controller (`Start Game Enabled`) |
| `DialogueGoodneighbor` | `0x00033582` | `QUST` | Vanilla Goodneighbor quest (`DateComplete`, `MagnoliaFlirt`) |
| `MagnoliaREF` | `0x0002268B` | `ACHR` | Magnolia persistent actor reference |
| `HotelRexfordPlayerBed` | `0x0010C651` | `REFR` | Player suite bed in Hotel Rexford (`GoodneighborHotelRexford`) |
| `HotelMagnoliaMarkerREF`| `0x001AD903` | `REFR` | Suite reference marker next to bed |
| `GoodneighborHotelRexford` | `0x00022683` | `CELL` | Hotel Rexford interior cell |
| `GoodneighborTheThirdRail` | `0x0002263E` | `CELL` | The Third Rail lounge club interior cell |
| `GoodneighborMagnoliaSingMarker` | `0x00075EBA` | `REFR` | Club stage microphone marker (return destination) |
| `LoversEmbracePerkSpell` | `0x000F3C1D` | `SPEL` | Lover's Embrace buff spell (+15% XP) |
| `MagnoliaGreetScene03` | `0x001AC13B` | `SCEN` | Vanilla morning lover greeting dialogue scene |
| `ClothesSlinkyDress` / `ClothesMagnoliaDress` | `0x000FD9A8` | `ARMO` | Magnolia's singer dress (stripped for sleep / re-equipped) |

---

## 3. Build & Compilation Instructions

### Prerequisites
- **Python 3.10+** on Linux host.
- **Wine 10** with configured prefix (`F4 modding/.wine`).
- **Caprica Compiler v3.9+** (`installer/caprica/Caprica.exe`).

### Step 1: Build ESP Plugin
Generate `RexfordRomance.esp` with verified VMAD properties and subrecords:
```bash
python3 "F4 modding/staging_rexford_romance/build_rexford_romance_esp.py"
```

### Step 2: Compile Papyrus Scripts
Compile `RexfordRomanceEncounterScript.psc` into `.pex` bytecode:
```bash
python3 "F4 modding/staging_rexford_romance/compile_rexford_scripts.py"
```

### Step 3: Synchronize with Game Data
Deploy the newly compiled files into `game/Data/`:
```bash
cp "F4 modding/staging_rexford_romance/RexfordRomance.esp" "game/Data/RexfordRomance.esp"
cp "F4 modding/staging_rexford_romance/Scripts/RexfordRomanceEncounterScript.pex" "game/Data/Scripts/RexfordRomanceEncounterScript.pex"
cp "F4 modding/staging_rexford_romance/Source/RexfordRomanceEncounterScript.psc" "game/Data/Scripts/Source/User/RexfordRomanceEncounterScript.psc"
```

---

## 4. In-Game Debug & Testing Protocol

### Batch Diagnostic Script (`copilot_cmd.txt`)
A pre-configured test batch is stored in `game/`. In-game, open the console (`~`) and run:
```text
bat copilot_cmd
```

### Manual Console Verification Commands:
1. **Verify Encounter Quest State:**
   ```text
   sqv 01000800
   ```
   *Expected:* `Running: YES`, variables `IsPartnerInHotel`, `ActiveHotelPartner`, `IsProcessingSleep = False`.

2. **Verify Magnolia Outfit & Inventory:**
   ```text
   prid 0002268b
   showinventory
   ```
   *Expected:* Dress `000FD9A8` present (stripped during sleep, equipped on morning wake-up).

3. **Verify Lover's Embrace Perk:**
   ```text
   player.hasspell 000F3C1D
   ```
   *Expected:* `>> 1.00` after sleep (no double stacking).

4. **Verify Goodneighbor Date Variables:**
   ```text
   sqv 00033582
   ```
   *Expected:* `DateComplete = 1` or `MagnoliaFlirt = 3`.

---

## 5. Features, Known Limitations & Roadmap

- [x] **Re-entrancy Lock:** Eliminated duplicate `OnPlayerSleepStop` dispatch calls.
- [x] **Scene Overlap Guard:** `MagnoliaGreetScene03` starts exactly once without duplicate audio lines.
- [x] **Dynamic Sleep Wardrobe:** `abPreventEquip = True` flag prevents default `DOFT` auto-reequip.
- [ ] **Bed Model Overhaul (Dual-Actor Layout):** **TBD**. Technical details and architectural breakdown are documented in [SCENARIO.md](SCENARIO.md).
