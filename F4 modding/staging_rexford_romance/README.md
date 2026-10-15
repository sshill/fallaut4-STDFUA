# Rexford Romance (Hotel Rexford Magnolia Encounter Overhaul)

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
