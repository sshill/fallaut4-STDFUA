<p align="right">
  <b>Language / Мова:</b>
  <a href="#українська-версія--ukrainian-version">🇺🇦 Українська</a> |
  <a href="#english-version--англійська-версія">🇬🇧 English</a>
</p>
<hr/>

# <a id="українська-версія--ukrainian-version"></a>🇺🇦 Сценарій та поведінкова специфікація: Rexford Romance (Магнолія)

## 1. Загальний опис та наративний контекст
Модуль **Rexford Romance** додає повноцінну циклічну постільну сцену та динамічний гардероб для Магнолії (співачки з клубу «Третя рейка», Добросусідство) у номері готелю «Рексфорд».

У ванільній грі побачення з Магнолією відбувається лише один раз через скрипт `DialogueGoodneighbor.MagnoliaDate()`, після чого романтична взаємодія фактично завершується, а повторний сон у готелі не дає романтичного контексту. Цей мод робить стосунки живими та повторюваними, інтегруючи систему динамічного сну, оновлення гардероба та нарахування бонусу відпочинку.

---

## 2. Геймплейна стейт-машина (Choreography & State Machine)

### Крок 1: Вхідні передумови (Entry Conditions)
Сцена активується у події `OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)` за дотримання таких умов:
1. `!abInterrupted` — сон завершився природно (без переривання бійкою або тривогою).
2. `isRexfordBed` — гравець спить у номері готелю «Рексфорд» (ліжко `HotelRexfordPlayerBed` `0x0010C651` або клітинка `GoodneighborHotelRexford`).
3. `magnoliaRomanced` — Магнолія успішно заромансена (у квесті `DialogueGoodneighbor` прапорець `DateComplete == 1` або значення флірту `MagnoliaFlirt >= 3`).
4. `!hasActiveRomanticCompanion` — **Запобіжник конфлікту супутників:** якщо поруч із гравцем перебуває інший активний романтичний партнер (Пайпер, Кейт, Кюрі, Данс тощо з `IsRomantic() && IsInfatuated()`), сцена з Магнолією блокується (`Return`).
5. `!IsProcessingSleep` — **Реентрантний замок:** блокує подвійний виклик обробника рушієм під час прокидання.

### Крок 2: Нічний перехід (Night Transition & Positioning)
1. Рушій запускає плавне затемнення екрана: `Game.FadeOutGame(True, True, 0.1, 2.0, True)`.
2. Магнолія телепортується у кімнату до маркеру `HotelMagnoliaMarkerREF` (`0x001AD903`) біля ліжка.
3. Очікування завантаження 3D-моделі (`chosenPartner.Is3DLoaded()`).
4. На актора накладається обмеження пересування: `chosenPartner.SetRestrained(True)`, щоб зафіксувати сцену відпочинку.

### Крок 3: Динамічний гардероб сну (Dynamic Sleep Outfit)
1. Перевірка наявності концертної сукні: `ClothesSlinkyDress` (`0x000FD9A8`). Якщо сукні немає в інвентарі, вона додається приховано (`AddItem(dress, 1, True)`).
2. **Зняття одягу з блокуванням повернення:**
   ```papyrus
   chosenPartner.UnequipItem(dress, True, True) ; abPreventEquip = True
   ```
   *Критично:* передача `abPreventEquip = True` апаратно блокує дефолтний аутфіт NPC (`DOFT` `OutfitMagnolia`) від негайного повторного вдягання сукні під час сну. Магнолія надійно залишається у спідній білизні.

### Крок 4: Нарахування романтичного бонусу
1. Перевірка наявності баффа у гравця: `!player.HasSpell(LoversEmbracePerkSpell)`.
2. Накладання закляття: `LoversEmbracePerkSpell.Cast(player, player)` (`0x000F3C1D`).
3. Виведення сповіщення: `Готель «Рексфорд»: Затишна ніч разом. Отримано «Обійми коханця».`

### Крок 5: Ранкове пробудження (Morning Wake-Up)
1. Плавне повернення світла: `Game.FadeOutGame(False, True, 0.0, 1.5, False)`.
2. **Пауза огляду (5.0 секунд):** гравець встає з ліжка та спостерігає партнерку в ранковій атмосфері.
3. Зняття обмеження руху: `chosenPartner.SetRestrained(False)`.
4. Ранкове одягання: `chosenPartner.EquipItem(dress, False, True)`.
5. Магнолія повертається обличчям до гравця: `chosenPartner.SetLookAt(player, True)` та оновлює пакети AI.
6. Запуск вітального діалогу закоханих:
   ```papyrus
   If !MagnoliaGreetScene03.IsPlaying()
       MagnoliaGreetScene03.Start()
   EndIf
   ```
   *Запобіжник:* перевірка `!IsPlaying()` усуває накладання паралельних аудіо-реплік з ванільним квестом.

