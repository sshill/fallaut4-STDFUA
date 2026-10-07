---
title: "Локальний аудит та індексація сегмента Ellie Romance (сесія 53117281)"
source_url: "conversation://53117281-e470-412a-af9f-0d8c0b735a83"
fetched_at: "2026-10-07T23:04:00"
domain: "Fallout 4 Engine / Papyrus / Creation Kit / ESP Index"
tags: [ellie_romance, dugout_inn, stage30, champollion, pex, psc, esp_parser, ollama, github_models]
content_hash_sha256: "auto"
---

# 🔍 Звіт індексації та аудиту сегмента `53117281` (Ellie Romance Overhaul)

## 1. Загальний підсумок та призначення
Сегмент реалізує сюжетну гілку романтичного оверхолу Еллі Перкінс (`EllieRomance.esp`), що включає інтерактивну сцену побачення в «Даґаут Інн» (Стадія 30), меню компліментів (+15 прихильності), кастомний напій «Піно-Нуар 2075 року», інтерактивний столик та перехід до фінальної стадії.

---

## 2. Результати декомпіляції (Champollion 1.1.3 під Wine 10)
Усі скомпільовані бінарні скрипти PEX у папці `F4 modding/staging_ellie_romance/Scripts/` опрацьовано та зафіксовано:
* `EllieWardrobeChestScript.pex` $\to$ декомпільовано в `decompiled/EllieWardrobeChestScript.psc` (0.0005 с)
* `TestQuick.pex` $\to$ декомпільовано в `decompiled/TestQuick.psc` (0.0023 с)
* `TestSimple.pex` $\to$ декомпільовано в `decompiled/TestSimple.psc` (0.0019 с)
* `EllieRomanceEncounterScript.pex` $\to$ декомпільовано частково (заголовки/властивості) через присутність опкодів Caprica debug line; повне джерело синхронізовано з канонічного `Source/EllieRomanceEncounterScript.psc`.

---

## 3. Детерміністичний розбір бінарного плагіна `EllieRomance.esp`
* **Формат:** TES4 Header (Size: 164 байти, FormID: 0x0)
* **Майстри:** `Fallout4.esm` (Index 0)
* **Загальна кількість записів:** 13
* **Каталог FormID:**
  - `0x01000810` [QUST]: `EllieRomanceQuest`
  - `0x01000820` [CONT]: `EllieWardrobeChest`
  - `0x01000850` [NPC_]: `ElliePerkinsStyled`
  - `0x01000860` [ALCH]: `EllieRomanceCountryCrossingWine`
  - `0x01000830`–`0x01000836` [MESG]: Серія з 7 діалогових та барних меню
  - `0x01000840`–`0x01000841` [SNDR]: Звукові ефекти подяки та флірту

---

## 4. [CODE_AUDIT_REPORT] Технічний висновок архітектури сцени (Стадія 30)

```markdown
[CODE_AUDIT_REPORT]
- Engine: qwen2.5-coder:1.5b (Ollama) & Antigravity Cloud Orchestrator
- Target Segment: 53117281-e470-412a-af9f-0d8c0b735a83 (staging_ellie_romance)
- Master Dependency Verdict: PASS
  * BobrovMoonshine (0x00050C28) валідовано як коректний FormID алкогольного напою Вадима у Fallout4.esm.
  * Виправлено попередню колізію з неналежним FormID вина (0x000366BF).
- Concurrency & VM Safety Verdict: PASS
  * Посадка Еллі реалізована через SnapIntoInteraction(DugoutTableChairMarker), що унеможливлює зависання колізій і навмешів.
  * Захист від nullptr для ScarlettActorRef гарантує відсутність падінь VM при відсутності Скарлетт у зоні видимості.
- Cache Strategy:
  * Повний індекс збережено в docs/knowledge/fallout/index/staging_ellie_romance_manifest.json.
  * Наступні звернення до сцени Даґаут Інн та FormID Еллі не потребують повторного бінарного чи текстового парсингу.
```
