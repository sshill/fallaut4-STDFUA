ScriptName MercyRecruitmentQuestScript Extends Quest
{ Main Quest Controller for Mercy & Settler Recruitment (Shelly Tiller & Surrendered Enemies) }

;-- Form Properties ----------------------------------------
Actor Property ShellyRef Auto
Actor Property PiperRef Auto
workshopparentscript Property WorkshopParent Auto Const
Quest Property MS04 Auto Const
ActorValue Property CA_Affinity Auto Const
Faction Property CurrentCompanionFaction Auto Const
Faction Property WorkshopNPCFaction Auto Const
Faction Property REIgnoreForCleanup Auto Const
Faction Property PlayerFaction Auto Const
Faction Property REDialogueRescued Auto Const
Keyword Property WorkshopAssignHomePermanentActor Auto Const
Message Property ShellyRecruitDialogueMessage Auto Const
ActorValue Property CharismaAV Auto Const
MiscObject Property CapsItem Auto Const
Perk Property MercyRecruitmentPerk Auto Const
Message Property CivilianRecruitDialogueMessage Auto Const

;-- State Properties ---------------------------------------
Bool Property IsShellyRecruited = False Auto
Bool Property IsShellySpared = False Auto
Bool Property IsTheaterCultistsFixed = False Auto

;-- Helper Getters -----------------------------------------
Actor Function GetShelly()
    If ShellyRef == None
        ShellyRef = Game.GetForm(0x000E1D28) as Actor
    EndIf
    Return ShellyRef
EndFunction

Actor Function GetPiper()
    If PiperRef == None
        PiperRef = Game.GetForm(0x00002F1F) as Actor
    EndIf
    Return PiperRef
EndFunction

;-- Initialization & Lifecycle -----------------------------
Event OnInit()
    InitializeMod()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    InitializeMod()
EndEvent

Function InitializeMod()
    Actor player = Game.GetPlayer()
    If player != None
        RegisterForRemoteEvent(player as ScriptObject, "OnPlayerLoadGame")
        RegisterForRemoteEvent(player as ScriptObject, "OnLocationChange")
        If MercyRecruitmentPerk != None
            player.AddPerk(MercyRecruitmentPerk, False)
        EndIf
    EndIf
    
    Actor shelly = GetShelly()
    If shelly != None && !IsShellyRecruited && !IsShellySpared && !shelly.IsDead()
        shelly.BlockActivation(True, False)
        RegisterForRemoteEvent(shelly as ScriptObject, "OnActivate")
        Debug.Trace("[MercyRecruitment] Shelly activation blocked and remote event registered.", 0)
    EndIf
    
    FixTheaterCultists()
EndFunction

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    If akSender == Game.GetPlayer()
        InitializeMod()
    EndIf
EndEvent

;-- Interaction Interception -------------------------------
Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
    Actor shelly = GetShelly()
    If akSender == (shelly as ObjectReference) && akActionRef == (Game.GetPlayer() as ObjectReference)
        If !IsShellyRecruited && !IsShellySpared
            ShowShellyDialogue()
        EndIf
    EndIf
EndEvent

Function ShowShellyDialogue()
    Actor shelly = GetShelly()
    If shelly == None || IsShellyRecruited || IsShellySpared
        Return
    EndIf
    
    If ShellyRecruitDialogueMessage == None
        RecruitShelly(shelly)
        Return
    EndIf
    
    Int choice = ShellyRecruitDialogueMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If choice == 0
        ; 0: «Тобі більше не треба ховатися серед гулів. У мене є безпечне поселення — вирушай туди.»
        RecruitShelly(shelly)
    ElseIf choice == 1
        ; 1: «Кендра надіслала мене вбити тебе, але я не вбиваю беззахисних. Тікай звідси.»
        SpareShelly(shelly)
    Else
        ; 2: «Залишайся тут, я скоро повернуся.»
        Debug.Notification("Шеллі продовжує переховуватися.")
    EndIf
EndFunction