### Крок 6: Розклад та повернення в клуб
1. Запуск таймера повернення: `StartTimer(180.0, 1001)`.
2. Якщо гравець відходить на відстань > 1500 одиниць або виходить із готелю, функція `ResetPartnerLocation()` відновлює сукню та повертає Магнолію до мікрофона в клубі «Третя рейка» (`GoodneighborMagnoliaSingMarker`, `0x00075EBA`).

---

## 3. Технічний аналіз нюансу з ліжком (Bed Layout & Marker Analysis)

### Поточний стан
У номері готелю встановлено ліжко `HotelRexfordPlayerBed` (`0x0010C651`).
- **Базова модель:** `NpcBedWoodLay01` (меблі типу `Furniture`).
- **Обмеження маркерів:** це класичне ванільне **одномісне** ліжко. Воно містить рівно **один меблевий маркер входу/анімації сну** (`LayEntry` / `LaySleep`).
- **Чому зазнає невдачі `SnapIntoInteraction`:** коли гравець засинає або прокидається, єдиний меблевий маркер заблокований геометрією гравця. Виклик `chosenPartner.SnapIntoInteraction(HotelRexfordPlayerBed)` отримує від рушія Creation Engine апаратну відмову (`False`), через що NPC скидався у вертикальну стоячу позу.

### Аналіз двоспального ліжка (Double Bed)
- **Атмосферний аспект:** Двоспальне розкішне ліжко (`BedDouble01` / `PrewarBedDouble`) ідеально відповідає статусу люкс-номеру та логіці сумісного нічного відпочинку.
- **Анімаційний аспект (Неформат):** Спільний одночасний сон двох акторів у Fallout 4 вимагає спарених меблевих маркерів (Left Marker + Right Marker) із чіткою синхронізацією подій анімації (`BedEntry` -> `BedSleep` -> `BedExit`). Без кастомної меблевої розмітки або сторонніх анімаційних фреймворків спроба прив'язки NPC до ліжка призводить до зсуву колізій або накладання мешів.

### Поточне стабільне рішення
Магнолія надійно позиціонується на маркері номера `HotelMagnoliaMarkerREF` (`0x001AD903`), перебуваючи безпосередньо біля ліжка у спідній білизні, що виключає падіння рушія, застрягання в текстурах та поломку анімацій.

### Статус подальшого фіксу ліжка
> [!IMPORTANT]
> **Bed Model & Multi-Actor Furniture Overhaul:** **TBD (To Be Determined)**.  
> Завдання внесено до беклогу для майбутнього етапу: створення кастомного двоспального ліжка з двома ізольованими маркерами взаємодії або налаштування безшовної idle-пози відпочинку (`PlayIdle`).

<br/>
<hr/>
<br/>

# <a id="english-version--англійська-версія"></a>🇬🇧 Encounter Scenario & Behavioral Specification: Rexford Romance (Magnolia)

## 1. Overview & Narrative Context
The **Rexford Romance** mod introduces a complete, repeatable overnight romantic bed scene and dynamic sleep wardrobe system for Magnolia (the lounge singer from The Third Rail, Goodneighbor) inside the Player's suite at Hotel Rexford.

In vanilla Fallout 4, dating Magnolia is a one-time scripted event triggered by `DialogueGoodneighbor.MagnoliaDate()`. After this encounter completes, romantic interactions cease permanently, and sleeping in Hotel Rexford provides no unique romantic ambiance. This overhaul transforms the relationship into a living, cyclic mechanic featuring dynamic wardrobe stripping, wake-up choreography, and rest perk integration.

---

## 2. Gameplay State Machine & Choreography

### Step 1: Entry Conditions
The encounter evaluates inside the `OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)` event when:
1. `!abInterrupted`: Sleep completed normally without combat alerts or interruptions.
2. `isRexfordBed`: The player slept inside Hotel Rexford (in `HotelRexfordPlayerBed` `0x0010C651` or within cell `GoodneighborHotelRexford`).
3. `magnoliaRomanced`: Magnolia has been successfully romanced in `DialogueGoodneighbor` (`DateComplete == 1` or `MagnoliaFlirt >= 3`).
4. `!hasActiveRomanticCompanion`: **Companion Conflict Guard:** If another romanced companion (Piper, Cait, Curie, Danse, etc. with `IsRomantic() && IsInfatuated()`) is present near the player, Magnolia's appearance is suppressed (`Return`).
5. `!IsProcessingSleep`: **Re-entrancy Lock:** Prevents double execution when the game engine fires multiple wake-up events.

