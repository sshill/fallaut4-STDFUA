ScriptName EllieRomanceEncounterScript Extends Quest

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
Armor Property OldWastelandDress Auto      ; 0x001B828C ClothesWastelandDress (Стара повсякденна сукня Еллі)

; UI, Container & Audio
Message Property EllieDialogueMessage Auto Const        ; 0x01000830 MESG
Message Property EllieWardrobeSelectMessage Auto Const  ; 0x01000831 MESG
Message Property EllieWardrobeSelectMessage2 Auto Const ; 0x01000832 MESG
Sound Property EllieGratitudeSound Auto Const           ; 0x01000840 SNDR («Спасибі тобі.»)
Sound Property EllieFlirtSound Auto Const               ; 0x01000841 SNDR («Все гаразд, сонечко?»)
Idle Property LaughingSittingIdle Auto Const            ; 0x00118015 ActionCustomLaughingSittingA
Idle Property LaughingStandingIdle Auto Const           ; 0x00118013 ActionCustomLaughingStandingA
Container Property WardrobeChestBase Auto Const         ; 0x01000820 CONT (Гардероб Еллі)
ObjectReference Property WardrobeChestRef Auto          ; Runtime placed chest ref

; Barbershop & Makeover Properties
ObjectReference Property BarberChairRef Auto
Sound Property BarberCutSound Auto
Sound Property BarberBrushSound Auto
MiscObject Property CapsItem Auto
Message Property EllieBarbershopMessage Auto
ActorBase Property ElliePerkinsStyledBase Auto
Actor Property EllieStyledREF Auto
Bool Property IsWaitingAtBarbershop = False Auto

; Dugout Inn & Romance Finale Properties
ObjectReference Property DugoutTableMarker Auto         ; 0x001C7F1A DmndDugoutTableMarker01
Potion Property BobrovMoonshine Auto                    ; 0x000366BF BobrovsBestMoonshine
Potion Property WineBottleForm Auto                     ; 0x000366C2 Wine
Potion Property CountryCrossingWineForm Auto            ; 0x01000860 ALCH Кантрі Кроссінг Піно-Нуар (урожай 2075 року)
MiscObject Property FlowerVaseForm Auto                 ; 0x000AC8E6 VaseVintageCleanFlowers01a
Idle Property HeadShakeIdle Auto                        ; 0x00038C7A HeadShakeNo
Idle Property InspectIdle Auto                          ; 0x00061D01 IDLE Inspect
Message Property EllieDugoutInnDialogueMessage Auto ; 0x01000836 MESG EllieDugoutInnDialogueMessage
ActorValue Property CA_IsRomantic Auto                  ; 0x00148DF6 AVIF CA_IsRomantic
Faction Property CurrentCompanionFaction Auto           ; 0x00023C01 FACT CurrentCompanionFaction
Message Property EllieBarOrderMessage Auto Const       ; 0x01000834 MESG
Message Property EllieWineToastMessage Auto Const      ; 0x01000835 MESG

ObjectReference Property PlacedMoonshineRef Auto
ObjectReference Property PlacedWineRef Auto
ObjectReference Property PlacedVaseRef Auto
ObjectReference Property PlacedClothTableRef Auto
ObjectReference Property PlacedShotGlass1Ref Auto
ObjectReference Property PlacedShotGlass2Ref Auto
ObjectReference Property PlacedWineGlass1Ref Auto
ObjectReference Property PlacedWineGlass2Ref Auto
ObjectReference Property PlacedScarlettBouquetRef Auto
Bool Property IsWaitingAtDugoutBar = False Auto
Bool Property HasOrderedWine = False Auto
Bool Property IsScarlettAdmiring = False Auto

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
Int Property CurrentManualDressIndex = 0 Auto ; 0=Авто-цикл, 1=Зелена, 2=Синя, 3=Червона, 4=Sequin, 5=Slinky, 6=Рожева, 7=Джинсова, 8=Кремова
Armor Property CurrentEquippedDress Auto

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

ObjectReference Function GetBarberChair()
    If BarberChairRef == None
        BarberChairRef = Game.GetForm(0x00031FAF) as ObjectReference
    EndIf
    Return BarberChairRef
EndFunction

MiscObject Function GetCapsItem()
    If CapsItem == None
        CapsItem = Game.GetForm(0x0000000F) as MiscObject
    EndIf
    Return CapsItem
EndFunction

Sound Function GetBarberCutSound()
    If BarberCutSound == None
        BarberCutSound = Game.GetForm(0x002484F8) as Sound
    EndIf
    Return BarberCutSound
EndFunction

Sound Function GetBarberBrushSound()
    If BarberBrushSound == None
        BarberBrushSound = Game.GetForm(0x002484F7) as Sound
    EndIf
    Return BarberBrushSound
EndFunction

ObjectReference Function GetDugoutTableMarker()
    If DugoutTableMarker == None
        DugoutTableMarker = Game.GetForm(0x001C7F1A) as ObjectReference
    EndIf
    Return DugoutTableMarker
EndFunction

Potion Function GetBobrovMoonshine()
    If BobrovMoonshine == None
        BobrovMoonshine = Game.GetForm(0x000366BF) as Potion
    EndIf
    Return BobrovMoonshine
EndFunction

Potion Function GetWineBottle()
    If WineBottleForm == None
        WineBottleForm = Game.GetForm(0x000366C2) as Potion
    EndIf
    Return WineBottleForm
EndFunction

MiscObject Function GetFlowerVase()
    If FlowerVaseForm == None
        FlowerVaseForm = Game.GetForm(0x000AC8E6) as MiscObject
    EndIf
    Return FlowerVaseForm
EndFunction

Idle Function GetHeadShakeIdle()
    If HeadShakeIdle == None
        HeadShakeIdle = Game.GetForm(0x00038C7A) as Idle
    EndIf
    Return HeadShakeIdle
EndFunction

ActorValue Function GetCA_IsRomantic()
    If CA_IsRomantic == None
        CA_IsRomantic = Game.GetForm(0x00148DF6) as ActorValue
    EndIf
    Return CA_IsRomantic
EndFunction

Faction Function GetCurrentCompanionFaction()
    If CurrentCompanionFaction == None
        CurrentCompanionFaction = Game.GetForm(0x00023C01) as Faction
    EndIf
    Return CurrentCompanionFaction
EndFunction

Potion Function GetCountryCrossingWine()
    If CountryCrossingWineForm == None
        CountryCrossingWineForm = Game.GetFormFromFile(0x00000860, "EllieRomance.esp") as Potion
    EndIf
    If CountryCrossingWineForm == None
        CountryCrossingWineForm = Game.GetForm(0x01000860) as Potion
    EndIf
    If CountryCrossingWineForm == None
        CountryCrossingWineForm = GetWineBottle()
    EndIf
    Return CountryCrossingWineForm
