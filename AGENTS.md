# Fallout 4 Research & Modding Stand — Domain Policy Overlay (v0.9.6)

> [!IMPORTANT]
> **Policy Inheritance Anchor (Global Plugin Architecture):**  
> Цей маніфест є доменним оверлеєм над Конституційним ядром [`~/.gemini/config/plugins/hybrid-ide/rules/AGENTS.md`](file:///home/hills/.gemini/config/plugins/hybrid-ide/rules/AGENTS.md) v0.9.6.
> Базові 5 фаз життєвого циклу, апаратні шлюзи `pre_tool_hook.py`, ліміт 16 ГБ RAM, заборона моделей $\ge 14\text{B}$ локально та правила Git-First Local Access діють безумовно і не дублюються.

---

## 1. Доменне поле та апаратне середовище
- **Роль агента:** *Cyber-Physical Game Research & Creation Engine Modding Engineer*.
- **Домен:** `Fallout 4 Research & Modding Stand` (`/home/hills/Documents/fallaut`).
- **Цільовий стек:** Linux Wine 10 / DXVK 2.6 / Mesa Iris Xe (ANV 25.0.7) / DualShock 4 v2 / Hardware Pedals / OSD Audio Chimes.
- **Обов'язковий Domain Badge у Status Banner:**  
  `🎯 [DOMAIN: Fallout 4 Research Stand | HOST: Linux Wine/Intel iGPU]`

---

## 2. Інженерні стандарти Creation Engine & Wine 10

### 2.1 Пре-флайт перевірка сигнатур API (Pre-flight API Verification)
- Перед написанням чи модифікацією викликів Papyrus (особливо нативних функцій: `RemoveAllItems`, `MoveTo`, `FadeOutGame`, `OnActivate`) обов'язково перевіряти сигнатури у ванільних дефініціях:  
  `cache/base_scripts/<ScriptName>.psc`.
- Категорично заборонено писати виклики API за пам'яттю з інших ігор (наприклад, плутати 3-параметричний `RemoveAllItems` зі Skyrim із 2-параметричним у Fallout 4).

### 2.2 Стандарт компіляції Caprica через Wine 10
- Запуск компілятора Caprica виконується з захищеними змінними оточення:
  ```bash
  WINEDEBUG="-all" WINEDLLOVERRIDES="winedbg.exe=d;winemenubuilder.exe=d"
  ```
  Це виключає дедлоки Wine та блокує інтерактивний дебагер `winedbg`.
- У разі підвисання сесії обов'язково виконувати скидання: `wineserver -k`.

### 2.3 Архітектурний чек-ліст Creation Engine (NPC, квести, поселенці)
- Заборона декларативних пустишок: зміна прапорців `Protected`/`Essential` в ESP **НЕ робить NPC поселенцем**.
- Обов'язкові умови:
  1. Прив'язка `WorkshopNPCScript` до актора або аліаса.
  2. Реєстрація у `WorkshopNPCFaction` (`0x0002058E`, rank 0).
  3. Реєстрація актора через `WorkshopParentScript`.
  4. Наявність діалогових пакетів бартеру та призначення (`DialogueSettler`).

---

## 3. Діагностика, зворотний зв'язок та Live-тестування

### 3.1 Інспекція екрана гри через Git
- Заборонено прямий запуск X11-утиліт із пісочниці.
- Використовувати виключно стандартизований скрипт стенда:  
  `bash /home/hills/Documents/fallaut/capture_screen_to_git.sh "<контекст>"`  
  *(Скрипт виконує знімок, валідацію, точковий `git add -f screens/latest.png` та локальний коміт).*
- Перегляд кадру — строго через нативний `view_file` (`screens/latest.png`).

### 3.2 Консольний батник live-перевірки
- Для перевірки стану квестів і поселенців агент підтримує [`game/copilot_cmd.txt`](file:///home/hills/Documents/fallaut/game/copilot_cmd.txt) (`sqv <QuestID>`, `prid <FormID>`, фракції) для швидкого виконання у вікні гри через `bat copilot_cmd`.

### 3.3 Валідація Фази 5 для плагінів
- Перевірка розміру скомпільованого бінарника `.pex` у `game/Data/Scripts/` (розмір має бути > 0 байт).
- Заборонено звітувати про успіх, якщо байткод не розгорнуто.

---

## 4. Залізні бар'єри домену (Anti-Drift Guardrails)

1. **Zero Ad-Hoc Script Synthesis for Text (Звуження §6.1 ядра):**  
   Оскільки `game/`, `scratch/` та `Fallout4Prefs.ini` ігноруються в `.gitignore`, операція `git show` для них не діє.  
   **Читання логів (`game_crash.log`, `Papyrus.0.log`), списків плагінів (`plugins.txt`) та конфігів (`Fallout4Prefs.ini`) виконується ВИКЛЮЧНО через `view_file`.**  
   Категорично заборонено генерувати Python-скрипти через Ollama/Groq для інспекції простих текстових файлів.
2. **Zero In-Workspace AI API Clients (§8.4 ядра):**  
   Заборонено синтезувати чи запускати в `scratch/` скрипти прямого доступу до зовнішніх API (Anthropic, OpenAI, Groq). Весь ШІ-інференс делегується виключно через ядро та `diagnostic_runner.py`.
3. **Прямі правки конфігурацій гри (§6.2 ядра):**  
   Файли `Fallout4Prefs.ini`, `Fallout4Custom.ini` та `game/copilot_cmd.txt` редагуються через `replace_file_content` без створення тимчасових утиліт. Перед правкою поточні значення фіксуються у звіті.
4. **Онлайн-пуш репозиторію (Звуження §1/§8.4 ядра):**  
   Команда `git push origin` у репозиторії `fallaut` дозволена **ВИКЛЮЧНО за прямої команди користувача** і лише за умов: 0 помилок Caprica, бінарник `.pex` валідний, тестовий пакет оновлено.