;-- Async Settlement Assignment ----------------------------
Event ObjectReference.OnWorkshopNPCTransfer(ObjectReference akSender, Location akNewWorkshopLocation, Keyword akActionKW)
    Actor akActor = akSender as Actor
    If akActor == None || WorkshopParent == None || akNewWorkshopLocation == None
        Return
    EndIf
    
    workshopscript ws = WorkshopParent.GetWorkshopFromLocation(akNewWorkshopLocation)
    If ws == None
        Return
    EndIf
    
    akSender.SetLinkedRef(ws as ObjectReference, WorkshopParent.WorkshopItemKeyword)
    akSender.SetPersistLoc(ws.myLocation)
    If WorkshopParent.PermanentActorAliases != None
        WorkshopParent.PermanentActorAliases.AddRef(akSender)
    EndIf
    WorkshopParent.ApplyWorkshopAliasData(akActor)
    
    workshopnpcscript wsNPC = akSender as workshopnpcscript
    If wsNPC != None
        WorkshopParent.AddActorToWorkshopPUBLIC(wsNPC, ws, False)
        WorkshopParent.TryToAutoAssignActor(ws, wsNPC)
    EndIf
    ws.RecalculateWorkshopResources(True)
    UnregisterForRemoteEvent(akSender as ScriptObject, "OnWorkshopNPCTransfer")
EndEvent

;-- Settlement Registration Helper -------------------------
Function AssignActorToSettlement(Actor akTarget, Location targetLoc, workshopnpcscript wsNPC)
    If akTarget == None
        Return
    EndIf
    
    workshopscript ws = None
    If WorkshopParent != None
        If targetLoc != None
            ws = WorkshopParent.GetWorkshopFromLocation(targetLoc)
        ElseIf wsNPC != None && wsNPC.GetWorkshopID() > -1
            ws = WorkshopParent.GetWorkshop(wsNPC.GetWorkshopID())
        EndIf
    EndIf
    
    If ws != None
        akTarget.SetLinkedRef(ws as ObjectReference, WorkshopParent.WorkshopItemKeyword)
        WorkshopParent.AssignHomeMarkerToActor(akTarget, ws)
        akTarget.SetPersistLoc(ws.myLocation)
        If WorkshopParent.PermanentActorAliases != None
            WorkshopParent.PermanentActorAliases.AddRef(akTarget as ObjectReference)
        EndIf
        WorkshopParent.ApplyWorkshopAliasData(akTarget)
    EndIf
    
    If wsNPC != None
        wsNPC.SetWorkshopStatus(True)
        wsNPC.bCountsForPopulation = True
        wsNPC.SetCommandable(True)
        wsNPC.SetAllowMove(True)
        wsNPC.SetAllowCaravan(True)
        
        If ws != None && wsNPC.GetWorkshopID() != ws.GetWorkshopID()
            WorkshopParent.AddActorToWorkshopPUBLIC(wsNPC, ws, False)
            WorkshopParent.TryToAutoAssignActor(ws, wsNPC)
        EndIf
    EndIf
    
    If ws != None
        ws.RecalculateWorkshopResources(True)
    EndIf
    
    akTarget.SetRestrained(False)
    akTarget.BlockActivation(False, False)
    akTarget.EvaluatePackage(False)
EndFunction

;-- Settler Registration For Theater Actors -----------------
Bool Function RegisterTheaterSettler(Actor akActor, workshopscript akWS)
    If akActor == None || akWS == None || akActor.IsDead()
        Return False
    EndIf
    
    akActor.AddToFaction(WorkshopNPCFaction)
    akActor.SetLinkedRef(akWS as ObjectReference, WorkshopParent.WorkshopItemKeyword)
    akActor.SetPersistLoc(akWS.myLocation)
    If WorkshopParent.PermanentActorAliases != None
        WorkshopParent.PermanentActorAliases.AddRef(akActor as ObjectReference)
    EndIf
    
    akActor.SetCrimeFaction(None)
    akActor.SetValue(Game.GetAggressionAV(), 0.0)
    akActor.StopCombat()
    akActor.StopCombatAlarm()
    
    workshopnpcscript wsNPC = akActor as workshopnpcscript
    If wsNPC != None
        wsNPC.SetWorkshopStatus(True)
        wsNPC.bCountsForPopulation = True
        wsNPC.SetCommandable(True)
        wsNPC.SetAllowMove(True)
        wsNPC.SetAllowCaravan(True)
        If wsNPC.GetWorkshopID() != akWS.GetWorkshopID()
            WorkshopParent.AddActorToWorkshopPUBLIC(wsNPC, akWS, False)
            WorkshopParent.TryToAutoAssignActor(akWS, wsNPC)
        EndIf
    Else
        WorkshopParent.AssignHomeMarkerToActor(akActor, akWS)
    EndIf
    WorkshopParent.ApplyWorkshopAliasData(akActor)
    
    akActor.SetRestrained(False)
    akActor.BlockActivation(False, False)
    akActor.EvaluatePackage(False)
    Return True
EndFunction