### Step 2: Night Transition & Positioning
1. Cinematic screen fade-out: `Game.FadeOutGame(True, True, 0.1, 2.0, True)`.
2. Magnolia teleports into the suite at `HotelMagnoliaMarkerREF` (`0x001AD903`) next to the bed.
3. 3D load polling guard (`chosenPartner.Is3DLoaded()`).
4. Actor movement inhibitor enabled: `chosenPartner.SetRestrained(True)` to hold the sleep repose state.

### Step 3: Dynamic Sleep Wardrobe
1. Singer dress presence verified: `ClothesSlinkyDress` (`0x000FD9A8`). If not in inventory, silently added (`AddItem(dress, 1, True)`).
2. **Wardrobe stripping with equipment lock:**
   ```papyrus
   chosenPartner.UnequipItem(dress, True, True) ; abPreventEquip = True
   ```
   *Critical:* Setting `abPreventEquip = True` hardware-locks the engine from allowing Magnolia's default outfit (`DOFT` `OutfitMagnolia`) from auto-re-equipping the gown during sleep. She remains reliably in her underwear.

### Step 4: Romance Perk Bonus
1. Active spell check: `!player.HasSpell(LoversEmbracePerkSpell)`.
2. Spell applied: `LoversEmbracePerkSpell.Cast(player, player)` (`0x000F3C1D`).
3. On-screen notification: `Hotel Rexford: Cozy night together. Received Lover's Embrace.`

### Step 5: Morning Wake-Up & Dressing Phase
1. Morning light fade-in: `Game.FadeOutGame(False, True, 0.0, 1.5, False)`.
2. **Observation pause (5.0 seconds):** Player gets up from bed and observes Magnolia in morning repose.
3. Restraint lifted: `chosenPartner.SetRestrained(False)`.
4. Dressing back: `chosenPartner.EquipItem(dress, False, True)`.
5. Magnolia faces the player (`chosenPartner.SetLookAt(player, True)`) and refreshes AI packages.
6. Lover greeting scene started:
   ```papyrus
   If !MagnoliaGreetScene03.IsPlaying()
       MagnoliaGreetScene03.Start()
   EndIf
   ```
   *Safeguard:* Checking `!IsPlaying()` prevents overlapping dual-audio lines with vanilla scenes.

### Step 6: Return Cycle
1. Return timer started: `StartTimer(180.0, 1001)`.
2. If player leaves Hotel Rexford or distance exceeds 1500 units, `ResetPartnerLocation()` restores concert dress and returns Magnolia to her stage microphone at The Third Rail (`GoodneighborMagnoliaSingMarker`, `0x00075EBA`).

---

## 3. Technical Bed Layout & Marker Analysis

### Current State & Failure Root Cause
The room contains the reference `HotelRexfordPlayerBed` (`0x0010C651`).
- **Base Form:** `NpcBedWoodLay01` (Furniture).
- **Marker Limit:** Vanilla **single bed** containing exactly **one interaction marker** (`LayEntry` / `LaySleep`).
- **Why `SnapIntoInteraction` Fails:** When the player sleeps or wakes up, the single interaction marker is already occupied by the player's collision/animation. The Creation Engine call `chosenPartner.SnapIntoInteraction(HotelRexfordPlayerBed)` returns `False`, causing the actor to snap into an upright standing pose.

### Double Bed Feasibility Analysis
- **Atmospheric Value:** A double bed (`BedDouble01` / `PrewarBedDouble`) fits the suite aesthetics and narrative perfectly.
- **Animation Non-format Issue:** Dual simultaneous actor sleeping in Creation Engine requires paired furniture markers (Left/Right) with synchronized animation transitions (`BedEntry` -> `BedSleep` -> `BedExit`). Vanilla beds do not support two simultaneous sleeping actors without specialized multi-marker furniture records or external animation frameworks.

### Current Stable Workaround
Magnolia is positioned at `HotelMagnoliaMarkerREF` (`0x001AD903`) directly beside the bed in sleepwear, preventing physics clipping, crash-to-desktop, or broken furniture interactions.

### Roadmap & Bed Fix Status
> [!IMPORTANT]
> **Bed Model & Multi-Actor Furniture Overhaul:** **TBD (To Be Determined)**.  
> Scheduled for future milestone: creating custom dual-actor furniture markers or implementing seamless idle repose poses (`PlayIdle`).
