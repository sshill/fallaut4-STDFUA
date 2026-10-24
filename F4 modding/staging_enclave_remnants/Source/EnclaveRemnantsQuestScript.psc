ScriptName EnclaveRemnantsQuestScript Extends Quest

; ==============================================================================
; Enclave Remnants - Echoes of the Past Stand Quest Controller
; Architecture: Linux Wine 10 / DXVK 2.6 / Fallout 4 GOTY v1.10.163.0
; ==============================================================================

; Core Engine References
Actor Property PlayerREF Auto Const
Location Property AtlanticOfficesLocation Auto Const
Cell Property GlowingSeaPOIDB05 Auto Const
MiscObject Property Caps001 Auto Const

; Quest Progression Flags
Bool Property BeaconDiscovered = False Auto
Bool Property RoadblockCleared = False Auto
Bool Property AtlanticOfficesDiscovered = False Auto
Bool Property BaseWipedOut = False Auto

Event OnInit()
    RegisterForRemoteEvent(PlayerREF as ScriptObject, "OnLocationChange")
    TuneHomingBeacon()
EndEvent

Function TuneHomingBeacon()
    If !BeaconDiscovered
        BeaconDiscovered = True
        SetStage(10)
        Debug.Notification("📡 [Піп-Бой]: Спіймано сигнал частоти: «Аварійний маяк Анклаву» (Сяюче море).")
        Debug.Trace("EnclaveRemnants: Stage 10 set, homing beacon active.", 0)
    EndIf
EndFunction

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    If akSender != PlayerREF
        Return
    EndIf

    ; Check if entering Atlantic Offices area in Glowing Sea
    If akNewLoc == AtlanticOfficesLocation || (PlayerREF.GetParentCell() == GlowingSeaPOIDB05)
        If GetStage() < 40
            SetStage(40)
            AtlanticOfficesDiscovered = True
            Debug.Notification("⚠️ [Анклав]: Виявлено польовий штаб Анклаву — Atlantic Offices!")
            Debug.Notification("⚠️ Бойова тривога: Майор Еліас та штурмовий підрозділ Анклаву відкрили вогонь!")
        EndIf
    EndIf
EndEvent

Function ReportRoadblockCleared()
    If !RoadblockCleared
        RoadblockCleared = True
        SetStage(20)
        Debug.Notification("🎖️ [Анклав]: Передовий блокпост біля Согус зачищено. Сигнал маяка веде в Сяюче море.")
    EndIf
EndFunction

Function WipeOutEnclaveBase()
    If !BaseWipedOut
        BaseWipedOut = True
        SetStage(100)
        If Caps001 != None
            PlayerREF.AddItem(Caps001 as Form, 3000, False)
        EndIf
        Debug.Notification("🎖️ [Анклав]: Базу в Сяючому морі знищено! Отримано нагороду: 3000 кришок.")
        Stop()
    EndIf
EndFunction