;-- Auto-Recovery For Theater Cultists ----------------------
Function FixTheaterCultists()
    If IsTheaterCultistsFixed
        Return
    EndIf

    workshopscript hangmansWS = Game.GetForm(0x001F0711) as workshopscript
    If hangmansWS == None && WorkshopParent != None
        Location hangmansLoc = Game.GetForm(0x001B8C53) as Location
        If hangmansLoc != None
            hangmansWS = WorkshopParent.GetWorkshopFromLocation(hangmansLoc)
        EndIf
    EndIf
    
    If hangmansWS == None
        Debug.Trace("[MercyRecruitment] FixTheaterCultists: Hangman's Alley workshop not found.", 0)
        Return
    EndIf
    
    Int[] cultistIDs = new Int[7]
    cultistIDs[0] = 0x000BBF8D
    cultistIDs[1] = 0x000BDB17
    cultistIDs[2] = 0x000BDB18
    cultistIDs[3] = 0x000C1730
    cultistIDs[4] = 0x0017208A
    cultistIDs[5] = 0x0019DEFB
    cultistIDs[6] = 0x0019DEFD
    
    Int i = 0
    Int fixedCount = 0
    While i < cultistIDs.Length
        Actor cultist = Game.GetForm(cultistIDs[i]) as Actor
        If RegisterTheaterSettler(cultist, hangmansWS)
            fixedCount += 1
        EndIf
        i += 1
    EndWhile

    ; Goodneighbor drifters at Hangman's Alley (base actor IDs from build_mercy_recruitment_esp.py)
    Int[] drifterBaseIDs = new Int[6]
    drifterBaseIDs[0] = 0x00023328
    drifterBaseIDs[1] = 0x00023346
    drifterBaseIDs[2] = 0x00023347
    drifterBaseIDs[3] = 0x0004F047
    drifterBaseIDs[4] = 0x0004F049
    drifterBaseIDs[5] = 0x0004F04B
    Keyword npcKW = Game.GetForm(0x00013794) as Keyword
    If npcKW != None
        ObjectReference[] nearby = hangmansWS.FindAllReferencesWithKeyword(npcKW as Form, 3000.0)
        Int n = 0
        While n < nearby.Length
            Actor drifter = nearby[n] as Actor
            If drifter != None && drifter != Game.GetPlayer()
                ActorBase drifterBase = drifter.GetActorBase()
                Int j = 0
                While drifterBase != None && j < drifterBaseIDs.Length
                    If drifterBase.GetFormID() == drifterBaseIDs[j]
                        If RegisterTheaterSettler(drifter, hangmansWS)
                            fixedCount += 1
                        EndIf
                        j = drifterBaseIDs.Length
                    EndIf
                    j += 1
                EndWhile
            EndIf
            n += 1
        EndWhile
    EndIf
    
    If fixedCount > 0
        hangmansWS.RecalculateWorkshopResources(True)
        Debug.Trace("[MercyRecruitment] FixTheaterCultists: Auto-recovered and registered " + fixedCount + " theater cultists to Hangman's Alley.", 0)
        Debug.Notification("Завербовані культисти театру стали повноцінними поселенцями Завулку шибеника (" + fixedCount + ").")
        IsTheaterCultistsFixed = True
    EndIf
EndFunction

;-- Shelly Recruitment & Mercy Logic ------------------------
Function RecruitShelly(Actor akShelly)
    If akShelly == None || IsShellyRecruited
        Return
    EndIf
    
    Location targetLoc = None
    workshopnpcscript wsNPC = akShelly as workshopnpcscript
    
    If wsNPC != None && WorkshopParent != None
        targetLoc = WorkshopParent.AddPermanentActorToWorkshopPlayerChoice(akShelly, True)
    ElseIf akShelly != None
        RegisterForRemoteEvent(akShelly as ScriptObject, "OnWorkshopNPCTransfer")
        targetLoc = akShelly.OpenWorkshopSettlementMenu(WorkshopAssignHomePermanentActor, None, None)
    EndIf
    
    If targetLoc != None || (wsNPC != None && wsNPC.GetWorkshopID() > -1)
        IsShellyRecruited = True
        
        akShelly.StopCombat()
        akShelly.StopCombatAlarm()
        akShelly.SetCrimeFaction(None)
        akShelly.SetValue(Game.GetAggressionAV(), 0.0)
        akShelly.AddToFaction(WorkshopNPCFaction)
        akShelly.AddToFaction(REIgnoreForCleanup)
        akShelly.AddToFaction(PlayerFaction)
        If WorkshopParent != None && WorkshopParent.PermanentActorAliases != None
            WorkshopParent.PermanentActorAliases.AddRef(akShelly as ObjectReference)
        EndIf
        If REDialogueRescued != None
            akShelly.RemoveFromFaction(REDialogueRescued)
        EndIf
        akShelly.SetEssential(True)
        
        AssignActorToSettlement(akShelly, targetLoc, wsNPC)
        
        ; Безпечне закриття опціонального вбивства у квесті MS04 (Alias ID 57 = KendraTarget)
        If MS04 != None
            MS04.SetObjectiveDisplayed(442, False, False)
            ReferenceAlias kendraTarget = MS04.GetAlias(57) as ReferenceAlias
            If kendraTarget != None
                kendraTarget.Clear()
            EndIf
        EndIf
        
        UnregisterForRemoteEvent(akShelly as ScriptObject, "OnActivate")
        
        TriggerPiperAffinityReaction(15.0)
        Debug.Notification("Шеллі Тіллер завербована та вирушила до поселення.")
    Else
        Debug.Notification("Вербування скасовано.")
    EndIf
