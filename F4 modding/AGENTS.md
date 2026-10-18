# AGENTS.md — Fallout 4 Modding Overlay (F4 modding)

Доповнює глобальне ядро Hybrid-IDE (`~/.gemini/config/plugins/hybrid-ide/rules/AGENTS.md`). Загальні 5 фаз та OS Hard Gates діють автоматично.

## 1. Проєкт та середовище розробки
- **Призначення:** Модифікація Creation Engine, розробка скриптів Papyrus, квести та інтеграція в гру.
- **Стек:** Caprica (Wine 10), Papyrus (`.psc` ➔ `.pex`), xEdit, `capture_screen_to_git.sh`.
- **Базовий сетап:** Ванільні сигнатури та скрипти рушія у `cache/base_scripts/`.

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
