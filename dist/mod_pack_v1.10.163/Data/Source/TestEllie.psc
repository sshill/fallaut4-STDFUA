ScriptName TestEllie Extends Quest

;-- Verified FormIDs from Fallout4.esm ---------------------
Actor Property EllieREF Auto
ObjectReference Property DugoutInnPlayerBed Auto
ObjectReference Property EllieDeskMarker Auto
Spell Property LoversEmbracePerkSpell Auto Const
Quest Property MQ104 Auto Const ; 0x0001F25E (Unlikely Valentine)

; Evening Dresses (Вечірні сукні для побачень та Даґаут Інн)
Armor Property EveningSlinkyDress Auto Const ; 0x000FD9A8 ClothesSlinkyDress (Червона сукня Магнолії)
Armor Property EveningSequinDress Auto Const ; 0x0011A27B ClothesSequinDress (Сукня з блискітками)

; Day / Business / Clean Dresses (Ошатні ділові сукні для детективного агентства)
Armor Property CleanGreenDress Auto Const    ; 0x000EECF5 ClothesPreWarDress (Випране зелене плаття / Ошатна зелена сукня)
Armor Property CleanRedDress Auto Const      ; 0x002075C1 ClothesPreWarDressPink (Випране червоне плаття / Ошатна червона сукня)
Armor Property CleanRoseDress Auto Const     ; 0x002075BF ClothesPrewarHouseDressB (Випране рожеве плаття)
Armor Property CleanBlueDress Auto Const     ; 0x0014D08F ClothesPrewarHouseDress (Випране блакитне плаття)
Armor Property CleanDenimDress Auto Const    ; 0x002075C0 ClothesPreWarDressBlue (Випране джинсове плаття)
Armor Property CleanCreamDress Auto Const    ; 0x002075BE ClothesPrewarHouseDressA (Випране кремове плаття)

; UI, Container & Audio
Message Property EllieDialogueMessage Auto Const ; 0x01000830 MESG
Sound Property EllieGratitudeSound Auto Const    ; 0x01000840 SNDR («Спасибі тобі.»)
Sound Property EllieFlirtSound Auto Const        ; 0x01000841 SNDR («Все гаразд, сонечко?»)
Idle Property LaughingSittingIdle Auto Const     ; 0x00118015 ActionCustomLaughingSittingA
Idle Property LaughingStandingIdle Auto Const    ; 0x00118013 ActionCustomLaughingStandingA
Container Property WardrobeChestBase Auto Const  ; 0x01000820 CONT (Гардероб Еллі)
ObjectReference Property WardrobeChestRef Auto   ; Runtime placed chest ref

;-- Quest & Affinity State ---------------------------------
Int Property RomanceStage = 0 Auto
; 0  = Неактивний (очікує ручного початку діалогу [E])
; 10 = Гардероб не зібрано / збір суконь (щонайменше 4, з них 1+ вечірня)
; 20 = Гардероб зібрано -> Етап перукарні Джона
; 30 = Затишний вечір у Даґаут Інн
; 100 = Романтичні стосунки активні

Bool Property IsRomanced = False Auto

; Dress counters
Int Property TotalDressesGiven = 0 Auto
Int Property EveningDressesGiven = 0 Auto
Int Property DayDressesGiven = 0 Auto

; Active visual styles
Int Property ActiveDayDressIndex = 0 Auto     ; 0=Зелена, 1=Червона, 2=Рожева, 3=Блакитна, 4=Джинсова, 5=Кремова
Int Property ActiveEveningDressIndex = 0 Auto ; 0=Червона шовкова, 1=З блискітками
Int Property CurrentHairstyleIndex = 0 Auto   ; Пресет зачіски та макіяжу

Bool Property EnableDynamicOutfits = True Auto
Bool Property AutoReturnAfterDelay = True Auto
Float Property ReturnDelaySeconds = 180.0 Auto

; Tracking unique wardrobe ownership (only 1 of each variant accepted)
Bool Property HasSlinky = False Auto
Bool Property HasSequin = False Auto
Bool Property HasCleanGreen = False Auto
Bool Property HasCleanRed = False Auto
Bool Property HasCleanRose = False Auto
Bool Property HasCleanBlue = False Auto
Bool Property HasCleanDenim = False Auto
Bool Property HasCleanCream = False Auto

Bool IsEllieInDugoutInn = False