EndFunction

Function SpareShelly(Actor akShelly)
    If akShelly == None
        Return
    EndIf
    
    IsShellySpared = True
    
    If MS04 != None
        MS04.SetObjectiveDisplayed(442, False, False)
        ReferenceAlias kendraTarget = MS04.GetAlias(57) as ReferenceAlias
        If kendraTarget != None
            kendraTarget.Clear()
        EndIf
    EndIf
    
    akShelly.StopCombat()
    akShelly.StopCombatAlarm()
    akShelly.SetCrimeFaction(None)
    akShelly.SetValue(Game.GetAggressionAV(), 0.0)
    akShelly.AddToFaction(PlayerFaction)
    akShelly.BlockActivation(False, False)
    UnregisterForRemoteEvent(akShelly as ScriptObject, "OnActivate")
    akShelly.EvaluatePackage(False)
    
    TriggerPiperAffinityReaction(10.0)
    Debug.Notification("Шеллі Тіллер подякувала вам і втекла у безпечне місце.")
EndFunction

Function TriggerPiperAffinityReaction(Float afAmount)
    Actor piper = GetPiper()
    Actor player = Game.GetPlayer()
    Bool isPiperActive = False
    
    If piper != None && player != None
        If piper.IsInFaction(CurrentCompanionFaction) || piper.GetDistance(player) < 3000.0
            isPiperActive = True
        EndIf
    EndIf
    
    If isPiperActive
        If CA_Affinity != None
            piper.ModValue(CA_Affinity, afAmount)
        EndIf
        Debug.Notification("Пайпер це сподобалося.")
        piper.EvaluatePackage(False)
    EndIf
EndFunction

;-- General Surrendered Enemy Recruitment -------------------
Function RecruitSurrenderedTarget(Actor akTarget)
    If akTarget == None || akTarget.IsDead() || akTarget == Game.GetPlayer()
        Return
    EndIf
    
    If akTarget.IsEssential() && !akTarget.IsBleedingOut()
        Debug.Notification("Цього персонажа не можна завербувати.")
        Return
    EndIf
    
    Location targetLoc = None
    workshopnpcscript wsNPC = akTarget as workshopnpcscript
    If wsNPC != None && WorkshopParent != None
        targetLoc = WorkshopParent.AddPermanentActorToWorkshopPlayerChoice(akTarget, True)
    ElseIf akTarget != None
        targetLoc = akTarget.OpenWorkshopSettlementMenu(WorkshopAssignHomePermanentActor, None, None)
    EndIf
    
    If targetLoc != None || (wsNPC != None && wsNPC.GetWorkshopID() > -1)
        akTarget.StopCombat()
        akTarget.StopCombatAlarm()
        akTarget.RemoveFromAllFactions()
        akTarget.SetCrimeFaction(None)
        akTarget.SetValue(Game.GetAggressionAV(), 0.0)
        akTarget.AddToFaction(PlayerFaction)
        akTarget.AddToFaction(WorkshopNPCFaction)
        akTarget.AddToFaction(REIgnoreForCleanup)
        If REDialogueRescued != None
            akTarget.RemoveFromFaction(REDialogueRescued)
        EndIf
        
        AssignActorToSettlement(akTarget, targetLoc, wsNPC)
        
        TriggerPiperAffinityReaction(10.0)
        Debug.Notification("Помилуваного завербовано до поселення.")
    Else
        Debug.Notification("Вербування скасовано.")
    EndIf