EndFunction

Message Function GetEllieDugoutInnDialogueMessage()
    If EllieDugoutInnDialogueMessage != None
        Return EllieDugoutInnDialogueMessage
    EndIf
    Return Game.GetFormFromFile(0x00000836, "EllieRomance.esp") as Message
EndFunction

Idle Function GetInspectIdle()
    If InspectIdle == None
        InspectIdle = Game.GetForm(0x00061D01) as Idle
    EndIf
    Return InspectIdle
EndFunction

Actor ScarlettActorRef = None

Actor Function GetScarlett()
    If ScarlettActorRef == None
        ScarlettActorRef = Game.GetForm(0x0004B242) as Actor
    EndIf
    Return ScarlettActorRef
EndFunction

ObjectReference Function GetDugoutTablePatio()
    Return Game.GetForm(0x00139639) as ObjectReference
EndFunction

ObjectReference Function GetDugoutChairWest()
    Return Game.GetForm(0x0013963A) as ObjectReference
EndFunction

ObjectReference Function GetDugoutChairNorth()
    Return Game.GetForm(0x0013963B) as ObjectReference
EndFunction

ObjectReference Function GetDugoutChairEast()
    Return Game.GetForm(0x0013963C) as ObjectReference
EndFunction

ObjectReference Function GetBeerBottle1()
    Return Game.GetForm(0x0013968E) as ObjectReference
EndFunction

ObjectReference Function GetBeerBottle2()
    Return Game.GetForm(0x0013968F) as ObjectReference
EndFunction

ObjectReference Function GetBeerBottle3()
    Return Game.GetForm(0x00139690) as ObjectReference
EndFunction

ObjectReference Function GetTinCanClutter()
    Return Game.GetForm(0x0023DFCA) as ObjectReference
EndFunction

Actor Function GetDugoutResident1()
    Return Game.GetForm(0x0013C4A4) as Actor
EndFunction

Actor Function GetDugoutResident2()
    Return Game.GetForm(0x0013C4A7) as Actor
EndFunction

Actor Function GetDugoutResident()
    Return GetDugoutResident2()
EndFunction

Static Function GetMemDenClothTable()
    Return Game.GetForm(0x0005B2E9) as Static
EndFunction

MiscObject Function GetShotGlassItem()
    Return Game.GetForm(0x00059B0A) as MiscObject
EndFunction

MiscObject Function GetWineGlassItem()
    Return Game.GetForm(0x0023CD68) as MiscObject
EndFunction

;-- Events & Registration ---------------------------------
Event OnInit()
    InitializeMod()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    InitializeMod()
    ReapplyCurrentDress()
    If RomanceStage == 30
        EnsureDugoutTableSetup(False)
    EndIf
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
    If EllieStyledREF != None
        EllieStyledREF.BlockActivation(True, False)
        RegisterForRemoteEvent(EllieStyledREF as ScriptObject, "OnActivate")
    EndIf
    
    ReapplyCurrentDress()
EndFunction

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    If akSender == Game.GetPlayer()
        InitializeMod()
        ReapplyCurrentDress()
        If RomanceStage == 30
            EnsureDugoutTableSetup(False)
        EndIf
    EndIf
EndEvent

;-- Interaction & Dialogue Menu ----------------------------
Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
    Actor ellie = GetEllie()
    Actor player = Game.GetPlayer()
    If akActionRef == (player as ObjectReference)
        If akSender == PlacedMoonshineRef
            OrderWineFromVadim()
            Return
        ElseIf akSender == PlacedWineRef
            PerformWineToastCinematic()
            Return
        ElseIf akSender == (GetScarlett() as ObjectReference)
            Actor scarlett = GetScarlett()
            If scarlett != None
                scarlett.PlayIdle(GetInspectIdle())
                Debug.Notification("Скарлетт мрійливо милується букетом від Еллі: «Вона сказала берегти його... Невже моє щастя й справді вже десь поруч?»")
            EndIf
            Return
        ElseIf (akSender == (ellie as ObjectReference) || (EllieStyledREF != None && akSender == (EllieStyledREF as ObjectReference)))
            If RomanceStage == 20 && IsWaitingAtBarbershop
                ShowEllieBarbershopMenu()
            ElseIf RomanceStage == 30
                ShowEllieDugoutInnMenu()
            Else
                ShowEllieDialogueMenu()
            EndIf
        EndIf
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
            SendEllieToBarbershop()
        ElseIf RomanceStage == 30
            Debug.Notification("Еллі: «Чекаю на тебе в «Даґаут Інн» для романтичного вечора.»")
        ElseIf RomanceStage >= 100
            Debug.Notification("Еллі: «Рада бачити тебе, любий. Завжди чекаю нашого наступного вечора в Даґаут Інн.»")
        EndIf
    ElseIf choice == 1
        ; 1: «Поглянь, що я приніс (Гардероб)»
        OpenWardrobeTransferBox()
    ElseIf choice == 2
        ; 2: «Приміряй сукню (Вибрати вбрання)»
        ShowWardrobeSelectMenu()
    ElseIf choice == 3
        ; 3: «Флірт»
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
    ElseIf choice == 4
        ; 4: «Бувай»
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

;-- Barbershop Visit & Makeover System --------------------
Function SendEllieToBarbershop()
    Actor ellie = GetEllie()
    ObjectReference chair = GetBarberChair()
    If ellie != None && chair != None
        Debug.Notification("Еллі: «Домовилися! Зустрінемось біля крісла Джона на ринку, не затримуйся!»")
        ellie.MoveTo(chair, 32.0, 32.0, 0.0, True)
        chair.Activate(ellie as ObjectReference, True)
        ellie.EvaluatePackage(False)
        ellie.SetRestrained(True)
        IsWaitingAtBarbershop = True
        Debug.Trace("[EllieRomance] Ellie dispatched to John's barber chair (0x00031FAF).", 0)
    Else
        Debug.Notification("Еллі: «Ходімо до перукарні Джона на ринку Даймонд-Сіті!»")
    EndIf
EndFunction

