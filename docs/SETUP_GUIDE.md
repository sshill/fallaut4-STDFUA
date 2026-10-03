# 🎮 Посібник з розгортання та тестування Fallout 4 GOTY v1.10.163.0
## (Linux Wine / Windows + Модуль українізації + Python AI Toolchain)

**Для комітерів, інженерів та тестерів комплексу F4 HW Gaming & Neuro-Copilot**  
**For Committers, Engineers, and Testers of the F4 HW Gaming & Neuro-Copilot Stand**

---

### 🌐 Мова / Language Selector
[ 🇺🇦 **Українська інструкція** ](#ukrainian) &nbsp;|&nbsp; [ 🇬🇧 **English Instruction** ](#english)

---

<a name="ukrainian"></a>
# 🇺🇦 Українська інструкція

## 1. 🎯 Цільова версія гри та обов'язкові компоненти

Для забезпечення стабільної роботи скриптового рушія Papyrus, усунення багів таймінгу та гарантії 100% сумісності плагінів використовується виключно **класична стабільна версія (pre-Next-Gen)**:

* **Базова версія:** **Fallout 4: Game of the Year Edition (GOTY) v1.10.163.0 (64-bit)**
  * *GOG Build:* `56699004712175290` (рекомендовано, не містить DRM, стабільний запуск під Wine).
  * *Steam Depot:* Версія `1.10.163.0` (отримана через консоль `download_depot` або відкат бета-гілки pre-nextgen).
  * ⚠️ **Застереження:** Оновлення Next-Gen (`v1.10.980`–`v1.10.984`) ламають нативні виклики Papyrus, модифікатори інтерфейсу та виклики консольного мосту. Використання Next-Gen заборонено.
* **Обов'язковий набір офіційних DLC (6 із 6):**
  1. `DLCCoast.esm` (Far Harbor)
  2. `DLCNukaWorld.esm` (Nuka-World)
  3. `DLCRobot.esm` (Automatron)
  4. `DLCworkshop01.esm` (Wasteland Workshop)
  5. `DLCworkshop02.esm` (Contraptions Workshop)
  6. `DLCworkshop03.esm` (Vault-Tec Workshop)

---

## 2. 🇺🇦 Модуль українізації (Ukrainian Localization Module)

Для забезпечення повної текстової та інтерфейсної локалізації для ветеранів ЗСУ та україномовних тестерів інтегровано офіційний адаптований **Модуль українізації**:

### Структура модуля українізації:
1. **Текстові файли рядків (`Data/Strings/`):**
   * Файли перекладу базової гри: `Fallout4_en.strings`, `Fallout4_en.dlstrings`, `Fallout4_en.ilstrings`.
   * Файли перекладу всіх 6 DLC: `dlccoast_en.*`, `dlcnukaworld_en.*`, `dlcrobot_en.*`, `dlcworkshop01-03_en.*`.
   * *Примітка щодо сумісності:* Використання суфікса `_en` для українізованих рядків дозволяє рушію завантажувати український текст при системній конфігурації `sLanguage=en`, зберігаючи англійські ідентифікатори квестів для сумісності з консоллю та скриптами.
2. **Шрифти з підтримкою українських символів (`Data/Interface/`):**
   * `FontConfig.txt` — конфігуратор карт шрифтів із підтримкою специфічних літер: `Ґ, Є, І, Ї, ґ, є, і, ї` у секціях `validNameChars` та `validBookChars`.
   * `fonts_en.swf` та `fonts_console.swf` — бібліотеки шрифтів із кириличними гліфами.
   * `Translate_en.txt` та `Translations/*.txt` — переклад інтерфейсу, меню паузи та налаштувань.

### Активація в `Fallout4Custom.ini`:
```ini
[General]
sLanguage=en

[Archive]
bInvalidateOlderFiles=1
sResourceDataDirsFinal=

[Interface]
bEnableDialogueSubtitles=1
bEnableGeneralSubtitles=1
```

---

## 3. 🐧 Встановлення та налаштування на Linux (через Wine)

### Крок 1: Підготовка оточення Wine та DXVK
Стенд протестовано на **Linux Debian 13 (Trixie)** з ядром 6.12+ та **Wine 9.x / 10.x (Staging/Vanilla)**:
```bash
# Встановлення необхідних пакетів
sudo apt install -y wine wine64 dxvk gamescope xdotool
```

### Крок 2: Ініціалізація WINEPREFIX
Створіть чистий 64-бітний префікс (або використовуйте каталог `prefix/` репозиторію):
```bash
export WINEPREFIX="/home/hills/Documents/fallaut/prefix"
export WINEARCH=win64
wineboot -u
```

### Крок 3: Налаштування DXVK (Direct3D 11 -> Vulkan)
Увімкніть DXVK 2.6 для трансляції DirectX 11 у нативний Vulkan:
```bash
# Встановлення бібліотек DXVK у префікс
WINEPREFIX="$WINEPREFIX" setup_dxvk install
```

### Крок 4: Налаштування прав ядра для емуляції вводу
Для роботи `footpad_mapper.py` та віртуального геймпада потрібні права на запис у `/dev/uinput`:
```bash
# Тимчасово
sudo chmod 666 /dev/uinput

# Постійно (через udev)
echo 'KERNEL=="uinput", MODE="0666"' | sudo tee /etc/udev/rules.d/99-uinput.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Крок 5: Розгортання конфігурації та активної черги плагінів
1. Скопіюйте `Fallout4Custom.ini` у каталог:
   `$WINEPREFIX/drive_c/users/<user>/Documents/My Games/Fallout4/Fallout4Custom.ini`
2. Переконайтеся у наявності черги завантаження `plugins.txt`:
   `$WINEPREFIX/drive_c/users/<user>/AppData/Local/Fallout4/plugins.txt`
   ```
   *DLCRobot.esm
   *DLCworkshop01.esm
   *DLCCoast.esm
   *DLCworkshop02.esm
   *DLCworkshop03.esm
   *DLCNukaWorld.esm
   *VintageMannequins.esp
   *RexfordRomance.esp
   *EllieRomance.esp
   *DebCaravanRomance.esp
   *MercyRecruitment.esp
   *GentlemanOutfitReskin.esp
   ```

### Крок 6: Запуск
Використовуйте оптимізований системний скрипт:
```bash
./launch_fallout4.sh
```

---

## 4. 🪟 Встановлення та налаштування на Windows

### Крок 1: Встановлення Fallout 4 GOTY v1.10.163.0
1. Встановіть версію GOG GOTY (або попередньо завантажений Steam depot).
2. Переконайтеся, що всі 6 офіційних DLC активовані в директорії `Data/`.

### Крок 2: Встановлення Модуля українізації
1. Скопіюйте українізовані файли рядків у `<Fallout4_Root>\Data\Strings\`.
2. Скопіюйте оновлені `FontConfig.txt` та шрифти у `<Fallout4_Root>\Data\Interface\`.

### Крок 3: Конфігурація INI файлів
У каталозі `%USERPROFILE%\Documents\My Games\Fallout4\` створіть або відредагуйте `Fallout4Custom.ini`:
```ini
[General]
sLanguage=en

[Archive]
bInvalidateOlderFiles=1
sResourceDataDirsFinal=

[Papyrus]
bEnableLogging=1
bEnableTrace=1
bLoadDebugInformation=1
bEnableProfiling=0
```

### Крок 4: Розгортання плагінів
1. Скопіюйте скомпільовані моди (`.esp`) та скрипти (`.pex`) з папки `dist/mod_pack_v1.10.163/Data/` у вашу теку `<Fallout4_Root>\Data\`.
2. Увімкніть моди у `%LOCALAPPDATA%\Fallout4\plugins.txt`.

### Крок 5: Запуск тестового та AI пайплайну на Windows
Встановіть Python 3.10+ та запускайте інструменти збирання:
```cmd
python "F4 modding/f4_pipeline_router.py" --audit-all
python "F4 modding/f4_pipeline_router.py" --assemble
python tests/mock_hardware_feeder.py --frames 500
```

---

## 5. 🤖 Автоматизоване збирання модів з локальною Ollama

Для підготовки релізу або локального тестування використовуйте вбудований збірник:
```bash
python3 "F4 modding/f4_pipeline_router.py" --assemble
```
* **Що робить команда:**
  1. Сканує всі 4 модулі `staging_*` та локалізаційні асети.
  2. Копіює `.esp`, `.pex`, `.psc` у теку дистрибутива `dist/mod_pack_v1.10.163/`.
  3. Генерує маніфест збірки `dist/build_manifest.json` із хешами SHA256.
  4. Запитує локальну модель **Ollama (`qwen2.5-coder`)** на порту 11434 для перевірки відповідності вихідного коду бінарникам та відсутності сміття.
  5. Перевіряє стан Git через Python для контролю релізу.

---
---

<a name="english"></a>
# 🇬🇧 English Instruction

## 1. 🎯 Target Game Version & Mandatory Components

To guarantee deterministic Papyrus script execution, eliminate timing race conditions, and ensure 100% plugin compatibility, this stand operates strictly on the **classic stable pre-Next-Gen release**:

* **Base Version:** **Fallout 4: Game of the Year Edition (GOTY) v1.10.163.0 (64-bit)**
  * *GOG Build:* `56699004712175290` (preferred: zero DRM, clean Wine execution).
  * *Steam Depot:* `1.10.163.0` (retrieved via `download_depot` or pre-nextgen beta branch).
  * ⚠️ **Warning:** Next-Gen updates (`v1.10.980`–`v1.10.984`) break Papyrus native hooks, UI scalers, and console injection pipes. Usage of Next-Gen builds is strictly prohibited.
* **Mandatory DLC Package (6 of 6):**
  1. `DLCCoast.esm` (Far Harbor)
  2. `DLCNukaWorld.esm` (Nuka-World)
  3. `DLCRobot.esm` (Automatron)
  4. `DLCworkshop01.esm` (Wasteland Workshop)
  5. `DLCworkshop02.esm` (Contraptions Workshop)
  6. `DLCworkshop03.esm` (Vault-Tec Workshop)

---

## 2. 🇺🇦 Ukrainization Module (Text & Interface Localization)

To support Ukrainian language digital neuro-rehabilitation and research validation, an integrated **Ukrainization Module** is deployed:

### Module Anatomy:
1. **String Tables (`Data/Strings/`):**
   * Base game strings: `Fallout4_en.strings`, `Fallout4_en.dlstrings`, `Fallout4_en.ilstrings`.
   * DLC strings: `dlccoast_en.*`, `dlcnukaworld_en.*`, `dlcrobot_en.*`, `dlcworkshop01-03_en.*`.
   * *Architecture Note:* Using the `_en` suffix for Ukrainian strings enables native Cyrillic text rendering under standard `sLanguage=en` settings while maintaining full engine and quest console compatibility.
2. **Cyrillic Fonts (`Data/Interface/`):**
   * `FontConfig.txt` mapping Ukrainian characters: `Ґ, Є, І, Ї, ґ, є, і, ї` in `validNameChars` and `validBookChars`.
   * `fonts_en.swf` with full Unicode glyph support.
   * `Translate_en.txt` for HUD, Pip-Boy, and settings translation.

---

## 3. 🐧 Linux Setup Guide (Wine & DXVK)

1. **Install Dependencies:** `wine`, `wine64`, `dxvk`, `gamescope`, `xdotool`.
2. **Init WINEPREFIX:** 64-bit prefix (`WINEARCH=win64`).
3. **Configure DXVK:** Direct3D 11 to Vulkan 1.3 translation via `setup_dxvk install`.
4. **Kernel Permissions:** Grant write access to `/dev/uinput` for input emulation.
5. **Install Mod Package:** Place `.esp` and `.pex` files into `game/Data/`.
6. **Launch:** Run `./launch_fallout4.sh`.

---

## 4. 🪟 Windows Setup Guide

1. Install **Fallout 4 GOTY v1.10.163.0**.
2. Deploy strings to `Data\Strings\` and fonts to `Data\Interface\`.
3. Configure `%USERPROFILE%\Documents\My Games\Fallout4\Fallout4Custom.ini` with loose file loading and Papyrus logging.
4. Copy compiled mod files into `<Fallout4_Root>\Data\`.
5. Run Python automated validation: `python "F4 modding/f4_pipeline_router.py" --assemble`.
