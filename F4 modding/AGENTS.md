# AGENTS.md — Fallout 4 Modding Overlay (F4 modding)

Доповнює глобальне ядро Hybrid-IDE (`~/.gemini/config/plugins/hybrid-ide/rules/AGENTS.md`). Загальні 5 фаз та OS Hard Gates діють автоматично.

## 1. Проєкт та середовище розробки
- **Призначення:** Модифікація Creation Engine, розробка скриптів Papyrus, квести та інтеграція в гру.
- **Каталог інструментів та об'єктів стенда (Tool Catalog & Object Matrix):**
  * **Декомпілятор:** Champollion 1.1.3 (`installer/champollion/Champollion.exe` під Wine 10).
    Команда декомпіляції:
    `WINEPREFIX="/home/hills/Documents/fallaut/prefix" WINEDEBUG="-all" wine installer/champollion/Champollion.exe "<шлях.pex>" -p "Z:\\home\\hills\\Documents\\fallaut\\<вихід_Source>"`
  * **Компілятор:** Caprica (`installer/caprica/Caprica.exe` під Wine 10) з прапорцями `installer/caprica/Institute_Papyrus_Flags.flg`.
  * **Пайплайн-роутер & аудит:** `python3 "F4 modding/f4_pipeline_router.py" --audit <staging_dir>`.
  * **Консольний міст:** `game/copilot_cmd.txt` (виконання через консоль гри `bat copilot_cmd`).
  * **Знімки екрана:** `bash capture_screen_to_git.sh "<контекст>"`.
- **Джерела бінарників та кодів:**
  * Ванільні сигнатури та скрипти рушія: `cache/base_scripts/*.psc` та `cache/base_scripts/*.pex`.
  * Активні модифікації: `game/Data/Scripts/*.pex` та `game/Data/*.esp`.
  * Staging каталоги: `F4 modding/staging_<mod_name>/` (`Source/`, `Scripts/`, `build_<mod>_esp.py`).
- **Заборона AI-патчерів:** Редагування файлів виконується строго через нативний інструмент `replace_file_content`. Категорично заборонено генерувати одноразові Python-скрипти для редагування коду.
- **Dynamic Step Budget:** Фаза 4 у домені F4 modding вимагає контракту `dynamic_step_budget = 60` у `/tmp/antigravity_phase4_contract.json`.

### 1.1 Ролі ШІ у декомпіляції та модифікації Papyrus / ESP
- **Двійковий рівень (Champollion):** Детерміністична декомпіляція двійкових `.pex` у вихідний код `.psc`. Заборонено намагатися дизасемблювати бінарники через ШІ-моделі!
- **Tier 1 (Local Ollama qwen2.5-coder:1.5b):** Очищення декомпільованого `.psc` від артефактів компилятора (`::temp*`, надлишкові касти типів), генерація автономних функцій.
- **Tier 2 (Groq Cloud LPU gpt-oss-120b):** Важкий рефакторинг квестових стейт-машин, сцен діалогів та формування логіки ESP-білдерів.
- **Tier 4 (Claude Sonnet 4.1):** Обов'язкова валідація сигнатур API проти ванільних дефініцій `cache/base_scripts/<ScriptName>.psc`.
- **Tier 4.5 (Copilot CLI):** Комплексний e2e-аудит пакета мода перед релізом (`copilot --heavy-refactor`).

## 2. Шлюз 4.1: Аудит Claude Sonnet (Базовий сет F4)
- **Розширений контекст аудиту:** При аудиті коду в Фазі 4 / 4.1 Claude Sonnet аналізує **НЕ лише diff змін**, а обов'язковий **повний сет задіяних файлів із базового сетапу F4**:
  * Ванільні дефініції `cache/base_scripts/<ScriptName>.psc` для перевірки точних сигнатур нативних функцій (наприклад, `RemoveAllItems`, `MoveTo`, `FadeOutGame`, `OnActivate`).
  * Задіяні скрипти системних зв'язок (`WorkshopNPCScript`, `WorkshopParentScript`, F4SE, MCM).
- Категорично заборонено затверджувати diff без співставлення з еталонними `.psc` із базового сетапу F4.

## 3. Pre-Release Gate: Аудит GitHub Copilot CLI (Весь пакет)
- **Пакетний e2e-аудит:** Перед релізом або фінальним тегом **Tier 4.5: GitHub Copilot CLI** (`copilot --heavy-refactor`) перевіряє **ВЕСЬ пакет мода цілком** (усі залежні скрипти, конфігурації, пакети діалогів, цілісність ESP), а не лише точкові зміни.
- **Approval Gate на Copilot:** Будь-який виклик `copilot` можливий виключно після прямого підтвердження користувачем у чаті. Самовільний запуск заборонено.

## 4. Верифікація та компіляція (Фаза 5)
- **Компіляція:** Caprica через Wine 10 з `WINEDEBUG="-all"` та `WINEDLLOVERRIDES="winedbg.exe=d;winemenubuilder.exe=d"`.
- **Байткод:** Перевірка згенерованих `.pex` у цільових каталогах (розмір > 0 байт, 0 помилок).
- **Live-тест:** `bash capture_screen_to_git.sh "<контекст>"` для інспекції екрана гри та `game/copilot_cmd.txt` для перевірки стану квестів у грі (`bat copilot_cmd`).

## 5. Стиль комітів
- `<type>(f4-<scope>): <опис> [generated: <model> | verified: antigravity]`
- Передрелізний аудит: `chore(release): ... [audited: copilot-cli | verified: antigravity]`