;-- Dynamic References Resolution -------------------------
Actor Function GetEllie()
    If EllieREF == None
        EllieREF = Game.GetForm(0x000222A4) as Actor
    EndIf
    Return EllieREF
EndFunction

ObjectReference Function GetBed()
    If DugoutInnPlayerBed == None
        DugoutInnPlayerBed = Game.GetForm(0x001395C6) as ObjectReference
    EndIf
    Return DugoutInnPlayerBed
EndFunction

ObjectReference Function GetDeskMarker()
    If EllieDeskMarker == None
        EllieDeskMarker = Game.GetForm(0x0006600D) as ObjectReference
    EndIf
    Return EllieDeskMarker
EndFunction

ObjectReference Function GetWardrobeChest()
    If WardrobeChestRef == None
        Actor ellie = GetEllie()
        If ellie != None && WardrobeChestBase != None
            ; Spawn invisible transfer wardrobe right near Ellie under desk
            WardrobeChestRef = ellie.PlaceAtMe(WardrobeChestBase as Form, 1, False, False, False)
            If WardrobeChestRef != None
                WardrobeChestRef.SetPosition(ellie.GetPositionX() + 40.0, ellie.GetPositionY() + 40.0, ellie.GetPositionZ() - 150.0)
            EndIf
        EndIf
    EndIf
    Return WardrobeChestRef
EndFunction

;-- Events & Registration ---------------------------------
Event OnInit()
    InitializeMod()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    InitializeMod()
EndEvent

Function InitializeMod()
    RegisterForPlayerSleep()
    Actor player = Game.GetPlayer()
    If player != None
        RegisterForRemoteEvent(player as ScriptObject, "OnPlayerLoadGame")
        RegisterForRemoteEvent(player as ScriptObject, "OnLocationChange")
    EndIf
    
    Actor ellie = GetEllie()
    If ellie != None
        ; Блокуємо стандартні чергові репліки, перенаправляючи [E] на діалогове меню
        ellie.BlockActivation(True, False)
        RegisterForRemoteEvent(ellie as ScriptObject, "OnActivate")
        Debug.Trace("[EllieRomance] BlockActivation set. Remote OnActivate registered on Ellie.", 0)
    EndIf
EndFunction

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    If akSender == Game.GetPlayer()
        InitializeMod()
    EndIf
EndEvent

;-- Interaction & Dialogue Menu ----------------------------
Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
    Actor ellie = GetEllie()
    If akSender == (ellie as ObjectReference) && akActionRef == (Game.GetPlayer() as ObjectReference)
        ShowEllieDialogueMenu()
    EndIf
EndEvent

Function ShowEllieDialogueMenu()
    If EllieDialogueMessage == None
        ; Fallback
        If RomanceStage == 0
            TriggerRomanceDialogueStart()
        Else
            OpenWardrobeTransferBox()
        EndIf
        Return
    EndIf

    Int choice = EllieDialogueMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If choice == 0
        ; 0: «Чи можу я тобі чимось допомогти?»
        If RomanceStage == 0
            TriggerRomanceDialogueStart()
        ElseIf RomanceStage == 10
            Int remaining = 4 - TotalDressesGiven
            If remaining <= 0 && EveningDressesGiven < 1
                Debug.Notification("Еллі: «Сукні гарні, але для побачення мені все ще потрібна хоча б одна вишукана вечірня сукня!»")
            ElseIf remaining > 0
                Debug.Notification("Еллі: «Мені потрібно 4 чисті ошатні сукні (зараз маю " + TotalDressesGiven + "), обов'язково 1 вечірню.»")
            Else
                Debug.Notification("Еллі: «Гардероб готовий! Ходімо до перукарні Джона.»")
            EndIf
        ElseIf RomanceStage == 20
            Debug.Notification("Еллі: «Ходімо до перукарні Джона на ринку Даймонд-Сіті!»")
        ElseIf RomanceStage == 30
            Debug.Notification("Еллі: «Чекаю на тебе в «Даґаут Інн» для романтичного вечора.»")
        ElseIf RomanceStage >= 100
            Debug.Notification("Еллі: «Рада бачити тебе, любий. Завжди чекаю нашого наступного вечора в Даґаут Інн.»")
        EndIf
    ElseIf choice == 1
        ; 1: «Поглянь, що я приніс»
        OpenWardrobeTransferBox()
    ElseIf choice == 2
        ; 2: «Флірт»
        If TotalDressesGiven > 0
            PlayEllieSmile()
            If EllieFlirtSound != None
                EllieFlirtSound.Play(GetEllie() as ObjectReference)
            EndIf
            Debug.Notification("Еллі: «Все гаразд, сонечко?»")
            Debug.Notification("Еллі приємно збентежена вашою увагою. Ваші стосунки покращилися.")
        Else
            Debug.Notification("Еллі: «Спершу до справи, джентльмене. Мені потрібні сукні!»")
        EndIf
    ElseIf choice == 3
        ; 3: «Бувай»
        ; Closes menu
    EndIf