Function ShowEllieBarbershopMenu()
    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    If player == None || ellie == None
        Return
    EndIf

    If EllieBarbershopMessage == None
        PerformBarbershopMakeover()
        Return
    EndIf

    Int choice = EllieBarbershopMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If choice == 0
        ; 0: «Зробити макіяж та нову зачіску (50 кришок)»
        MiscObject caps = GetCapsItem()
        If caps != None && player.GetItemCount(caps as Form) < 50
            Debug.Notification("Недостатньо кришок! Для оплати послуг перукаря потрібно 50 кришок.")
            Return
        EndIf

        If caps != None
            player.RemoveItem(caps as Form, 50, False, None)
            Debug.Notification("Списано 50 кришок за послуги перукаря.")
        EndIf

        PerformBarbershopMakeover()

    ElseIf choice == 1
        ; 1: «Приміряти іншу сукню (Вибрати вбрання)»
        ShowWardrobeSelectMenu()

    ElseIf choice == 2
        ; 2: «Почекай хвилинку (Бувай)»
        ; Closes menu
    EndIf
EndFunction

Function PerformBarbershopMakeover()
    Actor player = Game.GetPlayer()
    Actor oldEllie = GetEllie()
    ObjectReference chair = GetBarberChair()

    ; 1. Fade out game to complete blackness
    Game.FadeOutGame(True, True, 0.0, 1.5, True)

    ; 2. Play scissors cutting sound
    Sound cutSound = GetBarberCutSound()
    If cutSound != None && oldEllie != None
        cutSound.Play(oldEllie as ObjectReference)
    EndIf

    Utility.Wait(1.5)

    ; 3. Play hair brush sound
    Sound brushSound = GetBarberBrushSound()
    If brushSound != None && oldEllie != None
        brushSound.Play(oldEllie as ObjectReference)
    EndIf

    Utility.Wait(1.0)

    ; 4. Swap appearance to ElliePerkinsStyledBase (with Irma's makeup & hair)
    If ElliePerkinsStyledBase != None && chair != None
        If EllieStyledREF == None
            EllieStyledREF = chair.PlaceAtMe(ElliePerkinsStyledBase as Form, 1, True, True, False) as Actor
        EndIf

        If EllieStyledREF != None
            If oldEllie != None
                oldEllie.SetRestrained(False)
                oldEllie.RemoveAllItems(EllieStyledREF as ObjectReference, True)
                oldEllie.Disable(False)
            EndIf

            EllieStyledREF.MoveTo(chair, 0.0, 0.0, 0.0, True)
            EllieStyledREF.Enable(False)
            chair.Activate(EllieStyledREF as ObjectReference, True)
            EllieStyledREF.EvaluatePackage(False)

            EllieREF = EllieStyledREF
            RegisterForRemoteEvent(EllieStyledREF as ScriptObject, "OnActivate")
            EllieStyledREF.BlockActivation(True, False)
        EndIf
    EndIf

    If EnableDynamicOutfits
        EquipDayDress()
    EndIf

    Utility.Wait(0.5)

    ; 5. Fade back in from blackness
    Game.FadeOutGame(False, True, 0.0, 1.5, False)

    ; 6. Gratitude sound & animation
    Actor activeEllie = GetEllie()
    PlayEllieSmile()
    If EllieGratitudeSound != None && activeEllie != None
        EllieGratitudeSound.Play(activeEllie as ObjectReference)
    EndIf

    ; 7. Advance quest to Stage 30 («Даґаут Інн»)
    RomanceStage = 30
    SetStage(30)
    SetObjectiveCompleted(20, True)
    SetObjectiveDisplayed(30, True, False)
    IsRomanced = True
    IsWaitingAtBarbershop = False
    CurrentHairstyleIndex = 1

    Debug.Notification("Еллі: «Я почуваюся зовсім іншою жінкою... Дякую тобі за це, любий! Чекатиму на тебе в «Даґаут Інн» увечері!»")
    Debug.Trace("[EllieRomance] Barbershop makeover completed. Dispatching Ellie to Dugout Inn (Stage 30).", 0)

    SendEllieToDugoutInn()
EndFunction

Function CompleteBarbershopVisit()
    PerformBarbershopMakeover()
EndFunction

;-- Dugout Inn Date & Romance Scene (Stage 30) ------------
Function EnsureDugoutTableSetup(Bool abForce = False)
    If RomanceStage < 30 || (RomanceStage > 30 && !abForce)
        Return
    EndIf

    ; 1. Звільняємо столик від сторонніх жителів та зайвого мотлоху
    Actor res1 = GetDugoutResident1()
    If res1 != None
        res1.Disable(False)
    EndIf
    Actor res2 = GetDugoutResident2()
    If res2 != None
        res2.Disable(False)
    EndIf
    ObjectReference chairNorth = GetDugoutChairNorth()
    If chairNorth != None
        chairNorth.Disable(False)
    EndIf
    ObjectReference b1 = GetBeerBottle1()
    If b1 != None
        b1.Disable(False)
    EndIf
    ObjectReference b2 = GetBeerBottle2()
    If b2 != None
        b2.Disable(False)
    EndIf
    ObjectReference b3 = GetBeerBottle3()
    If b3 != None
        b3.Disable(False)
    EndIf
    ObjectReference tinCan = GetTinCanClutter()
    If tinCan != None
        tinCan.Disable(False)
    EndIf

    ; 2. Еллі: вечірня сукня, садимо за західний стілець, фіксуємо позу та меню
    Actor ellie = GetEllie()
    ObjectReference chairWest = GetDugoutChairWest()
    ObjectReference tableMarker = GetDugoutTableMarker()
    ObjectReference table = GetDugoutTablePatio()
    If table == None
        table = tableMarker
    EndIf

    If ellie != None
        If EnableDynamicOutfits
            EquipEveningDress()
        EndIf
        
        If chairWest != None
            ellie.MoveTo(chairWest, 0.0, 0.0, 0.0, True)
            chairWest.Activate(ellie as ObjectReference, True)
        ElseIf tableMarker != None
            ellie.MoveTo(tableMarker, 0.0, 0.0, 0.0, True)
        EndIf
        ellie.EvaluatePackage(False)
        ellie.SetRestrained(True)
        ellie.BlockActivation(True, False)
        RegisterForRemoteEvent(ellie as ScriptObject, "OnActivate")
        If EllieStyledREF != None
            EllieStyledREF.BlockActivation(True, False)
            RegisterForRemoteEvent(EllieStyledREF as ScriptObject, "OnActivate")
        EndIf
        IsEllieInDugoutInn = True
        IsWaitingAtDugoutBar = True
    EndIf

    ; 3. Якщо вино ще не замовлено — на столі стоїть самогон та гранчаки
    If !HasOrderedWine
        If table != None && PlacedMoonshineRef == None
            Potion moonshine = GetBobrovMoonshine()
            If moonshine != None
                PlacedMoonshineRef = table.PlaceAtMe(moonshine as Form, 1, False, False, False)
                If PlacedMoonshineRef != None
                    PlacedMoonshineRef.SetPosition(-128.0, -3090.8, 55.0)
                    RegisterForRemoteEvent(PlacedMoonshineRef as ScriptObject, "OnActivate")
                EndIf
            EndIf

            MiscObject shotGlass = GetShotGlassItem()
            If shotGlass != None
                If PlacedShotGlass1Ref == None
                    PlacedShotGlass1Ref = table.PlaceAtMe(shotGlass as Form, 1, False, False, False)
                    If PlacedShotGlass1Ref != None
                        PlacedShotGlass1Ref.SetPosition(-155.0, -3088.0, 55.0)
                    EndIf
                EndIf
                If PlacedShotGlass2Ref == None
                    PlacedShotGlass2Ref = table.PlaceAtMe(shotGlass as Form, 1, False, False, False)
                    If PlacedShotGlass2Ref != None
                        PlacedShotGlass2Ref.SetPosition(-101.0, -3092.0, 55.0)
                    EndIf
                EndIf
            EndIf
        ElseIf PlacedMoonshineRef != None
            RegisterForRemoteEvent(PlacedMoonshineRef as ScriptObject, "OnActivate")
        EndIf
    Else
        If PlacedWineRef != None
            RegisterForRemoteEvent(PlacedWineRef as ScriptObject, "OnActivate")
        EndIf
    EndIf
    Debug.Trace("[EllieRomance] EnsureDugoutTableSetup complete.", 0)
EndFunction

Function SendEllieToDugoutInn()
    RomanceStage = 30
    SetStage(30)
    SetObjectiveDisplayed(30, True, False)
    HasOrderedWine = False

    EnsureDugoutTableSetup(True)
    PlayEllieDisgustReaction()
    Debug.Trace("[EllieRomance] Stage 30 started. Ellie dispatched to Dugout Inn.", 0)
EndFunction

Function PlayEllieDisgustReaction()
    Actor ellie = GetEllie()
    If ellie != None
        Idle headShake = GetHeadShakeIdle()
        If headShake != None
            ellie.PlayIdle(headShake)
        EndIf
        Debug.Notification("Еллі з відразою дивиться на Бобровку: «Брр... Це ж справжній гас, а не напій для леді! Як ви взагалі це п'єте, хлопці?»")
    EndIf
EndFunction

Function ShowEllieDugoutInnMenu()
    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    If player == None || ellie == None
        Return
    EndIf

    EnsureDugoutTableSetup(False)

    Message dlgMsg = GetEllieDugoutInnDialogueMessage()
    If dlgMsg == None
        If !HasOrderedWine
            OrderWineFromVadim()
        Else
            PerformWineToastCinematic()
        EndIf
        Return
    EndIf

    Int choice = dlgMsg.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If choice == 0
        ; 0: «Ти виглядаєш просто приголомшливо у цій вечірній сукні!»
        PlayEllieSmile()
        If EllieFlirtSound != None
            EllieFlirtSound.Play(ellie as ObjectReference)
        EndIf
        Debug.Notification("Еллі ніжно посміхається: «Дякую, любий... Я так хвилювалася, чи сподобається тобі мій вибір!»")
        Debug.Notification("Еллі зворушена вашим компліментом. (Прихильність +15)")
        If !HasOrderedWine
            Debug.Notification("Погляньте на напій на столику [E].")
        Else
            Debug.Notification("Погляньте на пляшку вина на столику [E].")
        EndIf
    ElseIf choice == 1
        ; 1: «Ця нова зачіска та макіяж підкреслюють твої прекрасні очі...»
        PlayEllieSmile()
        If EllieGratitudeSound != None
            EllieGratitudeSound.Play(ellie as ObjectReference)
        EndIf
        Debug.Notification("Еллі торкається локона: «Перукар Джон дійсно знає свою справу... Але найголовніше — бачити захоплення в твоїх очах.»")
        Debug.Notification("Еллі у захваті від вашої уваги до деталей. (Прихильність +15)")
        If !HasOrderedWine
            Debug.Notification("Погляньте на напій на столику [E].")
        Else
            Debug.Notification("Погляньте на пляшку вина на столику [E].")
        EndIf
    ElseIf choice == 2
        ; 2: «Поруч з тобою цей бар здається найзатишнішим місцем у Співдружності.»
        PlayEllieSmile()
        If EllieFlirtSound != None
            EllieFlirtSound.Play(ellie as ObjectReference)
        EndIf
        Debug.Notification("Еллі м'яко дивиться на вас: «У такій компанії навіть галасливий «Даґаут» перетворюється на казку... Спасибі тобі за цей вечір.»")
        Debug.Notification("Ваш романтичний зв'язок з Еллі міцнішає. (Прихильність +15)")
        If !HasOrderedWine
            Debug.Notification("Погляньте на напій на столику [E].")
        Else
            Debug.Notification("Погляньте на пляшку вина на столику [E].")
        EndIf
    ElseIf choice == 3
        ; 3: «Як тобі напій на столі?»
        If !HasOrderedWine
            PlayEllieDisgustReaction()
            Debug.Notification("Підійдіть до столика та натисніть [E] на пляшку Бобровки, щоб замовити вишукане вино.")
        Else
            PlayEllieSmile()
            Debug.Notification("Еллі: «Це чудове вино, любий! Піднімемо келихи за нас?» (Натисніть [E] на пляшку вина на столику)")
        EndIf
    ElseIf choice == 4
        ; 4: «Зачекай хвилинку (Бувай)»
    EndIf
EndFunction

Function OrderWineFromVadim()
    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    ObjectReference tableMarker = GetDugoutTableMarker()
    If player == None || ellie == None || tableMarker == None
        Return
    EndIf

    If EllieBarOrderMessage == None
        ExecuteWineArrival()
        Return
    EndIf

    Int choice = EllieBarOrderMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If choice == 0
        ; 0: «[50 кришок] Тримай кришки. Для Еллі — тільки найкраще!»
        MiscObject caps = GetCapsItem()
        If caps != None && player.GetItemCount(caps as Form) < 50
            Debug.Notification("Недостатньо кришок! Вадим вимагає 50 кришок за марочне вино.")
            Return
        EndIf
        If caps != None
            player.RemoveItem(caps as Form, 50, False, None)
            Debug.Notification("Списано 50 кришок за пляшку марочного вина.")
        EndIf
        ExecuteWineArrival()
    ElseIf choice == 1
        ; 1: «[Харизма] Вадиме, ти ж мене знаєш — запиши на мій рахунок!»
        Debug.Notification("Вадим: «Хе-хе, друже, тільки заради такої гарної леді! Записую на твій рахунок!»")
        ExecuteWineArrival()
    ElseIf choice == 2
        ; 2: «[Відійти] Зачекай хвилинку.»
    EndIf
EndFunction

Function ExecuteWineArrival()
    Actor ellie = GetEllie()
    ObjectReference table = GetDugoutTablePatio()
    If table == None
        table = GetDugoutTableMarker()
    EndIf
    If table == None
        Return
    EndIf

    ; 1. Прибираємо самогон Бобрових та гранчаки зі столика
    CleanUpBobrovkaProps()

    ; 2. Замінюємо столик на столик зі скатертиною
    ObjectReference tablePatio = GetDugoutTablePatio()
    If tablePatio != None
        tablePatio.Disable(False)
    EndIf
    Static clothTableBase = GetMemDenClothTable()
    If clothTableBase != None && tablePatio != None
        PlacedClothTableRef = tablePatio.PlaceAtMe(clothTableBase as Form, 1, False, False, False)
        If PlacedClothTableRef != None
            PlacedClothTableRef.SetPosition(-128.0, -3090.8, 0.0)
        EndIf
    EndIf

    ; 3. Ставимо марочне вино «Кантрі Кроссінг Піно-Нуар (урожай 2075 року)»
    Potion wine = GetCountryCrossingWine()
    If wine != None
        PlacedWineRef = table.PlaceAtMe(wine as Form, 1, False, False, False)
        If PlacedWineRef != None
            PlacedWineRef.SetPosition(-128.0, -3080.0, 56.0)
            RegisterForRemoteEvent(PlacedWineRef as ScriptObject, "OnActivate")
        EndIf
    EndIf

    ; 4. Ставимо 2 високі вишукані келихи
    MiscObject wineGlass = GetWineGlassItem()
    If wineGlass != None
        PlacedWineGlass1Ref = table.PlaceAtMe(wineGlass as Form, 1, False, False, False)
        If PlacedWineGlass1Ref != None
            PlacedWineGlass1Ref.SetPosition(-155.0, -3088.0, 56.0)
        EndIf
        PlacedWineGlass2Ref = table.PlaceAtMe(wineGlass as Form, 1, False, False, False)
        If PlacedWineGlass2Ref != None
            PlacedWineGlass2Ref.SetPosition(-101.0, -3092.0, 56.0)
        EndIf
    EndIf

    ; 5. Ставимо вазу з квітами
    MiscObject vase = GetFlowerVase()
    If vase != None
        PlacedVaseRef = table.PlaceAtMe(vase as Form, 1, False, False, False)
        If PlacedVaseRef != None
            PlacedVaseRef.SetPosition(-128.0, -3105.0, 56.0)
        EndIf
    EndIf

    HasOrderedWine = True

    ; 6. Захоплення Еллі
    If ellie != None
        PlayEllieSmile()
        If EllieGratitudeSound != None
            EllieGratitudeSound.Play(ellie as ObjectReference)
        EndIf
        Debug.Notification("Еллі: «Ого... Кантрі Кроссінг Піно-Нуар довоєнного року, скатертина та свіжі квіти?! Ти неймовірний джентльмен, любий!»")
    EndIf
EndFunction

Function PerformWineToastCinematic()
    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    If player == None || ellie == None
        Return
    EndIf

    If EllieWineToastMessage != None
        Int choice = EllieWineToastMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        If choice != 0
            Return
        EndIf
    EndIf

    ; 1. Камера: перемикання у 3-тю особу та плавний фокус
    Game.ForceThirdPerson()
    Game.StartDialogueCameraOrCenterOnTarget(ellie as ObjectReference)

    ; 2. Тост і посмішка
    PlayEllieSmile()
    If EllieFlirtSound != None
        EllieFlirtSound.Play(ellie as ObjectReference)
    EndIf
    Debug.Notification("Еллі піднімає келих: «За нас, мій захиснику... Цей вечір належить тільки нам двох!»")

    Utility.Wait(2.5)

    ; 3. Перехід до номеру готелю
    TransitionToDugoutBedroom()
EndFunction

Function TransitionToDugoutBedroom()
    Actor player = Game.GetPlayer()
    Actor ellie = GetEllie()
    ObjectReference bed = GetBed()

    ; 1. Плавне затемнення екрана
    Game.FadeOutGame(True, True, 0.5, 2.0, True)

    ; 2. Прибирання предметів зі столика та відновлення бару
    CleanUpTableProps()
    RestoreDugoutInnBar()

    Utility.Wait(2.0)

    ; 3. Переміщення гравця та Еллі до ліжка в номері
    If bed != None
        If player != None
            player.MoveTo(bed, 0.0, 0.0, 0.0, True)
        EndIf
        If ellie != None
            ellie.MoveTo(bed, 48.0, 48.0, 0.0, True)
            ; У ліжку без сукні (у спідній білизні)
            UnequipAllDresses(ellie)
            ellie.EvaluatePackage(False)
        EndIf
    EndIf

    ; 4. Бонус "Обійми коханця"
    If LoversEmbracePerkSpell != None && player != None
        LoversEmbracePerkSpell.Cast(player as ObjectReference, player as ObjectReference)
    EndIf

    ; 5. Фінал роману: перехід на Stage 100
    RomanceStage = 100
    SetStage(100)
    SetObjectiveCompleted(30, True)
    IsRomanced = True
    IsWaitingAtDugoutBar = False
    HasOrderedWine = False

    Utility.Wait(1.0)

    ; 6. Повернення світла (ранок)
    Game.FadeOutGame(False, True, 0.0, 2.0, False)

    ; 7. Сповіщення та вдячна репліка
    Debug.Notification("Даймонд-Сіті («Даґаут Інн»): Затишна ніч разом з Еллі. Отримано «Обійми коханця».")
    Debug.Notification("Еллі: «Це була неймовірно затишна та чарівна ніч... Я чекатиму тебе в цьому номері щоночі, любий!»")

    Utility.Wait(1.5)

    ; 8. Коли Еллі встає з ліжка — одягається в ошатну ділову сукню та знімається обмеження
    If EnableDynamicOutfits
        EquipDayDress()
    EndIf
    If ellie != None
        ellie.SetRestrained(False)
    EndIf

    ; 9. Сцена зі Скарлетт (прибиральниця милується букетом)
    SetupScarlettAdmiringBouquet()

    If AutoReturnAfterDelay
        StartTimer(ReturnDelaySeconds, 2001)
    EndIf

    Debug.Trace("[EllieRomance] Stage 30 date & night completed. Romance permanently active (Stage 100).", 0)
EndFunction

Function RestoreDugoutInnBar()
    ObjectReference tablePatio = GetDugoutTablePatio()
    If tablePatio != None
        tablePatio.Enable(False)
    EndIf
    ObjectReference chairNorth = GetDugoutChairNorth()
    If chairNorth != None
        chairNorth.Enable(False)
    EndIf
    ObjectReference b1 = GetBeerBottle1()
    If b1 != None
        b1.Enable(False)
    EndIf
    ObjectReference b2 = GetBeerBottle2()
    If b2 != None
        b2.Enable(False)
    EndIf
    ObjectReference b3 = GetBeerBottle3()
    If b3 != None
        b3.Enable(False)
    EndIf
    ObjectReference tinCan = GetTinCanClutter()
    If tinCan != None
        tinCan.Enable(False)
    EndIf
    Actor res1 = GetDugoutResident1()
    If res1 != None
        res1.Enable(False)
    EndIf
    Actor res2 = GetDugoutResident2()
    If res2 != None
        res2.Enable(False)
    EndIf
EndFunction

Function SetupScarlettAdmiringBouquet()
    Actor scarlett = GetScarlett()
    If scarlett != None
        MiscObject vase = GetFlowerVase()
        If vase != None && PlacedScarlettBouquetRef == None
            PlacedScarlettBouquetRef = scarlett.PlaceAtMe(vase as Form, 1, False, False, False)
            If PlacedScarlettBouquetRef != None
                PlacedScarlettBouquetRef.SetPosition(scarlett.GetPositionX() + 14.0, scarlett.GetPositionY() - 14.0, scarlett.GetPositionZ() + 38.0)
                PlacedScarlettBouquetRef.AttachTo(scarlett as ObjectReference)
            EndIf
        EndIf
        scarlett.SetRestrained(True)
        Idle inspect = GetInspectIdle()
        If inspect != None
            scarlett.PlayIdle(inspect)
        EndIf
        scarlett.BlockActivation(True, False)
        RegisterForRemoteEvent(scarlett as ScriptObject, "OnActivate")
        IsScarlettAdmiring = True
        Debug.Notification("Скарлетт щасливо милується залишеним Еллі букетом квітів як теплим натяком на майбутнє кохання.")
    EndIf
EndFunction

Function CleanUpScarlett()
    If PlacedScarlettBouquetRef != None
        PlacedScarlettBouquetRef.Disable(False)
        PlacedScarlettBouquetRef.Delete()
        PlacedScarlettBouquetRef = None
    EndIf
    Actor scarlett = GetScarlett()
    If scarlett != None
        scarlett.SetRestrained(False)
        scarlett.BlockActivation(False, False)
        UnregisterForRemoteEvent(scarlett as ScriptObject, "OnActivate")
    EndIf
    IsScarlettAdmiring = False
EndFunction

Function CleanUpBobrovkaProps()
    If PlacedMoonshineRef != None
        UnregisterForRemoteEvent(PlacedMoonshineRef as ScriptObject, "OnActivate")
        PlacedMoonshineRef.Disable(False)
        PlacedMoonshineRef.Delete()
        PlacedMoonshineRef = None
    EndIf
    If PlacedShotGlass1Ref != None
        PlacedShotGlass1Ref.Disable(False)
        PlacedShotGlass1Ref.Delete()
        PlacedShotGlass1Ref = None
    EndIf
    If PlacedShotGlass2Ref != None
        PlacedShotGlass2Ref.Disable(False)
        PlacedShotGlass2Ref.Delete()
        PlacedShotGlass2Ref = None
    EndIf
EndFunction

Function CleanUpWineProps()
    If PlacedWineRef != None
        UnregisterForRemoteEvent(PlacedWineRef as ScriptObject, "OnActivate")
        PlacedWineRef.Disable(False)
        PlacedWineRef.Delete()
        PlacedWineRef = None
    EndIf
    If PlacedWineGlass1Ref != None
        PlacedWineGlass1Ref.Disable(False)
        PlacedWineGlass1Ref.Delete()
        PlacedWineGlass1Ref = None
    EndIf
    If PlacedWineGlass2Ref != None
        PlacedWineGlass2Ref.Disable(False)
        PlacedWineGlass2Ref.Delete()
        PlacedWineGlass2Ref = None
    EndIf
    If PlacedVaseRef != None
        PlacedVaseRef.Disable(False)
        PlacedVaseRef.Delete()
        PlacedVaseRef = None
    EndIf
    If PlacedClothTableRef != None
        PlacedClothTableRef.Disable(False)
        PlacedClothTableRef.Delete()
        PlacedClothTableRef = None
    EndIf
EndFunction

Function CleanUpTableProps()
    CleanUpBobrovkaProps()
    CleanUpWineProps()
EndFunction

Bool Function HasRomancedFollowerPresent()
    Actor player = Game.GetPlayer()
    ActorValue romanticAV = GetCA_IsRomantic()
    Faction compFaction = GetCurrentCompanionFaction()
    If player == None || romanticAV == None || compFaction == None
        Return False
    EndIf

    Actor[] followers = Game.GetPlayerFollowers()
    If followers != None
        Int i = 0
        While i < followers.Length
            Actor fol = followers[i]
            If fol != None && fol != (GetEllie())
                If fol.IsInFaction(compFaction) && fol.GetValue(romanticAV) > 0.0
                    Return True
                EndIf
            EndIf
            i += 1
        EndWhile
    EndIf
    Return False
EndFunction

;-- Sleep Encounter System («Даґаут Інн») -------------------
Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
    Debug.Trace("[EllieRomance] OnPlayerSleepStop fired. Interrupted=" + abInterrupted + ", Bed=" + (akBed as String), 0)
    If !abInterrupted
        Actor player = Game.GetPlayer()
        Actor ellie = GetEllie()
        ObjectReference bed = GetBed()

        If player != None && ellie != None && IsRomanced
            ; Перевірка застереження Магнолії: чи є поруч романтичний супутник
            If HasRomancedFollowerPresent()
                Debug.Trace("[EllieRomance] Sleep encounter skipped: player is accompanied by a romanced follower.", 0)
                Return
            EndIf

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
                    ellie.MoveTo(bed, 48.0, 48.0, 0.0, True)
                EndIf
                ; У ліжку без сукні
                UnequipAllDresses(ellie)
                ellie.EvaluatePackage(False)
                IsEllieInDugoutInn = True

                If LoversEmbracePerkSpell != None
                    LoversEmbracePerkSpell.Cast(player as ObjectReference, player as ObjectReference)
                    Debug.Trace("[EllieRomance] Lover's Embrace perk spell cast on player.", 0)
                EndIf

                Debug.Notification("Даймонд-Сіті («Даґаут Інн»): Затишна ніч разом з Еллі. Отримано «Обійми коханця».")
                Debug.Notification("Еллі: «Я так рада прокидатися поруч з тобою... Гарного дня, любий!»")

                Utility.Wait(1.0)
                ; Встає та одягає ділове вбрання
                If EnableDynamicOutfits
                    EquipDayDress()
                EndIf

                If RomanceStage == 30
                    RomanceStage = 100
                    SetStage(100)
                    SetObjectiveCompleted(30, True)
                    Debug.Trace("[EllieRomance] Stage 30 completed. Romance permanently active (Stage 100).", 0)
                EndIf

                If AutoReturnAfterDelay
                    StartTimer(ReturnDelaySeconds, 2001)
                EndIf
                Return
            EndIf
        EndIf

        ; Звичайний щоденний сон поза побаченням: оновлення сукні
        If CurrentManualDressIndex == 0
            CycleToNextDress()
        Else
            ReapplyCurrentDress()
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
            CleanUpScarlett()
            CleanUpTableProps()
            RestoreDugoutInnBar()
            Debug.Trace("[EllieRomance] Ellie returned to Valentine Detective Agency.", 0)
        Else
            StartTimer(60.0, 2001)
        EndIf
    EndIf
EndFunction

;-- Wardrobe Selection & Outfit Swapping --------------------
Function ShowWardrobeSelectMenu()
    If EllieWardrobeSelectMessage == None
        Debug.Notification("Меню вибору сукні недоступне.")
        Return
    EndIf

    Actor ellie = GetEllie()
    Actor player = Game.GetPlayer()
    If ellie == None || player == None
        Return
    EndIf

    Int choice = EllieWardrobeSelectMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    If choice == 0
        ; 0: Автоматичний цикл
        CurrentManualDressIndex = 0
        CycleToNextDress()
        PlayEllieSmile()
        Debug.Notification("Еллі: «Чудово! Щодня я одягатиму нову сукню з моєї колекції.»")
    ElseIf choice == 1
        ; 1: Зелена довоєнна сукня
        If HasCleanGreen && CleanGreenDress != None
            CurrentManualDressIndex = 1
            EquipSpecificDress(CleanGreenDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Як тобі ця зелена сукня? Вона виглядає просто чудово!»")
        Else
            Debug.Notification("Еллі: «У мене ще немає такої зеленої сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 2
        ; 2: Синя домашня сукня
        If HasCleanBlue && CleanBlueDress != None
            CurrentManualDressIndex = 2
            EquipSpecificDress(CleanBlueDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Ця синя сукня така зручна та охайна. Дякую!»")
        Else
            Debug.Notification("Еллі: «У мене ще немає такої синьої сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 3
        ; 3: Рожева / Червона сукня
        If HasCleanRed && CleanRedDress != None
            CurrentManualDressIndex = 3
            EquipSpecificDress(CleanRedDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Цей колір додає мені впевненості! Мені дуже подобається.»")
        Else
            Debug.Notification("Еллі: «У мене ще немає цієї яскравої сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 4
        ; 4: Вечірня з блискітками
        If HasSequin && EveningSequinDress != None
            CurrentManualDressIndex = 4
            EquipSpecificDress(EveningSequinDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Ого, я вся сяю! Справжня зірка Даймонд-Сіті.»")
        Else
            Debug.Notification("Еллі: «У мене ще немає сукні з блискітками. Знайди її для мене!»")
        EndIf
    ElseIf choice == 5
        ; 5: Спокуслива вечірня (Slinky)
        If HasSlinky && EveningSlinkyDress != None
            CurrentManualDressIndex = 5
            EquipSpecificDress(EveningSlinkyDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Ох, ця сукня дійсно дуже смілива... Сподіваюся, тобі подобається.»")
        Else
            Debug.Notification("Еллі: «У мене ще немає червоної шовкової сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 6
        ; 6: Інші сукні...
        ShowWardrobeSelectMenu2()
    ElseIf choice == 7
        ; 7: Забрати стару сукню собі в колекцію
        TakeOldDressToPlayer(ellie, player)
    ElseIf choice == 8
        ; 8: Назад
    EndIf
EndFunction

Function ShowWardrobeSelectMenu2()
    If EllieWardrobeSelectMessage2 == None
        Return
    EndIf

    Int choice = EllieWardrobeSelectMessage2.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    If choice == 0
        ; 0: Трояндова
        If HasCleanRose && CleanRoseDress != None
            CurrentManualDressIndex = 6
            EquipSpecificDress(CleanRoseDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Ніжний трояндовий колір... Дякую за турботу!»")
        Else
            Debug.Notification("Еллі: «У мене ще немає цієї трояндової сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 1
        ; 1: Джинсова
        If HasCleanDenim && CleanDenimDress != None
            CurrentManualDressIndex = 7
            EquipSpecificDress(CleanDenimDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Практична та ошатна джинсова сукня. Чудовий вибір!»")
        Else
            Debug.Notification("Еллі: «У мене ще немає цієї джинсової сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 2
        ; 2: Кремова
        If HasCleanCream && CleanCreamDress != None
            CurrentManualDressIndex = 8
            EquipSpecificDress(CleanCreamDress)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Вишукана кремова довоєнна сукня. Вона ідеальна!»")
        Else
            Debug.Notification("Еллі: «У мене ще немає цієї кремової сукні. Знайди її для мене!»")
        EndIf
    ElseIf choice == 3
        ; 3: Назад до вибору суконь
        ShowWardrobeSelectMenu()
    EndIf
EndFunction

Function TakeOldDressToPlayer(Actor ellie, Actor player)
    If OldWastelandDress == None
        OldWastelandDress = Game.GetForm(0x001B828C) as Armor
    EndIf
    
    If ellie != None && player != None && OldWastelandDress != None
        Int oldCount = ellie.GetItemCount(OldWastelandDress as Form)
        If oldCount > 0
            ellie.UnequipItem(OldWastelandDress as Form, False, True)
            ellie.RemoveItem(OldWastelandDress as Form, oldCount, True, player as ObjectReference)
            PlayEllieSmile()
            Debug.Notification("Еллі: «Тримай мою стару сукню на пам'ять, якщо хочеш!»")
            Debug.Notification("Отримано: Стара сукня Еллі (для колекції).")
        Else
            Debug.Notification("Еллі: «У мене вже немає моєї старої сукні — вона вже в твоїй колекції!»")
        EndIf
    EndIf
EndFunction

Function UnequipAllDresses(Actor ellie)
    If ellie == None
        Return
    EndIf
    If CleanGreenDress != None
        ellie.UnequipItem(CleanGreenDress as Form, False, True)
    EndIf
    If CleanBlueDress != None
        ellie.UnequipItem(CleanBlueDress as Form, False, True)
    EndIf
    If CleanRedDress != None
        ellie.UnequipItem(CleanRedDress as Form, False, True)
    EndIf
    If CleanRoseDress != None
        ellie.UnequipItem(CleanRoseDress as Form, False, True)
    EndIf
    If CleanDenimDress != None
        ellie.UnequipItem(CleanDenimDress as Form, False, True)
    EndIf
    If CleanCreamDress != None
        ellie.UnequipItem(CleanCreamDress as Form, False, True)
    EndIf
    If EveningSequinDress != None
        ellie.UnequipItem(EveningSequinDress as Form, False, True)
    EndIf
    If EveningSlinkyDress != None
        ellie.UnequipItem(EveningSlinkyDress as Form, False, True)
    EndIf
    If OldWastelandDress == None
        OldWastelandDress = Game.GetForm(0x001B828C) as Armor
    EndIf
    If OldWastelandDress != None
        ellie.UnequipItem(OldWastelandDress as Form, False, True)
    EndIf
EndFunction

Function EquipSpecificDress(Armor target)
    Actor ellie = GetEllie()
    If ellie == None || target == None
        Return
    EndIf

    ; Переміщення старої сукні до гравця, якщо вона все ще в інвентарі
    Actor player = Game.GetPlayer()
    If OldWastelandDress == None
        OldWastelandDress = Game.GetForm(0x001B828C) as Armor
    EndIf
    If OldWastelandDress != None && ellie.GetItemCount(OldWastelandDress as Form) > 0 && player != None
        ellie.UnequipItem(OldWastelandDress as Form, False, True)
        ellie.RemoveItem(OldWastelandDress as Form, 99, True, player as ObjectReference)
        Debug.Notification("Стару сукню Еллі перенесено до вашої колекції.")
    EndIf

    ; Зняти інші сукні
    UnequipAllDresses(ellie)

    ; Переконатися у наявності цільової сукні в інвентарі
    If ellie.GetItemCount(target as Form) == 0
        ellie.AddItem(target as Form, 1, True)
    EndIf

    ; Надягнути сукню
    ellie.EquipItem(target as Form, False, True)
    CurrentEquippedDress = target
    ellie.EvaluatePackage(False)
EndFunction

Function CycleToNextDress()
    Actor ellie = GetEllie()
    If ellie == None
        Return
    EndIf

    If IsEllieInDugoutInn
        EquipEveningDress()
        Return
    EndIf

    Armor[] available = new Armor[6]
    Int count = 0
    If HasCleanGreen && CleanGreenDress != None
        available[count] = CleanGreenDress
        count += 1
    EndIf
    If HasCleanBlue && CleanBlueDress != None
        available[count] = CleanBlueDress
        count += 1
    EndIf
    If HasCleanRed && CleanRedDress != None
        available[count] = CleanRedDress
        count += 1
    EndIf
    If HasCleanRose && CleanRoseDress != None
        available[count] = CleanRoseDress
        count += 1
    EndIf
    If HasCleanDenim && CleanDenimDress != None
        available[count] = CleanDenimDress
        count += 1
    EndIf
    If HasCleanCream && CleanCreamDress != None
        available[count] = CleanCreamDress
        count += 1
    EndIf

    If count == 0
        If HasSequin && EveningSequinDress != None
            EquipSpecificDress(EveningSequinDress)
        ElseIf HasSlinky && EveningSlinkyDress != None
            EquipSpecificDress(EveningSlinkyDress)
        EndIf
        Return
    EndIf

    ActiveDayDressIndex = (ActiveDayDressIndex + 1) % count
    EquipSpecificDress(available[ActiveDayDressIndex])
    Debug.Trace("[EllieRomance] Cycled to dress index " + ActiveDayDressIndex + " (" + available[ActiveDayDressIndex] + ").", 0)
EndFunction

Function ReapplyCurrentDress()
    Actor ellie = GetEllie()
    If ellie == None
        Return
    EndIf

    ; Завжди вилучаємо стару сукню при появі
    If OldWastelandDress == None
        OldWastelandDress = Game.GetForm(0x001B828C) as Armor
    EndIf
    If OldWastelandDress != None && ellie.GetItemCount(OldWastelandDress as Form) > 0
        Actor player = Game.GetPlayer()
        If player != None
            ellie.UnequipItem(OldWastelandDress as Form, False, True)
            ellie.RemoveItem(OldWastelandDress as Form, 99, True, player as ObjectReference)
        EndIf
    EndIf

    If IsEllieInDugoutInn
        EquipEveningDress()
        Return
    EndIf

    If CurrentManualDressIndex == 1 && CleanGreenDress != None
        EquipSpecificDress(CleanGreenDress)
    ElseIf CurrentManualDressIndex == 2 && CleanBlueDress != None
        EquipSpecificDress(CleanBlueDress)
    ElseIf CurrentManualDressIndex == 3 && CleanRedDress != None
        EquipSpecificDress(CleanRedDress)
    ElseIf CurrentManualDressIndex == 4 && EveningSequinDress != None
        EquipSpecificDress(EveningSequinDress)
    ElseIf CurrentManualDressIndex == 5 && EveningSlinkyDress != None
        EquipSpecificDress(EveningSlinkyDress)
    ElseIf CurrentManualDressIndex == 6 && CleanRoseDress != None
        EquipSpecificDress(CleanRoseDress)
    ElseIf CurrentManualDressIndex == 7 && CleanDenimDress != None
        EquipSpecificDress(CleanDenimDress)
    ElseIf CurrentManualDressIndex == 8 && CleanCreamDress != None
        EquipSpecificDress(CleanCreamDress)
    Else
        ; Auto-cyclic mode (0)
        If CurrentEquippedDress != None
            EquipSpecificDress(CurrentEquippedDress)
        Else
            CycleToNextDress()
        EndIf
    EndIf
EndFunction

Function EquipDayDress()
    ReapplyCurrentDress()
EndFunction

Function EquipEveningDress()
    Actor ellie = GetEllie()
    If ellie == None
        Return
    EndIf

    If ActiveEveningDressIndex == 1 && HasSequin && EveningSequinDress != None
        EquipSpecificDress(EveningSequinDress)
    ElseIf HasSlinky && EveningSlinkyDress != None
        EquipSpecificDress(EveningSlinkyDress)
    ElseIf HasSequin && EveningSequinDress != None
        EquipSpecificDress(EveningSequinDress)
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
