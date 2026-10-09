ScriptName DebCaravanSupervisorScript Extends Quest

; Core References
Actor Property DebREF Auto Const
Actor Property StocktonREF Auto Const
Actor Property PlayerREF Auto Const
Location Property BunkerHillLocation Auto Const
Spell Property LoversEmbracePerkSpell Auto Const
Quest Property FFBunkerHill02 Auto Const
MiscObject Property Caps001 Auto Const
Form Property ArmoryChestBase Auto Const

; Placed World Chest
ObjectReference Property PlacedChest Auto

; Quest Stages / State
Int Property CaravanTier = 1 Auto
Bool Property ThreatActive = False Auto
Int Property StocktonContractStage = 0 Auto ; 0=none, 1=active (needs 3 sets), 2=ready to turn in, 3=paid/completed
Int Property StocktonRewardCaps = 3500 Auto

Event OnInit()
    RegisterForRemoteEvent(DebREF as ScriptObject, "OnActivate")
    RegisterForRemoteEvent(StocktonREF as ScriptObject, "OnActivate")
    RegisterForRemoteEvent(PlayerREF as ScriptObject, "OnLocationChange")
    RegisterForPlayerSleep()
    SpawnArmoryChest()
EndEvent

Function SpawnArmoryChest()
    If PlacedChest == None && DebREF != None && ArmoryChestBase != None
        PlacedChest = DebREF.PlaceAtMe(ArmoryChestBase, 1, True, False, False)
        PlacedChest.MoveTo(DebREF, 60.0, -40.0, 0.0, True)
    EndIf
EndFunction

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    If akSender == PlayerREF && akNewLoc == BunkerHillLocation
        SpawnArmoryChest()
        CheckLevelScaling()
    EndIf
EndEvent

Function CheckLevelScaling()
    Int playerLevel = PlayerREF.GetLevel()
    ; Check if threat triggers
    If playerLevel >= 15 && CaravanTier < 2 && !ThreatActive
        ThreatActive = True
        StocktonRewardCaps = 4000
        Debug.Notification("Деб: Шляхи стали небезпечнішими! Потрібно посилити караван до Тіру 2.")
    ElseIf playerLevel >= 30 && CaravanTier < 3 && !ThreatActive
        ThreatActive = True
        StocktonRewardCaps = 10000
        Debug.Notification("Деб: На каравани нападають важкоозброєні загони! Потрібно посилити захист (Тір 3).")
    ElseIf playerLevel >= 45 && CaravanTier < 4 && !ThreatActive
        ThreatActive = True
        StocktonRewardCaps = 25000
        Debug.Notification("Деб: Критична загроза на маршрутах! Потрібно топове спорядження караванів (Тір 4).")
    EndIf
EndFunction

Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
    If akActionRef != PlayerREF
        Return
    EndIf

    ; Deb interaction
    If akSender == DebREF
        If ThreatActive
            Debug.Notification("Деб: Наші люди гинуть на дорогах! Поклади комплект у Скриню арсеналу біля мого прилавка.")
        ElseIf FFBunkerHill02 != None && FFBunkerHill02.IsCompleted()
            Debug.Notification("Деб: Каравани під надійним захистом. Ти чудово справляєшся!")
        EndIf
    EndIf

    ; Stockton interaction
    If akSender == StocktonREF
        If StocktonContractStage == 1
            Debug.Notification("Стоктон: Мені потрібно 3 комплекти спорядження для моїх караванів у Скрині арсеналу.")
        ElseIf StocktonContractStage == 2
            ; Payout contract!
            StocktonContractStage = 3
            PlayerREF.AddItem(Caps001 as Form, StocktonRewardCaps, False)
            Debug.Notification("Стоктон: Чудова робота! Ось твоя преміальна плата: " + StocktonRewardCaps + " кришок.")
        EndIf
    EndIf
EndEvent

Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
    If akBed == None
        Return
    EndIf
    
    ; Check if sleeping in Bunker Hill
    Location bedLoc = akBed.GetCurrentLocation()
    If bedLoc == BunkerHillLocation || PlayerREF.GetCurrentLocation() == BunkerHillLocation
        If ThreatActive
            Debug.Notification("Деб: «Я не можу спати, поки мої люди під загрозою. Спершу захист!»")
        ElseIf CaravanTier >= 1
            If LoversEmbracePerkSpell != None
                LoversEmbracePerkSpell.Cast(PlayerREF, PlayerREF)
            EndIf
            Debug.Notification("Обійми коханця: Затишний відпочинок з Деб у Банкер-Гілл (+15% досвіду).")
        EndIf
    EndIf
EndEvent

Function OnChestInventoryChecked(CaravanArmoryChestScript akChest, Int aiCompleteSets)
    ; Priority 1: Upgrade Deb's caravan if threat is active and we have >= 1 set
    If ThreatActive && aiCompleteSets >= 1
        akChest.ConsumeSets(1)
        ThreatActive = False
        CaravanTier += 1
        aiCompleteSets -= 1
        Debug.Notification("Деб: Караван успішно оновлено до Тіру " + CaravanTier + "! Загрозу знято.")
        
        ; Now Stockton offers contract for his 3 caravans!
        StocktonContractStage = 1
        Debug.Notification("Стоктон помітив оновлення: відкрився контракт на озброєння 3-х його караванів!")
    EndIf

    ; Priority 2: Fulfill Stockton's contract if active and we have >= 3 sets
    If StocktonContractStage == 1 && aiCompleteSets >= 3
        akChest.ConsumeSets(3)
        StocktonContractStage = 2
        Debug.Notification("Контракт Стоктона виконано! Отримай плату (" + StocktonRewardCaps + " кришок) у Стоктона.")
    EndIf
EndFunction