EndFunction

Function TriggerRomanceDialogueStart()
    RomanceStage = 10
    SetStage(10)
    SetObjectiveDisplayed(10, True, False)
    Debug.Notification("Еллі: «Якщо ти справжній джентльмен — допоможи мені оновити гардероб!»")
    Debug.Trace("[EllieRomance] Quest started. Objective 10 displayed.", 0)
EndFunction

;-- Wardrobe Container Transfer Box -----------------------
Function OpenWardrobeTransferBox()
    Actor player = Game.GetPlayer()
    ObjectReference chest = GetWardrobeChest()
    If player != None && chest != None
        chest.RemoveAllItems(None, False)
        chest.Activate(player as ObjectReference, True)
    EndIf
EndFunction

Function ProcessDonatedDresses(ObjectReference akChest)
    If akChest == None
        Return
    EndIf

    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    If player == None || ellie == None
        Return
    EndIf

    Int newAcceptedThisTime = 0
    Int duplicatesReturned = 0

    ; 1. Evening Dresses
    If EveningSlinkyDress != None
        Int count = akChest.GetItemCount(EveningSlinkyDress as Form)
        If count > 0
            If !HasSlinky
                HasSlinky = True
                EveningDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(EveningSlinkyDress as Form, 1, True)
                akChest.RemoveItem(EveningSlinkyDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(EveningSlinkyDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If EveningSequinDress != None
        Int count = akChest.GetItemCount(EveningSequinDress as Form)
        If count > 0
            If !HasSequin
                HasSequin = True
                EveningDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(EveningSequinDress as Form, 1, True)
                akChest.RemoveItem(EveningSequinDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(EveningSequinDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    ; 2. Day / Clean Dresses
    If CleanGreenDress != None
        Int count = akChest.GetItemCount(CleanGreenDress as Form)
        If count > 0
            If !HasCleanGreen
                HasCleanGreen = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanGreenDress as Form, 1, True)
                akChest.RemoveItem(CleanGreenDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanGreenDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If CleanRedDress != None
        Int count = akChest.GetItemCount(CleanRedDress as Form)
        If count > 0
            If !HasCleanRed
                HasCleanRed = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanRedDress as Form, 1, True)
                akChest.RemoveItem(CleanRedDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanRedDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If CleanRoseDress != None
        Int count = akChest.GetItemCount(CleanRoseDress as Form)
        If count > 0
            If !HasCleanRose
                HasCleanRose = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanRoseDress as Form, 1, True)
                akChest.RemoveItem(CleanRoseDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanRoseDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If CleanBlueDress != None
        Int count = akChest.GetItemCount(CleanBlueDress as Form)
        If count > 0
            If !HasCleanBlue
                HasCleanBlue = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanBlueDress as Form, 1, True)
                akChest.RemoveItem(CleanBlueDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanBlueDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If CleanDenimDress != None
        Int count = akChest.GetItemCount(CleanDenimDress as Form)
        If count > 0
            If !HasCleanDenim
                HasCleanDenim = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanDenimDress as Form, 1, True)
                akChest.RemoveItem(CleanDenimDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanDenimDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    If CleanCreamDress != None
        Int count = akChest.GetItemCount(CleanCreamDress as Form)
        If count > 0
            If !HasCleanCream
                HasCleanCream = True
                DayDressesGiven += 1
                TotalDressesGiven += 1
                newAcceptedThisTime += 1
                ellie.AddItem(CleanCreamDress as Form, 1, True)
                akChest.RemoveItem(CleanCreamDress as Form, 1, True, None)
                count -= 1
            EndIf
            If count > 0
                akChest.RemoveItem(CleanCreamDress as Form, count, True, player as ObjectReference)
                duplicatesReturned += count
            EndIf
        EndIf
    EndIf

    ; Any remaining unapproved items returned to player
    akChest.RemoveAllItems(player as ObjectReference, True)

    ; Feedback and Reactions
    If duplicatesReturned > 0
        Debug.Notification("Еллі: «Дякую, але таку сукню ти мені вже дарував!»")
    EndIf

    If newAcceptedThisTime > 0
        ; Smile animation
        PlayEllieSmile()
        
        ; Voice line of satisfaction
        If EllieGratitudeSound != None
            EllieGratitudeSound.Play(ellie as ObjectReference)
        EndIf
        Debug.Notification("Еллі: «Спасибі тобі.»")

        ; Immediately equip the new day dress style
        EquipDayDress()

        ; Quest stage evaluation
        If RomanceStage == 10
            If TotalDressesGiven >= 4 && EveningDressesGiven >= 1
                CompleteWardrobeStage()
            Else
                Int remaining = 4 - TotalDressesGiven
                If remaining > 0
                    Debug.Notification("Еллі: «Чудово! Залишилося знайти ще " + remaining + " сукні (з них 1 вечірню).»")
                ElseIf EveningDressesGiven < 1
                    Debug.Notification("Еллі: «Сукні чудові, але для побачення потрібна хоча б одна вишукана вечірня сукня!»")
                EndIf
            EndIf
        ElseIf RomanceStage >= 20
            Debug.Notification("Еллі: «Мій гардероб тепер ще багатший! Тепер я маю " + TotalDressesGiven + " з 8 унікальних суконь.»")
        EndIf
    Else
        If duplicatesReturned == 0
            Debug.Notification("Еллі: «У скринці не було нових суконь із моєї колекції.»")
        EndIf
    EndIf
EndFunction

;-- Facial Smile Animation --------------------------------
Function PlayEllieSmile()
    Actor ellie = GetEllie()
    If ellie != None
        If ellie.GetSitState() != 0
            If LaughingSittingIdle != None
                ellie.PlayIdle(LaughingSittingIdle)
            EndIf
        Else
            If LaughingStandingIdle != None
                ellie.PlayIdle(LaughingStandingIdle)
            EndIf
        EndIf
    EndIf
EndFunction

;-- Quest Milestones --------------------------------------
Function CompleteWardrobeStage()
    RomanceStage = 20
    SetStage(20)
    SetObjectiveCompleted(10, True)
    SetObjectiveDisplayed(20, True, False)
    
    Debug.Notification("Еллі: «Ох, мій гардероб тепер просто бездоганний! Ходімо до Джона на ринок — час освіжити зачіску та макіяж!»")
    Debug.Trace("[EllieRomance] Stage 10 completed. Advancing to Barbershop (Stage 20).", 0)

    If EnableDynamicOutfits
        EquipDayDress()
    EndIf
EndFunction

Function CompleteBarbershopVisit()
    If RomanceStage == 20
        RomanceStage = 30
        SetStage(30)
        SetObjectiveCompleted(20, True)
        SetObjectiveDisplayed(30, True, False)

        IsRomanced = True
        CurrentHairstyleIndex = 1

        Debug.Notification("Еллі: «Я почуваюся зовсім іншою жінкою... Дякую тобі за це. Чекатиму на тебе в «Даґаут Інн» увечері!»")
        Debug.Trace("[EllieRomance] Barbershop completed. Romance active (Stage 30).", 0)
    EndIf
EndFunction

;-- Sleep Encounter System («Даґаут Інн») -------------------
Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
    Debug.Trace("[EllieRomance] OnPlayerSleepStop fired. Interrupted=" + abInterrupted + ", Bed=" + (akBed as String), 0)
    If !abInterrupted && IsRomanced
        Actor player = Game.GetPlayer()
        Actor ellie = GetEllie()
        ObjectReference bed = GetBed()

        If player != None && ellie != None
            Bool isDugoutOrHome = False
            If akBed != None && bed != None && akBed == bed
                isDugoutOrHome = True
            EndIf

            If !isDugoutOrHome && bed != None
                If player.GetDistance(bed) < 1200.0
                    isDugoutOrHome = True
                EndIf
            EndIf

            If isDugoutOrHome && !ellie.IsDead()
                If bed != None
                    ellie.MoveTo(bed, 64.0, 64.0, 0.0, True)
                EndIf
                ellie.EvaluatePackage(False)
                IsEllieInDugoutInn = True

                If EnableDynamicOutfits
                    EquipEveningDress()
                EndIf

                If LoversEmbracePerkSpell != None
                    LoversEmbracePerkSpell.Cast(player as ObjectReference, player as ObjectReference)
                    Debug.Trace("[EllieRomance] Lover's Embrace perk spell cast on player.", 0)
                EndIf

                Debug.Notification("Даймонд-Сіті («Даґаут Інн»): Затишна ніч разом з Еллі. Отримано «Обійми коханця».")

                If RomanceStage == 30
                    RomanceStage = 100
                    SetStage(100)
                    SetObjectiveCompleted(30, True)
                    Debug.Trace("[EllieRomance] Stage 30 completed. Romance permanently active (Stage 100).", 0)
                EndIf

                If AutoReturnAfterDelay
                    StartTimer(ReturnDelaySeconds, 2001)
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

Event OnTimer(Int aiTimerID)
    If aiTimerID == 2001
        Debug.Trace("[EllieRomance] Timer 2001 fired. Resetting Ellie to Agency.", 0)
        ResetEllieLocation()
    EndIf
EndEvent

Function ResetEllieLocation()
    Actor ellie = GetEllie()
    ObjectReference bed = GetBed()
    ObjectReference deskMarker = GetDeskMarker()

    If IsEllieInDugoutInn && ellie != None
        Actor player = Game.GetPlayer()
        If player.GetDistance(ellie as ObjectReference) > 800.0 || (bed != None && player.GetDistance(bed) > 1500.0)
            If deskMarker != None
                ellie.MoveTo(deskMarker, 0.0, 0.0, 0.0, True)
                ellie.EvaluatePackage(False)
            EndIf
            If EnableDynamicOutfits
                EquipDayDress()
            EndIf
            IsEllieInDugoutInn = False
            Debug.Trace("[EllieRomance] Ellie returned to Valentine Detective Agency.", 0)
        Else
            StartTimer(60.0, 2001)
        EndIf
    EndIf
EndFunction

;-- Dynamic Outfit Swapping -------------------------------
Function EquipDayDress()
    Actor ellie = GetEllie()
    If ellie == None
        Return
    EndIf
    
    Armor target = None
    If ActiveDayDressIndex == 1 && HasCleanRed && CleanRedDress != None
        target = CleanRedDress
    ElseIf ActiveDayDressIndex == 2 && HasCleanRose && CleanRoseDress != None
        target = CleanRoseDress
    ElseIf ActiveDayDressIndex == 3 && HasCleanBlue && CleanBlueDress != None
        target = CleanBlueDress
    ElseIf ActiveDayDressIndex == 4 && HasCleanDenim && CleanDenimDress != None
        target = CleanDenimDress
    ElseIf ActiveDayDressIndex == 5 && HasCleanCream && CleanCreamDress != None
        target = CleanCreamDress
    ElseIf HasCleanGreen && CleanGreenDress != None
        target = CleanGreenDress
    ElseIf HasCleanRed && CleanRedDress != None
        target = CleanRedDress
    ElseIf HasCleanRose && CleanRoseDress != None
        target = CleanRoseDress
    ElseIf HasCleanBlue && CleanBlueDress != None
        target = CleanBlueDress
    ElseIf HasCleanDenim && CleanDenimDress != None
        target = CleanDenimDress
    ElseIf HasCleanCream && CleanCreamDress != None
        target = CleanCreamDress
    EndIf

    If target != None
        ellie.AddItem(target as Form, 1, True)
        ellie.EquipItem(target as Form, False, True)
    EndIf
EndFunction

Function EquipEveningDress()
    Actor ellie = GetEllie()
    If ellie == None
        Return
    EndIf
    Armor target = None
    If ActiveEveningDressIndex == 1 && HasSequin && EveningSequinDress != None
        target = EveningSequinDress
    ElseIf HasSlinky && EveningSlinkyDress != None
        target = EveningSlinkyDress
    ElseIf HasSequin && EveningSequinDress != None
        target = EveningSequinDress
    EndIf

    If target != None
        ellie.AddItem(target as Form, 1, True)
        ellie.EquipItem(target as Form, False, True)
    EndIf
EndFunction

Function SetDayDressPreset(Int aiPreset)
    ActiveDayDressIndex = aiPreset
    If !IsEllieInDugoutInn
        EquipDayDress()
    EndIf
EndFunction

Function SetEveningDressPreset(Int aiPreset)
    ActiveEveningDressIndex = aiPreset
    If IsEllieInDugoutInn
        EquipEveningDress()
    EndIf
EndFunction

Function SetHairstylePreset(Int aiPreset)
    CurrentHairstyleIndex = aiPreset
    Debug.Notification("Еллі: Стиль зачіски оновлено!")
EndFunction