EndFunction

;-- Peaceful Civilian & Scavenger Recruitment --------------
Function RecruitPeacefulCivilian(Actor akTarget)
    If akTarget == None || akTarget.IsDead() || akTarget == Game.GetPlayer()
        Return
    EndIf
    
    ; Перенаправлення Шеллі Тіллер на спеціальний сюжетний діалог
    If akTarget == GetShelly()
        ShowShellyDialogue()
        Return
    EndIf
    
    ; Захист активних супутників від вербування як звичайних поселенців
    If akTarget.IsInFaction(CurrentCompanionFaction)
        Return
    EndIf
    
    ; 1. Перевірка: чи персонаж уже є поселенцем і прив'язаний до майстерні
    If akTarget.IsInFaction(WorkshopNPCFaction) && akTarget.GetLinkedRef(WorkshopParent.WorkshopItemKeyword) != None
        Debug.Notification("Цей персонаж уже живе у вашому поселенні.")
        Return
    EndIf
    
    ; 2. Перевірка на бойовий стан
    If akTarget.IsInCombat() || Game.GetPlayer().IsInCombat()
        If akTarget.IsBleedingOut()
            RecruitSurrenderedTarget(akTarget)
        Else
            Debug.Notification("Зараз триває бій! Вербування неможливе.")
        EndIf
        Return
    EndIf
    
    ; 3. Перевірка сюжетних / безсмертних персонажів
    If akTarget.IsEssential()
        Debug.Notification("Цього персонажа не можна завербувати.")
        Return
    EndIf
    
    ; 4. Перевірка Харизми або вибір допомоги
    Actor player = Game.GetPlayer()
    Float playerCharisma = 1.0
    If CharismaAV != None
        playerCharisma = player.GetValue(CharismaAV)
    EndIf
    
    Bool paidCaps = False
    If CivilianRecruitDialogueMessage != None
        Int choice = CivilianRecruitDialogueMessage.Show(playerCharisma, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        If choice == 0
            ; 0: «У мене є захищене поселення. Приєднуйся до нас (Харизма 6+)»
            If playerCharisma < 6.0
                Debug.Notification("Вам не вистачило переконливості (Потрібна Харизма 6+).")
                Return
            EndIf
        ElseIf choice == 1
            ; 1: «Ось 50 кришок та припаси на дорогу (Без перевірки харизми)»
            If CapsItem != None
                If player.GetItemCount(CapsItem as Form) < 50
                    Debug.Notification("У вас недостатньо кришок (потрібно 50).")
                    Return
                EndIf
                player.RemoveItem(CapsItem as Form, 50, False, None)
                paidCaps = True
            EndIf
        Else
            ; 2: «Бувай (Скасувати)»
            Return
        EndIf
    EndIf
    
    ; 5. Відкриваємо меню вибору поселення
    Location targetLoc = None
    workshopnpcscript wsNPC = akTarget as workshopnpcscript
    If wsNPC != None && WorkshopParent != None
        targetLoc = WorkshopParent.AddPermanentActorToWorkshopPlayerChoice(akTarget, True)
    ElseIf akTarget != None
        targetLoc = akTarget.OpenWorkshopSettlementMenu(WorkshopAssignHomePermanentActor, None, None)
    EndIf
    
    ; 6. Якщо поселення обрано — завершуємо налаштування
    If targetLoc != None || (wsNPC != None && wsNPC.GetWorkshopID() > -1)
        akTarget.StopCombat()
        akTarget.StopCombatAlarm()
        akTarget.SetCrimeFaction(None)
        akTarget.SetValue(Game.GetAggressionAV(), 0.0)
        akTarget.AddToFaction(WorkshopNPCFaction)
        akTarget.AddToFaction(REIgnoreForCleanup)
        akTarget.AddToFaction(PlayerFaction)
        If REDialogueRescued != None
            akTarget.RemoveFromFaction(REDialogueRescued)
        EndIf
        
        AssignActorToSettlement(akTarget, targetLoc, wsNPC)
        
        TriggerPiperAffinityReaction(15.0)
        Debug.Notification("Мирний житель погодився і вирушив до поселення.")
    Else
        ; Якщо вербування скасовано, а гравець заплатив кришки — повертаємо їх
        If paidCaps && CapsItem != None
            player.AddItem(CapsItem as Form, 50, True)
        EndIf
        Debug.Notification("Вербування скасовано.")
    EndIf
EndFunction
