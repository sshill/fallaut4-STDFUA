# 📚 Fallout 4 Stand & Hardware Architecture Knowledge Base

Локальна персистентна база знань та кеш результатів досліджень для усунення повторних онлайн-запитів.
Відповідає **Рівню 3** багаторівневої ШІ-архітектури ([`GEMINI.md`](file:///home/hills/Documents/GEMINI.md)).

---

## 📂 Структура категорій знань

* `engine/`: Специфікації Creation Engine, поведінка Papyrus, таймінги, ліміти пам'яті.
* `hardware/`: Специфікації сенсорів (Polar H10, LinX CGM, DualShock 4, USB Footpad).
* `linux/`: Ядро Linux, evdev/uinput драйвери, Gamescope, AMD FSR, Vulkan 1.3, audio ALSA/Pulse.
* `modding/`: Формати `.esp`, декомпіляція `.pex`, структура записів FormID, конфлікти плагінів.

---

## 📝 Стандарт оформлення артефакту знань

Кожен файл знань зберігається у форматі `.md` із обов'язковими YAML-метаданими:

```yaml
---
title: "Назва теми або API"
source_url: "https://..."
fetched_at: "2026-10-07T21:00:00"
domain: "Fallout 4 Engine"
tags: [papyrus, timing, threads]
content_hash_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
---

# Короткий технічний огляд
...
```

---

## 🔍 Протокол використання в агентах

1. **Pre-search Lookup:** Перед зверненням до мережі виконується локальний пошук `ripgrep` по директорії `docs/knowledge/`.
2. **Commit on Discovery:** Знайдений новий контекст обов'язково оформлюється за шаблоном та комітиться в локальний Git.
