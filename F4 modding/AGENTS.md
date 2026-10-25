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
- **Tier 4 (Claude Sonnet 5.5 / Arbiter):** Обов'язкова валідація сигнатур API проти ванільних дефініцій `cache/base_scripts/<ScriptName>.psc`.
- **Tier 4.5 (Copilot CLI):** Комплексний e2e-аудит пакета мода перед релізом (`copilot --heavy-refactor`).

## 2. Цикл виконання Фази 4 (Фази 4.1 – 4.5)
- **Фаза 4.1: Pre-Execution Context Assembly:** Збирання контексту за планом (зчитування еталонних дефініцій `cache/base_scripts/<ScriptName>.psc`, системних зв'язок `WorkshopNPCScript`, F4SE, MCM та diff без виклику bash/cd).
- **Фаза 4.2: Pre-Check Gate (Claude Sonnet Arbiter):** Перевірка точних сигнатур API нативних функцій (`RemoveAllItems`, `MoveTo`, `FadeOutGame`, `OnActivate`) та валідація зібраного контексту плану. Заборонено синтез без проходження Шлюзу 4.2.
- **Фаза 4.3: AI Синтез коду (Tier 1/2):** Очищення `.psc` (Ollama) або генерація стейт-машин (Groq) з обов'язковою реєстрацією в SLSA Provenance Ledger.
- **Фаза 4.4: Детерміністична компіляція Caprica:** Компіляція `.psc` у двійковий `.pex` через Wine 10 (перевірка: розмір `.pex` > 0 байт, 0 помилок).
- **Фаза 4.5: Pre-Release Gate (Copilot CLI):** Комплексний e2e-аудит усього пакета мода перед релізом (`copilot --heavy-refactor`) за прямою згодою користувача.

## 4. Верифікація та компіляція (Фаза 5)
- **Компіляція:** Caprica через Wine 10 з `WINEDEBUG="-all"` та `WINEDLLOVERRIDES="winedbg.exe=d;winemenubuilder.exe=d"`.
- **Байткод:** Перевірка згенерованих `.pex` у цільових каталогах (розмір > 0 байт, 0 помилок).
- **Live-тест:** `bash capture_screen_to_git.sh "<контекст>"` для інспекції екрана гри та `game/copilot_cmd.txt` для перевірки стану квестів у грі (`bat copilot_cmd`).

## 5. Стиль комітів
- `<type>(f4-<scope>): <опис> [generated: <model> | verified: antigravity]`
- Передрелізний аудит: `chore(release): ... [audited: copilot-cli | verified: antigravity]`
