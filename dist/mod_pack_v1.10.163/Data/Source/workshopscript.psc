ScriptName WorkshopScript Extends ObjectReference conditional
{ script for Workshop reference }

;-- Structs -----------------------------------------
Struct DailyUpdateData
  Int totalPopulation
  Int robotPopulation
  Int brahminPopulation
  Int unassignedPopulation
  Float vendorIncome
  Float currentHappiness
  Float damageMult
  Float productivity
  Int availableBeds
  Int shelteredBeds
  Int bonusHappiness
  Int happinessModifier
  Int safety
  Int safetyDamage
  Int foodProduction
  Int waterProduction
  Int availableFood
  Int availableWater
  Int safetyPerNPC
  Float totalHappiness
EndStruct


;-- Variables ---------------------------------------
Int WorkshopID = -1
Float attackChanceBase = 0.02 Const
Float attackChancePopulationMult = 0.005 Const
Float attackChanceResourceMult = 0.001 Const
Float attackChanceSafetyMult = 0.01 Const
Float attractNPCDailyChance = 0.100000001 Const
Float attractNPCHappinessMult = 0.5 Const
Bool bDailyUpdateInProgress = False
Float brahminProductionBoost = 0.5
Int buildWorkObjectTimerID = 0 Const
Int dailyUpdateTimerID = 1 Const
Float damageDailyPopulationMult = 0.200000003 Const
Float damageDailyRepairBase = 5.0 Const
Float happinessBonusBed = 10.0 Const
Int happinessBonusChangePerUpdate = 2 Const
Float happinessBonusFood = 20.0 Const
Float happinessBonusSafety = 20.0 Const
Float happinessBonusShelter = 10.0 Const
Float happinessBonusWater = 20.0 Const
Float happinessChangeMult = 0.200000003 Const
Int iBaseMaxNPCs = 10 Const
Int iMaxBonusAttractChancePopulation = 5 Const
Int iMaxSurplusNPCs = 5 Const
Int maxBrahminFertilizerProduction = 3
Float maxDailyUpdateWaitHours = 1.0
Float maxHappinessNoFood = 30.0 Const
Float maxHappinessNoShelter = 60.0 Const
Float maxHappinessNoWater = 30.0 Const
Int maxProductionPerBrahmin = 10
Int maxStoredFertilizerBase = 10
Int maxStoredFoodBase = 10 Const
Int maxStoredFoodPerPopulation = 1 Const
Int maxStoredScavengeBase = 100 Const
Int maxStoredScavengePerPopulation = 5 Const
Int maxStoredWaterBase = 5 Const
Float maxStoredWaterPerPopulation = 0.25 Const
Float maxVendorIncome = 50.0
Float minDailyUpdateWaitHours = 0.200000003
Float minDaysSinceLastAttack = 7.0 Const
Int minHappinessChangePerUpdate = 1 Const
Int minHappinessClearWarningThreshold = 20 Const
Int minHappinessThreshold = 10 Const
Int minHappinessWarningThreshold = 15 Const
Float minProductivity = 0.25 Const
Int minVendorIncomePopulation = 5
Float productivityHappinessMult = 0.75 Const
Bool showVendorTraces = True
Float vendorIncomeBaseMult = 2.0
Float vendorIncomePopulationMult = 0.029999999

;-- Properties --------------------------------------
Group Optional
  Faction Property SettlementOwnershipFaction Auto
  { optional - if the workshop settlement has an ownership faction, set this here so the player can be added to that faction when workshop becomes player-owned }
  Bool Property UseOwnershipFaction = True Auto
  { set to false to not use the ownership faction }
  ActorBase Property CustomWorkshopNPC Auto Const
  { Patch 1.4: the actor that gets created when a settlement makes a successful recruitment roll - overrides properties on WorkshopParentScript }
  Message Property CustomUnownedMessage Auto Const
  { Patch 1.4: a custom unowned message, that overrides standard messages from WorkshopParentScript }
  Bool Property AllowBrahminRecruitment = True Auto Const
  { Patch 1.6: set to false to prevent brahmin from being randomly recruited at this workshop settlement }
EndGroup

Group BuildingBudget
  Int Property MaxTriangles Auto
  { if > 0, initialize WorkshopMaxTriangles to this value }
  Int Property MaxDraws Auto
  { if > 0, initialize WorkshopMaxDraws to this value }
  Int Property CurrentTriangles Auto
  { if > 0, initialize WorkshopCurrentTriangles to this value }
  Int Property CurrentDraws Auto
  { if > 0, initialize WorkshopCurrentDraws to this value }
EndGroup

Group Flags
  Bool Property OwnedByPlayer = False Auto conditional
  { all workshops start "unowned" - activate after location is cleared to "own" }
  Bool Property StartsHostile = False Auto conditional
  { set to true for workbench locations that start out with hostiles in control (to prevent it being counted as a valid Minuteman recruiting target) }
  Bool Property EnableAutomaticPlayerOwnership = True Auto
  { TRUE = workshop will automatically become usable when the location is cleared (or if there are no bosses)
	  FALSE = workshop won't be usable by player until SetOwnedByPlayer(true) is called on it }
  Bool Property AllowUnownedFromLowHappiness = False Auto
  { TRUE = workshop can become unowned due to low happiness (<=minHappinessThreshold)
		FALSE (default) = workshop can never become unowned, no matter how low the happiness (for special cases like the Castle) }
  Bool Property HappinessWarning Auto conditional hidden
  { set to true when happiness warning given; set back to false when happiness goes above the warning level 
	  NOTE: only applies when AllowUnownedFromLowHappiness = true }
  Int Property DaysSinceLastVisit Auto conditional hidden
  { this gets cleared when player visits, incremented by daily update }
  Bool Property PlayerHasVisited Auto conditional hidden
  { this gets set to true the first time player visits - used by ResetWorkshop to initialize data on first visit }
  Bool Property MinRecruitmentProhibitRandom = False Auto conditional
  { set to TRUE to prohibit random Minutemen recruitment quests from picking this workshop }
  Bool Property MinRecruitmentAllowRandomAfterPlayerOwned = True Auto conditional
  { set to FALSE to prohibit random Minutemen quests from picking this workshop AFTER the player takes over (TRUE = random quests are allowed once owned by player) }
  Bool Property AllowAttacksBeforeOwned = True Auto conditional
  { set to FALSE to prevent attacks when unowned
		NOTE: this always gets set to true when the player takes ownership for the first time }
  Bool Property AllowAttacks = True Auto conditional
  { set to FALSE to prevent ALL random attacks (e.g. the Castle) }
  Bool Property RadioBeaconFirstRecruit = False Auto conditional hidden
  { set to true after player first builds a radio beacon here and gets the first "quick" recruit }
  Bool Property ShowedWorkshopMenuExitMessage = False Auto conditional hidden
  { set to true after player first exits the workshop menu here }
EndGroup

Group VendorData
  ObjectReference[] Property VendorContainersMisc Auto hidden
  { array of Misc vendor containers, indexed by vendor level }
  ObjectReference[] Property VendorContainersArmor Auto hidden
  ObjectReference[] Property VendorContainersWeapons Auto hidden
  ObjectReference[] Property VendorContainersBar Auto hidden
  ObjectReference[] Property VendorContainersClinic Auto hidden
  ObjectReference[] Property VendorContainersClothing Auto hidden
EndGroup

Group WorkshopRadioData
  ObjectReference Property WorkshopRadioRef Auto Const
  { if WorkshopRadioRef exists, it will override the default WorkshopRadioRef from WorkshopParent }
  Float Property workshopRadioInnerRadius = 9000.0 Auto Const
  { override workshop parent values }
  Float Property workshopRadioOuterRadius = 20000.0 Auto Const
  { override workshop parent values }
  Scene Property WorkshopRadioScene Auto Const
  { if WorkshopRadioRef exists, WorkshopRadioScene will be started instead of the default scene from WorkshopParent }
  Bool Property bWorkshopRadioRefIsUnique = True Auto Const
  { TRUE: WorkshopRadioScene is unique to this workshop, so it should be stopped/disabled when radio is shut off (completely) }
EndGroup

workshopparentscript Property WorkshopParent Auto Const mandatory
{ parent quest - holds most general workshop properties }
Location Property myLocation Auto hidden
{ workshop's location (filled onInit)
 this is a property so the WorkshopParent script can access it }
ObjectReference Property myMapMarker Auto hidden
{ workshop's map marker (filled by WorkshopParent.InitializeLocation) }

;-- Functions ---------------------------------------

ObjectReference[] Function GetVendorContainersByType(Int vendorType)
  If vendorType == 0 ; #DEBUG_LINE_NO:240
    If VendorContainersMisc == None ; #DEBUG_LINE_NO:241
      VendorContainersMisc = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:242
    EndIf
    Return VendorContainersMisc ; #DEBUG_LINE_NO:244
  ElseIf vendorType == 1 ; #DEBUG_LINE_NO:245
    If VendorContainersArmor == None ; #DEBUG_LINE_NO:248
      VendorContainersArmor = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:249
    EndIf
    Return VendorContainersArmor ; #DEBUG_LINE_NO:251
  ElseIf vendorType == 2 ; #DEBUG_LINE_NO:252
    If VendorContainersWeapons == None ; #DEBUG_LINE_NO:253
      VendorContainersWeapons = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:254
    EndIf
    Return VendorContainersWeapons ; #DEBUG_LINE_NO:256
  ElseIf vendorType == 3 ; #DEBUG_LINE_NO:257
    If VendorContainersBar == None ; #DEBUG_LINE_NO:258
      VendorContainersBar = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:259
    EndIf
    Return VendorContainersBar ; #DEBUG_LINE_NO:261
  ElseIf vendorType == 4 ; #DEBUG_LINE_NO:262
    If VendorContainersClinic == None ; #DEBUG_LINE_NO:263
      VendorContainersClinic = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:264
    EndIf
    Return VendorContainersClinic ; #DEBUG_LINE_NO:266
  ElseIf vendorType == 5 ; #DEBUG_LINE_NO:267
    If VendorContainersClothing == None ; #DEBUG_LINE_NO:268
      VendorContainersClothing = Self.InitializeVendorChests(vendorType) ; #DEBUG_LINE_NO:269
    EndIf
    Return VendorContainersClothing ; #DEBUG_LINE_NO:271
  EndIf
EndFunction

ObjectReference[] Function InitializeVendorChests(Int vendorType)
  Int containerArraySize = WorkshopParent.VendorTopLevel + 1 ; #DEBUG_LINE_NO:280
  ObjectReference[] vendorContainers = new ObjectReference[containerArraySize] ; #DEBUG_LINE_NO:281
  FormList vendorContainerList = WorkshopParent.WorkshopVendorContainers[vendorType] ; #DEBUG_LINE_NO:284
  Int vendorLevel = 0 ; #DEBUG_LINE_NO:285
  While vendorLevel <= WorkshopParent.VendorTopLevel ; #DEBUG_LINE_NO:286
    vendorContainers[vendorLevel] = WorkshopParent.WorkshopHoldingCellMarker.PlaceAtMe(vendorContainerList.GetAt(vendorLevel), 1, False, False, True) ; #DEBUG_LINE_NO:289
    vendorLevel += 1 ; #DEBUG_LINE_NO:291
  EndWhile
  Return vendorContainers ; #DEBUG_LINE_NO:294
EndFunction

Event OnInit()
  If MaxTriangles > 0 ; #DEBUG_LINE_NO:299
    Self.SetValue(WorkshopParent.WorkshopMaxTriangles, MaxTriangles as Float) ; #DEBUG_LINE_NO:300
  EndIf
  If MaxDraws > 0 ; #DEBUG_LINE_NO:302
    Self.SetValue(WorkshopParent.WorkshopMaxDraws, MaxDraws as Float) ; #DEBUG_LINE_NO:303
  EndIf
  If CurrentTriangles > 0 ; #DEBUG_LINE_NO:305
    Self.SetValue(WorkshopParent.WorkshopCurrentTriangles, CurrentTriangles as Float) ; #DEBUG_LINE_NO:306
  EndIf
  If CurrentDraws > 0 ; #DEBUG_LINE_NO:308
    Self.SetValue(WorkshopParent.WorkshopCurrentDraws, CurrentDraws as Float) ; #DEBUG_LINE_NO:309
  EndIf
  Self.SetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, WorkshopParent.startingHappinessTarget) ; #DEBUG_LINE_NO:313
EndEvent

Event OnLoad()
  Self.BlockActivation(!OwnedByPlayer, False) ; #DEBUG_LINE_NO:318
  If Self.GetBaseObject() as Container ; #DEBUG_LINE_NO:320
    ObjectReference linkedContainer = Self.GetLinkedRef(WorkshopParent.WorkshopLinkContainer) ; #DEBUG_LINE_NO:322
    If linkedContainer ; #DEBUG_LINE_NO:323
      linkedContainer.RemoveAllItems(Self as ObjectReference, False) ; #DEBUG_LINE_NO:324
    EndIf
    ObjectReference[] linkedContainers = Self.GetLinkedRefChildren(WorkshopParent.WorkshopLinkContainer) ; #DEBUG_LINE_NO:328
    Int I = 0 ; #DEBUG_LINE_NO:329
    While I < linkedContainers.Length ; #DEBUG_LINE_NO:330
      linkedContainer = linkedContainers[I] ; #DEBUG_LINE_NO:331
      If linkedContainer ; #DEBUG_LINE_NO:332
        linkedContainer.RemoveAllItems(Self as ObjectReference, False) ; #DEBUG_LINE_NO:333
      EndIf
      I += 1 ; #DEBUG_LINE_NO:335
    EndWhile
  EndIf
  If !myLocation ; #DEBUG_LINE_NO:340
    myLocation = Self.GetCurrentLocation() ; #DEBUG_LINE_NO:341
  EndIf
EndEvent

Event OnUnload()
  DaysSinceLastVisit = 0 ; #DEBUG_LINE_NO:347
EndEvent

Event OnActivate(ObjectReference akActionRef)
  If akActionRef == Game.GetPlayer() as ObjectReference ; #DEBUG_LINE_NO:353
    Self.CheckOwnership() ; #DEBUG_LINE_NO:354
    If OwnedByPlayer ; #DEBUG_LINE_NO:356
      Self.StartWorkshop(True) ; #DEBUG_LINE_NO:358
    EndIf
  EndIf
EndEvent

Function CheckOwnership()
  If myLocation.IsCleared() && !OwnedByPlayer && EnableAutomaticPlayerOwnership && !WorkshopParent.PermanentActorsAliveAndPresent(Self) ; #DEBUG_LINE_NO:366
    Self.SetOwnedByPlayer(True) ; #DEBUG_LINE_NO:367
  EndIf
  If !OwnedByPlayer ; #DEBUG_LINE_NO:372
    If CustomUnownedMessage ; #DEBUG_LINE_NO:375
      CustomUnownedMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:376
    Else
      Int totalPopulation = Self.GetBaseValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as Int ; #DEBUG_LINE_NO:378
      If totalPopulation > 0 ; #DEBUG_LINE_NO:380
        WorkshopParent.WorkshopUnownedSettlementMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:381
      ElseIf myLocation.IsCleared() == False && EnableAutomaticPlayerOwnership ; #DEBUG_LINE_NO:382
        WorkshopParent.WorkshopUnownedHostileMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:383
      Else
        WorkshopParent.WorkshopUnownedMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:385
      EndIf
    EndIf
  EndIf
EndFunction

Event OnWorkshopMode(Bool aStart)
  If aStart ; #DEBUG_LINE_NO:393
    If OwnedByPlayer ; #DEBUG_LINE_NO:394
      WorkshopParent.SetCurrentWorkshop(Self) ; #DEBUG_LINE_NO:396
    EndIf
    Var[] kargs = new Var[2] ; #DEBUG_LINE_NO:399
    kargs[0] = None ; #DEBUG_LINE_NO:400
    kargs[1] = Self as Var ; #DEBUG_LINE_NO:401
    WorkshopParent.SendCustomEvent("workshopparentscript_WorkshopEnterMenu", kargs) ; #DEBUG_LINE_NO:403
  EndIf
  If aStart && WorkshopParent.DogmeatAlias.GetRef() as Bool ; #DEBUG_LINE_NO:407
    WorkshopParent.WorkshopDogmeatWhileBuildingScene.Start() ; #DEBUG_LINE_NO:408
  Else
    WorkshopParent.WorkshopDogmeatWhileBuildingScene.Stop() ; #DEBUG_LINE_NO:410
  EndIf
  If aStart && WorkshopParent.CompanionAlias.GetRef() as Bool ; #DEBUG_LINE_NO:415
    WorkshopParent.WorkshopCompanionWhileBuildingScene.Start() ; #DEBUG_LINE_NO:417
  Else
    WorkshopParent.WorkshopCompanionWhileBuildingScene.Stop() ; #DEBUG_LINE_NO:419
  EndIf
  If !aStart ; #DEBUG_LINE_NO:422
    If ShowedWorkshopMenuExitMessage == False ; #DEBUG_LINE_NO:424
      ShowedWorkshopMenuExitMessage = True ; #DEBUG_LINE_NO:425
      WorkshopParent.WorkshopExitMenuMessage.ShowAsHelpMessage("WorkshopMenuExit", 10.0, 0.0, 1, "NoMenu", 0) ; #DEBUG_LINE_NO:426
    EndIf
    WorkshopParent.TryToAssignResourceObjectsPUBLIC(Self) ; #DEBUG_LINE_NO:429
  EndIf
  Self.DailyUpdate(False) ; #DEBUG_LINE_NO:433
EndEvent

Event OnTimer(Int aiTimerID)
  If aiTimerID == buildWorkObjectTimerID ; #DEBUG_LINE_NO:438
    WorkshopParent.TryToAssignResourceObjectsPUBLIC(Self) ; #DEBUG_LINE_NO:439
  EndIf
EndEvent

Event OnTimerGameTime(Int aiTimerID)
  If aiTimerID == dailyUpdateTimerID ; #DEBUG_LINE_NO:444
    If WorkshopParent.IsEditLocked() || WorkshopParent.DailyUpdateInProgress ; #DEBUG_LINE_NO:445
      Float waitTime = Utility.RandomFloat(minDailyUpdateWaitHours, maxDailyUpdateWaitHours) ; #DEBUG_LINE_NO:446
      Self.StartTimerGameTime(waitTime, dailyUpdateTimerID) ; #DEBUG_LINE_NO:449
    Else
      Self.DailyUpdate(True) ; #DEBUG_LINE_NO:451
    EndIf
  EndIf
EndEvent

Function SetOwnedByPlayer(Bool bIsOwned)
  If !bIsOwned && OwnedByPlayer ; #DEBUG_LINE_NO:460
    OwnedByPlayer = bIsOwned ; #DEBUG_LINE_NO:462
    WorkshopParent.DisplayMessage(WorkshopParent.WorkshopLosePlayerOwnership, None, myLocation) ; #DEBUG_LINE_NO:465
    Self.SetValue(WorkshopParent.WorkshopPlayerLostControl, 1.0) ; #DEBUG_LINE_NO:467
    ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(Self) ; #DEBUG_LINE_NO:469
    Int I = 0 ; #DEBUG_LINE_NO:470
    While I < WorkshopActors.Length ; #DEBUG_LINE_NO:471
      workshopnpcscript theActor = (WorkshopActors[I] as Actor) as workshopnpcscript ; #DEBUG_LINE_NO:472
      If theActor ; #DEBUG_LINE_NO:473
        theActor.RemoveFromFaction(WorkshopParent.FarmDiscountFaction) ; #DEBUG_LINE_NO:474
        theActor.UpdatePlayerOwnership(Self) ; #DEBUG_LINE_NO:476
      EndIf
      I += 1 ; #DEBUG_LINE_NO:478
    EndWhile
    WorkshopParent.ClearCaravansFromWorkshopPUBLIC(Self) ; #DEBUG_LINE_NO:482
  ElseIf bIsOwned && !OwnedByPlayer ; #DEBUG_LINE_NO:484
    OwnedByPlayer = bIsOwned ; #DEBUG_LINE_NO:486
    If !WorkshopParent.PlayerOwnsAWorkshop ; #DEBUG_LINE_NO:489
      WorkshopParent.PlayerOwnsAWorkshop = True ; #DEBUG_LINE_NO:490
    EndIf
    Float currentHappiness = Self.GetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappiness].resourceValue) ; #DEBUG_LINE_NO:494
    Float currentHappinessTarget = Self.GetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue) ; #DEBUG_LINE_NO:495
    If (currentHappiness < minHappinessClearWarningThreshold as Float) || (currentHappinessTarget < minHappinessClearWarningThreshold as Float) ; #DEBUG_LINE_NO:496
      WorkshopParent.ModifyResourceData(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappiness].resourceValue, Self, minHappinessClearWarningThreshold as Float) ; #DEBUG_LINE_NO:497
      WorkshopParent.ModifyResourceData(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, Self, minHappinessClearWarningThreshold as Float) ; #DEBUG_LINE_NO:498
    EndIf
    WorkshopParent.DisplayMessage(WorkshopParent.WorkshopGainPlayerOwnership, None, myLocation) ; #DEBUG_LINE_NO:503
    If Self.GetValue(WorkshopParent.WorkshopPlayerLostControl) == 0.0 ; #DEBUG_LINE_NO:506
      Game.IncrementStat("Workshops Unlocked", 1) ; #DEBUG_LINE_NO:508
    Else
      Self.SetValue(WorkshopParent.WorkshopPlayerLostControl, 0.0) ; #DEBUG_LINE_NO:511
    EndIf
    If MinRecruitmentAllowRandomAfterPlayerOwned ; #DEBUG_LINE_NO:515
      MinRecruitmentProhibitRandom = False ; #DEBUG_LINE_NO:516
    EndIf
    AllowAttacksBeforeOwned = True ; #DEBUG_LINE_NO:520
    ObjectReference[] workshopactors = WorkshopParent.GetWorkshopActors(Self) ; #DEBUG_LINE_NO:523
    Int i = 0 ; #DEBUG_LINE_NO:524
    While i < workshopactors.Length ; #DEBUG_LINE_NO:525
      workshopnpcscript theactor = (workshopactors[i] as Actor) as workshopnpcscript ; #DEBUG_LINE_NO:526
      If theactor ; #DEBUG_LINE_NO:527
        theactor.UpdatePlayerOwnership(Self) ; #DEBUG_LINE_NO:528
      EndIf
      i += 1 ; #DEBUG_LINE_NO:530
    EndWhile
  EndIf
  OwnedByPlayer = bIsOwned ; #DEBUG_LINE_NO:535
  Self.BlockActivation(!OwnedByPlayer, False) ; #DEBUG_LINE_NO:536
  Self.SetValue(WorkshopParent.WorkshopPlayerOwnership, bIsOwned as Float) ; #DEBUG_LINE_NO:538
  If bIsOwned ; #DEBUG_LINE_NO:541
    Self.SetActorOwner(Game.GetPlayer().GetActorBase(), False) ; #DEBUG_LINE_NO:542
    myLocation.SetCleared(False) ; #DEBUG_LINE_NO:544
    If SettlementOwnershipFaction as Bool && UseOwnershipFaction ; #DEBUG_LINE_NO:546
      Game.GetPlayer().AddToFaction(SettlementOwnershipFaction) ; #DEBUG_LINE_NO:547
    EndIf
  Else
    Self.SetActorOwner(None, False) ; #DEBUG_LINE_NO:550
    If SettlementOwnershipFaction as Bool && UseOwnershipFaction ; #DEBUG_LINE_NO:552
      Game.GetPlayer().RemoveFromFaction(SettlementOwnershipFaction) ; #DEBUG_LINE_NO:553
    EndIf
  EndIf
  WorkshopParent.SendPlayerOwnershipChangedEvent(Self) ; #DEBUG_LINE_NO:558
EndFunction

Event OnWorkshopObjectPlaced(ObjectReference akReference)
  If WorkshopParent.BuildObjectPUBLIC(akReference, Self) ; #DEBUG_LINE_NO:563
    Self.StartTimer(3.0, buildWorkObjectTimerID) ; #DEBUG_LINE_NO:565
  EndIf
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
  workshopobjectscript workshopObjectRef = akReference as workshopobjectscript ; #DEBUG_LINE_NO:572
  If workshopObjectRef ; #DEBUG_LINE_NO:574
    Var[] kargs = new Var[2] ; #DEBUG_LINE_NO:577
    kargs[0] = workshopObjectRef as Var ; #DEBUG_LINE_NO:578
    kargs[1] = Self as Var ; #DEBUG_LINE_NO:579
    WorkshopParent.SendCustomEvent("workshopparentscript_WorkshopObjectMoved", kargs) ; #DEBUG_LINE_NO:581
  EndIf
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
  WorkshopParent.RemoveObjectPUBLIC(akReference, Self) ; #DEBUG_LINE_NO:587
EndEvent

Event OnWorkshopObjectRepaired(ObjectReference akReference)
  workshopobjectactorscript workshopObjectActor = akReference as workshopobjectactorscript ; #DEBUG_LINE_NO:592
  If workshopObjectActor ; #DEBUG_LINE_NO:593
    workshopobjectscript workshopObject = akReference as workshopobjectscript ; #DEBUG_LINE_NO:596
    workshopObject.OnDestructionStageChanged(1, 0) ; #DEBUG_LINE_NO:597
  EndIf
  workshopobjectscript workshopObjectRef = akReference as workshopobjectscript ; #DEBUG_LINE_NO:600
  If workshopObjectRef ; #DEBUG_LINE_NO:602
    Var[] kargs = new Var[2] ; #DEBUG_LINE_NO:605
    kargs[0] = workshopObjectRef as Var ; #DEBUG_LINE_NO:606
    kargs[1] = Self as Var ; #DEBUG_LINE_NO:607
    WorkshopParent.SendCustomEvent("workshopparentscript_WorkshopObjectRepaired", kargs) ; #DEBUG_LINE_NO:609
  EndIf
EndEvent

ObjectReference Function GetContainer()
  If Self.GetBaseObject() as Container ; #DEBUG_LINE_NO:615
    Return Self as ObjectReference ; #DEBUG_LINE_NO:616
  Else
    Return Self.GetLinkedRef(WorkshopParent.WorkshopLinkContainer) ; #DEBUG_LINE_NO:618
  EndIf
EndFunction

Event WorkshopParentScript.WorkshopDailyUpdate(workshopparentscript akSender, Var[] akArgs)
  Float waitTime = WorkshopParent.dailyUpdateIncrement * WorkshopID as Float ; #DEBUG_LINE_NO:624
  Self.StartTimerGameTime(waitTime, dailyUpdateTimerID) ; #DEBUG_LINE_NO:626
EndEvent

Int Function GetMaxWorkshopNPCs()
  Int iMaxNPCs = iBaseMaxNPCs + Game.GetPlayer().GetValue(WorkshopParent.Charisma) as Int ; #DEBUG_LINE_NO:632
  Return iMaxNPCs ; #DEBUG_LINE_NO:633
EndFunction

Function DailyUpdate(Bool bRealUpdate)
  If bDailyUpdateInProgress ; #DEBUG_LINE_NO:672
    If bRealUpdate ; #DEBUG_LINE_NO:673
      While bDailyUpdateInProgress
        Utility.wait(0.5) ; #DEBUG_LINE_NO:676
      EndWhile
    Else
      Return  ; #DEBUG_LINE_NO:681
    EndIf
  EndIf
  bDailyUpdateInProgress = True ; #DEBUG_LINE_NO:684
  WorkshopParent.DailyUpdateInProgress = True ; #DEBUG_LINE_NO:685
  workshopdatascript:workshopratingkeyword[] ratings = WorkshopParent.WorkshopRatings ; #DEBUG_LINE_NO:688
  workshopscript:dailyupdatedata updateData = new workshopscript:dailyupdatedata ; #DEBUG_LINE_NO:689
  updateData.totalPopulation = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as Int ; #DEBUG_LINE_NO:692
  updateData.robotPopulation = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulationRobots].resourceValue) as Int ; #DEBUG_LINE_NO:693
  updateData.brahminPopulation = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingBrahmin].resourceValue) as Int ; #DEBUG_LINE_NO:694
  updateData.unassignedPopulation = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulationUnassigned].resourceValue) as Int ; #DEBUG_LINE_NO:695
  updateData.vendorIncome = Self.GetValue(ratings[WorkshopParent.WorkshopRatingVendorIncome].resourceValue) * vendorIncomeBaseMult ; #DEBUG_LINE_NO:697
  updateData.currentHappiness = Self.GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue) ; #DEBUG_LINE_NO:698
  updateData.damageMult = 1.0 - Self.GetValue(ratings[WorkshopParent.WorkshopRatingDamageCurrent].resourceValue) / 100.0 ; #DEBUG_LINE_NO:700
  updateData.productivity = Self.GetProductivityMultiplier(ratings) ; #DEBUG_LINE_NO:701
  updateData.availableBeds = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingBeds].resourceValue) as Int ; #DEBUG_LINE_NO:702
  updateData.shelteredBeds = Self.GetValue(ratings[WorkshopParent.WorkshopRatingBeds].resourceValue) as Int ; #DEBUG_LINE_NO:703
  updateData.bonusHappiness = Self.GetValue(ratings[WorkshopParent.WorkshopRatingBonusHappiness].resourceValue) as Int ; #DEBUG_LINE_NO:704
  updateData.happinessModifier = Self.GetValue(ratings[WorkshopParent.WorkshopRatingHappinessModifier].resourceValue) as Int ; #DEBUG_LINE_NO:705
  updateData.safety = Self.GetValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue) as Int ; #DEBUG_LINE_NO:706
  updateData.safetyDamage = Self.GetValue(WorkshopParent.GetDamageRatingValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue)) as Int ; #DEBUG_LINE_NO:707
  updateData.totalHappiness = 0.0 ; #DEBUG_LINE_NO:708
  If bRealUpdate ; #DEBUG_LINE_NO:713
    Self.DailyUpdateAttractNewSettlers(ratings, updateData) ; #DEBUG_LINE_NO:714
  EndIf
  ObjectReference containerRef = Self.GetContainer() ; #DEBUG_LINE_NO:717
  If !containerRef ; #DEBUG_LINE_NO:718
    bDailyUpdateInProgress = False ; #DEBUG_LINE_NO:720
    WorkshopParent.DailyUpdateInProgress = False ; #DEBUG_LINE_NO:721
    Return  ; #DEBUG_LINE_NO:722
  EndIf
  If Self.GetWorkshopID() as Float == WorkshopParent.WorkshopCurrentWorkshopID.GetValue() ; #DEBUG_LINE_NO:728
    ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(Self) ; #DEBUG_LINE_NO:731
    Int I = 0 ; #DEBUG_LINE_NO:732
    While I < WorkshopActors.Length ; #DEBUG_LINE_NO:733
      WorkshopParent.UpdateActorsWorkObjects(WorkshopActors[I] as workshopnpcscript, Self, False) ; #DEBUG_LINE_NO:734
      I += 1 ; #DEBUG_LINE_NO:735
    EndWhile
  EndIf
  Self.DailyUpdateProduceResources(ratings, updateData, containerRef, bRealUpdate) ; #DEBUG_LINE_NO:739
  Self.DailyUpdateConsumeResources(ratings, updateData, containerRef, bRealUpdate) ; #DEBUG_LINE_NO:741
  If bRealUpdate ; #DEBUG_LINE_NO:745
    Self.DailyUpdateSurplusResources(ratings, updateData, containerRef) ; #DEBUG_LINE_NO:746
    Self.RepairDamage() ; #DEBUG_LINE_NO:748
    Self.RecalculateWorkshopResources(True) ; #DEBUG_LINE_NO:751
    Self.CheckForAttack(False) ; #DEBUG_LINE_NO:753
  EndIf
  If updateData.totalPopulation >= WorkshopParent.TradeCaravanMinimumPopulation && Self.GetValue(ratings[WorkshopParent.WorkshopRatingCaravan].resourceValue) > 0.0 ; #DEBUG_LINE_NO:757
    WorkshopParent.TradeCaravanWorkshops.AddRef(Self as ObjectReference) ; #DEBUG_LINE_NO:758
  Else
    WorkshopParent.TradeCaravanWorkshops.RemoveRef(Self as ObjectReference) ; #DEBUG_LINE_NO:760
  EndIf
  bDailyUpdateInProgress = False ; #DEBUG_LINE_NO:768
  WorkshopParent.DailyUpdateInProgress = False ; #DEBUG_LINE_NO:769
EndFunction

Function DailyUpdateAttractNewSettlers(workshopdatascript:workshopratingkeyword[] ratings, workshopscript:dailyupdatedata updateData)
  DaysSinceLastVisit += 1 ; #DEBUG_LINE_NO:778
  Int radioRating = Self.GetValue(ratings[WorkshopParent.WorkshopRatingRadio].resourceValue) as Int ; #DEBUG_LINE_NO:782
  If radioRating > 0 && Self.HasKeyword(WorkshopParent.WorkshopType02) == False && updateData.unassignedPopulation < iMaxSurplusNPCs && updateData.totalPopulation < Self.GetMaxWorkshopNPCs() ; #DEBUG_LINE_NO:783
    Float attractChance = attractNPCDailyChance + updateData.currentHappiness / 100.0 * attractNPCHappinessMult ; #DEBUG_LINE_NO:785
    If updateData.totalPopulation < iMaxBonusAttractChancePopulation ; #DEBUG_LINE_NO:786
      attractChance += (iMaxBonusAttractChancePopulation - updateData.totalPopulation) as Float * attractNPCDailyChance ; #DEBUG_LINE_NO:787
    EndIf
    Float dieRoll = Utility.RandomFloat(0.0, 1.0) ; #DEBUG_LINE_NO:790
    If dieRoll <= attractChance ; #DEBUG_LINE_NO:793
      workshopnpcscript newWorkshopActor = WorkshopParent.CreateActor(Self, False, None, False) ; #DEBUG_LINE_NO:794
      updateData.totalPopulation = updateData.totalPopulation + 1 ; #DEBUG_LINE_NO:795
      If newWorkshopActor.GetValue(WorkshopParent.WorkshopGuardPreference) == 0.0 ; #DEBUG_LINE_NO:797
        If Self.GetValue(ratings[WorkshopParent.WorkshopRatingBrahmin].resourceValue) == 0.0 && AllowBrahminRecruitment ; #DEBUG_LINE_NO:800
          Int brahminRoll = Utility.RandomInt(0, 100) ; #DEBUG_LINE_NO:801
          If brahminRoll <= WorkshopParent.recruitmentBrahminChance ; #DEBUG_LINE_NO:803
            Actor newBrahmin = WorkshopParent.CreateActor(Self, True, None, False) as Actor ; #DEBUG_LINE_NO:804
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf
EndFunction

Function DailyUpdateProduceResources(workshopdatascript:workshopratingkeyword[] ratings, workshopscript:dailyupdatedata updateData, ObjectReference containerRef, Bool bRealUpdate)
  updateData.foodProduction = Self.GetValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue) as Int ; #DEBUG_LINE_NO:821
  updateData.waterProduction = Self.GetValue(ratings[WorkshopParent.WorkshopRatingWater].resourceValue) as Int ; #DEBUG_LINE_NO:822
  Int missingSafety = Math.max(0.0, (updateData.totalPopulation - updateData.safety) as Float) as Int ; #DEBUG_LINE_NO:827
  WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingSafety].resourceValue, Self, missingSafety as Float) ; #DEBUG_LINE_NO:828
  updateData.foodProduction = Math.max(0.0, (updateData.foodProduction - Self.GetValue(WorkshopParent.GetDamageRatingValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue)) as Int) as Float) as Int ; #DEBUG_LINE_NO:831
  updateData.waterProduction = Math.max(0.0, (updateData.waterProduction - Self.GetValue(WorkshopParent.GetDamageRatingValue(ratings[WorkshopParent.WorkshopRatingWater].resourceValue)) as Int) as Float) as Int ; #DEBUG_LINE_NO:832
  If updateData.brahminPopulation > 0 ; #DEBUG_LINE_NO:835
    Int brahminMaxFoodBoost = Math.min((updateData.brahminPopulation * maxProductionPerBrahmin) as Float, updateData.foodProduction as Float) as Int ; #DEBUG_LINE_NO:836
    Int brahminFoodProduction = Math.Ceiling(brahminMaxFoodBoost as Float * brahminProductionBoost) ; #DEBUG_LINE_NO:837
    updateData.foodProduction = updateData.foodProduction + brahminFoodProduction ; #DEBUG_LINE_NO:839
  EndIf
  WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingFoodActual].resourceValue, Self, updateData.foodProduction as Float) ; #DEBUG_LINE_NO:851
  updateData.safety = Math.max((updateData.safety - updateData.safetyDamage) as Float, 0.0) as Int ; #DEBUG_LINE_NO:863
  updateData.safetyPerNPC = 0 ; #DEBUG_LINE_NO:864
  If updateData.totalPopulation > 0 ; #DEBUG_LINE_NO:865
    updateData.safetyPerNPC = Math.Ceiling((updateData.safety / updateData.totalPopulation) as Float) ; #DEBUG_LINE_NO:866
  EndIf
  updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood as Form) ; #DEBUG_LINE_NO:869
  updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater as Form) ; #DEBUG_LINE_NO:870
  updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood as Form) + updateData.foodProduction ; #DEBUG_LINE_NO:883
  updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater as Form) + updateData.waterProduction ; #DEBUG_LINE_NO:884
  Int neededFood = updateData.totalPopulation - updateData.robotPopulation - updateData.availableFood ; #DEBUG_LINE_NO:891
  Int neededWater = updateData.totalPopulation - updateData.robotPopulation - updateData.availableWater ; #DEBUG_LINE_NO:892
  If neededFood > 0 || neededWater > 0 ; #DEBUG_LINE_NO:895
    WorkshopParent.TransferResourcesFromLinkedWorkshops(Self, neededFood, neededWater) ; #DEBUG_LINE_NO:899
  EndIf
  updateData.availableFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood as Form) + updateData.foodProduction ; #DEBUG_LINE_NO:903
  updateData.availableWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater as Form) + updateData.waterProduction ; #DEBUG_LINE_NO:904
EndFunction

Function DailyUpdateConsumeResources(workshopdatascript:workshopratingkeyword[] ratings, workshopscript:dailyupdatedata updateData, ObjectReference containerRef, Bool bRealUpdate)
  If updateData.totalPopulation == 0 ; #DEBUG_LINE_NO:940
    Return  ; #DEBUG_LINE_NO:941
  EndIf
  Float ActorHappiness = 0.0 ; #DEBUG_LINE_NO:945
  Bool ActorBed = False ; #DEBUG_LINE_NO:946
  Bool ActorShelter = False ; #DEBUG_LINE_NO:947
  Bool ActorFood = False ; #DEBUG_LINE_NO:948
  Bool ActorWater = False ; #DEBUG_LINE_NO:949
  Int missingFood = 0 ; #DEBUG_LINE_NO:952
  Int missingWater = 0 ; #DEBUG_LINE_NO:953
  Int missingBeds = 0 ; #DEBUG_LINE_NO:954
  Int missingShelter = 0 ; #DEBUG_LINE_NO:955
  Int missingSafety = 0 ; #DEBUG_LINE_NO:956
  Int I = 0 ; #DEBUG_LINE_NO:959
  While I < updateData.totalPopulation - updateData.robotPopulation ; #DEBUG_LINE_NO:960
    ActorHappiness = 0.0 ; #DEBUG_LINE_NO:963
    ActorFood = False ; #DEBUG_LINE_NO:964
    ActorWater = False ; #DEBUG_LINE_NO:965
    ActorBed = False ; #DEBUG_LINE_NO:966
    ActorShelter = False ; #DEBUG_LINE_NO:967
    If updateData.availableFood > 0 ; #DEBUG_LINE_NO:972
      ActorFood = True ; #DEBUG_LINE_NO:974
      updateData.availableFood = updateData.availableFood - 1 ; #DEBUG_LINE_NO:975
      If updateData.foodProduction > 0 ; #DEBUG_LINE_NO:977
        updateData.foodProduction = updateData.foodProduction - 1 ; #DEBUG_LINE_NO:978
      ElseIf bRealUpdate
        containerRef.RemoveItem(WorkshopParent.WorkshopConsumeFood as Form, 1, False, None) ; #DEBUG_LINE_NO:980
      EndIf
      ActorHappiness += happinessBonusFood ; #DEBUG_LINE_NO:982
    Else
      missingFood += 1 ; #DEBUG_LINE_NO:985
    EndIf
    If updateData.availableWater > 0 ; #DEBUG_LINE_NO:989
      ActorWater = True ; #DEBUG_LINE_NO:991
      updateData.availableWater = updateData.availableWater - 1 ; #DEBUG_LINE_NO:992
      If updateData.waterProduction > 0 ; #DEBUG_LINE_NO:994
        updateData.waterProduction = updateData.waterProduction - 1 ; #DEBUG_LINE_NO:995
      ElseIf bRealUpdate
        containerRef.RemoveItem(WorkshopParent.WorkshopConsumeWater as Form, 1, False, None) ; #DEBUG_LINE_NO:997
      EndIf
      ActorHappiness += happinessBonusWater ; #DEBUG_LINE_NO:999
    Else
      missingWater += 1 ; #DEBUG_LINE_NO:1002
    EndIf
    If updateData.availableBeds > 0 ; #DEBUG_LINE_NO:1007
      ActorBed = True ; #DEBUG_LINE_NO:1008
      updateData.availableBeds = updateData.availableBeds - 1 ; #DEBUG_LINE_NO:1009
      ActorHappiness += happinessBonusBed ; #DEBUG_LINE_NO:1010
    Else
      missingBeds += 1 ; #DEBUG_LINE_NO:1013
    EndIf
    If updateData.shelteredBeds > 0 ; #DEBUG_LINE_NO:1017
      ActorShelter = True ; #DEBUG_LINE_NO:1018
      updateData.shelteredBeds = updateData.shelteredBeds - 1 ; #DEBUG_LINE_NO:1019
      ActorHappiness += happinessBonusShelter ; #DEBUG_LINE_NO:1020
    EndIf
    If updateData.safetyPerNPC > 0 ; #DEBUG_LINE_NO:1025
      ActorHappiness += happinessBonusSafety ; #DEBUG_LINE_NO:1026
    EndIf
    ActorHappiness = Self.CheckActorHappiness(ActorHappiness, ActorFood, ActorWater, ActorBed, ActorShelter) ; #DEBUG_LINE_NO:1030
    updateData.totalHappiness = updateData.totalHappiness + ActorHappiness ; #DEBUG_LINE_NO:1034
    I += 1 ; #DEBUG_LINE_NO:1035
  EndWhile
  updateData.totalHappiness = updateData.totalHappiness + (50 * updateData.robotPopulation) as Float ; #DEBUG_LINE_NO:1039
  WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingBeds].resourceValue, Self, missingBeds as Float) ; #DEBUG_LINE_NO:1042
  If bRealUpdate ; #DEBUG_LINE_NO:1046
    WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingFood].resourceValue, Self, missingFood as Float) ; #DEBUG_LINE_NO:1047
    WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingMissingWater].resourceValue, Self, missingWater as Float) ; #DEBUG_LINE_NO:1048
  EndIf
  updateData.totalHappiness = updateData.totalHappiness + updateData.bonusHappiness as Float ; #DEBUG_LINE_NO:1052
  updateData.totalHappiness = Math.max((updateData.totalHappiness / updateData.totalPopulation as Float) + updateData.happinessModifier as Float, 0.0) ; #DEBUG_LINE_NO:1057
  updateData.totalHappiness = Math.min(updateData.totalHappiness, 100.0) ; #DEBUG_LINE_NO:1059
  WorkshopParent.SetResourceData(ratings[WorkshopParent.WorkshopRatingHappinessTarget].resourceValue, Self, updateData.totalHappiness) ; #DEBUG_LINE_NO:1063
  If bRealUpdate ; #DEBUG_LINE_NO:1066
    Float deltaHappinessFloat = (updateData.totalHappiness - updateData.currentHappiness) * happinessChangeMult ; #DEBUG_LINE_NO:1067
    Int deltaHappiness = 0 ; #DEBUG_LINE_NO:1070
    If deltaHappinessFloat < 0.0 ; #DEBUG_LINE_NO:1071
      deltaHappiness = Math.floor(deltaHappinessFloat) ; #DEBUG_LINE_NO:1072
    Else
      deltaHappiness = Math.Ceiling(deltaHappinessFloat) ; #DEBUG_LINE_NO:1074
    EndIf
    If deltaHappiness != 0 && (Math.abs(deltaHappiness as Float) < minHappinessChangePerUpdate as Float) ; #DEBUG_LINE_NO:1078
      deltaHappiness = minHappinessChangePerUpdate * (deltaHappiness as Float / Math.abs(deltaHappiness as Float)) as Int ; #DEBUG_LINE_NO:1080
    EndIf
    WorkshopParent.ModifyResourceData(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue, Self, deltaHappiness as Float) ; #DEBUG_LINE_NO:1085
    Float finalHappiness = Self.GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue) ; #DEBUG_LINE_NO:1089
    If finalHappiness >= WorkshopParent.HappinessAchievementValue as Float ; #DEBUG_LINE_NO:1093
      Game.AddAchievement(WorkshopParent.HappinessAchievementID) ; #DEBUG_LINE_NO:1095
    EndIf
    If OwnedByPlayer && AllowUnownedFromLowHappiness ; #DEBUG_LINE_NO:1099
      If (finalHappiness <= minHappinessWarningThreshold as Float) && HappinessWarning == False ; #DEBUG_LINE_NO:1101
        HappinessWarning = True ; #DEBUG_LINE_NO:1102
        WorkshopParent.DisplayMessage(WorkshopParent.WorkshopUnhappinessWarning, None, myLocation) ; #DEBUG_LINE_NO:1104
      ElseIf finalHappiness <= minHappinessThreshold as Float ; #DEBUG_LINE_NO:1105
        Self.SetOwnedByPlayer(False) ; #DEBUG_LINE_NO:1106
      EndIf
      If (finalHappiness > minHappinessClearWarningThreshold as Float) && HappinessWarning == True ; #DEBUG_LINE_NO:1110
        HappinessWarning = False ; #DEBUG_LINE_NO:1111
      EndIf
    EndIf
    If updateData.happinessModifier != 0 ; #DEBUG_LINE_NO:1116
      Float modifierSign = -1.0 * (updateData.happinessModifier as Float / Math.abs(updateData.happinessModifier as Float)) ; #DEBUG_LINE_NO:1117
      Int deltaHappinessModifier = 0 ; #DEBUG_LINE_NO:1119
      Float deltaHappinessModifierFloat = Math.abs(updateData.happinessModifier as Float) * modifierSign * happinessChangeMult ; #DEBUG_LINE_NO:1120
      If deltaHappinessModifierFloat > 0.0 ; #DEBUG_LINE_NO:1122
        deltaHappinessModifier = Math.floor(deltaHappinessModifierFloat) ; #DEBUG_LINE_NO:1123
      Else
        deltaHappinessModifier = Math.Ceiling(deltaHappinessModifierFloat) ; #DEBUG_LINE_NO:1125
      EndIf
      If Math.abs(deltaHappinessModifier as Float) < happinessBonusChangePerUpdate as Float ; #DEBUG_LINE_NO:1129
        deltaHappinessModifier = (modifierSign * happinessBonusChangePerUpdate as Float) as Int ; #DEBUG_LINE_NO:1130
      EndIf
      If deltaHappinessModifier as Float > Math.abs(updateData.happinessModifier as Float) ; #DEBUG_LINE_NO:1134
        WorkshopParent.SetHappinessModifier(Self, 0.0) ; #DEBUG_LINE_NO:1135
      Else
        WorkshopParent.ModifyHappinessModifier(Self, deltaHappinessModifier as Float) ; #DEBUG_LINE_NO:1137
      EndIf
    EndIf
  EndIf
EndFunction

Function DailyUpdateSurplusResources(workshopdatascript:workshopratingkeyword[] ratings, workshopscript:dailyupdatedata updateData, ObjectReference containerRef)
  Int currentStoredFood = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeFood as Form) ; #DEBUG_LINE_NO:1151
  Int currentStoredWater = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeWater as Form) ; #DEBUG_LINE_NO:1152
  Int currentStoredScavenge = containerRef.GetItemCount(WorkshopParent.WorkshopConsumeScavenge as Form) ; #DEBUG_LINE_NO:1153
  Int currentStoredFertilizer = containerRef.GetItemCount(WorkshopParent.WorkshopProduceFertilizer as Form) ; #DEBUG_LINE_NO:1154
  Bool bAllowFoodProduction = True ; #DEBUG_LINE_NO:1158
  If currentStoredFood > maxStoredFoodBase + maxStoredFoodPerPopulation * updateData.totalPopulation ; #DEBUG_LINE_NO:1159
    bAllowFoodProduction = False ; #DEBUG_LINE_NO:1160
  EndIf
  Bool bAllowWaterProduction = True ; #DEBUG_LINE_NO:1163
  If currentStoredWater > maxStoredWaterBase + Math.floor(maxStoredWaterPerPopulation * updateData.totalPopulation as Float) ; #DEBUG_LINE_NO:1164
    bAllowWaterProduction = False ; #DEBUG_LINE_NO:1165
  EndIf
  Bool bAllowScavengeProduction = True ; #DEBUG_LINE_NO:1168
  If currentStoredScavenge > maxStoredScavengeBase + maxStoredScavengePerPopulation * updateData.totalPopulation ; #DEBUG_LINE_NO:1169
    bAllowScavengeProduction = False ; #DEBUG_LINE_NO:1170
  EndIf
  Bool bAllowFertilizerProduction = True ; #DEBUG_LINE_NO:1173
  If currentStoredFertilizer > maxStoredFertilizerBase ; #DEBUG_LINE_NO:1174
    bAllowFertilizerProduction = False ; #DEBUG_LINE_NO:1175
  EndIf
  If updateData.foodProduction > 0 && bAllowFoodProduction ; #DEBUG_LINE_NO:1182
    updateData.foodProduction = Math.floor(updateData.foodProduction as Float * updateData.productivity) ; #DEBUG_LINE_NO:1188
    If updateData.foodProduction > 0 ; #DEBUG_LINE_NO:1190
      WorkshopParent.ProduceFood(Self, updateData.foodProduction) ; #DEBUG_LINE_NO:1191
    EndIf
  EndIf
  If updateData.waterProduction > 0 && bAllowWaterProduction ; #DEBUG_LINE_NO:1194
    containerRef.AddItem(WorkshopParent.WorkshopProduceWater as Form, updateData.waterProduction, False) ; #DEBUG_LINE_NO:1196
  EndIf
  If updateData.brahminPopulation > 0 && bAllowFertilizerProduction ; #DEBUG_LINE_NO:1198
    Int fertilizerProduction = Math.min(updateData.brahminPopulation as Float, maxBrahminFertilizerProduction as Float) as Int ; #DEBUG_LINE_NO:1199
    containerRef.AddItem(WorkshopParent.WorkshopProduceFertilizer as Form, fertilizerProduction, False) ; #DEBUG_LINE_NO:1201
  EndIf
  Int scavengePopulation = (updateData.unassignedPopulation as Float - Self.GetValue(ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue)) as Int ; #DEBUG_LINE_NO:1205
  Int scavengeProductionGeneral = Self.GetValue(ratings[WorkshopParent.WorkshopRatingScavengeGeneral].resourceValue) as Int ; #DEBUG_LINE_NO:1208
  Int scavengeAmount = Math.Ceiling((scavengePopulation as Float * updateData.productivity) * updateData.damageMult + (scavengeProductionGeneral as Float * updateData.productivity)) ; #DEBUG_LINE_NO:1211
  If scavengeAmount > 0 && bAllowScavengeProduction ; #DEBUG_LINE_NO:1213
    containerRef.AddItem(WorkshopParent.WorkshopProduceScavenge as Form, scavengeAmount, False) ; #DEBUG_LINE_NO:1215
  EndIf
  If updateData.vendorIncome > 0.0 ; #DEBUG_LINE_NO:1219
    Int vendorIncomeFinal = 0 ; #DEBUG_LINE_NO:1225
    Float linkedPopulation = WorkshopParent.GetLinkedPopulation(Self, False) ; #DEBUG_LINE_NO:1228
    Float vendorPopulation = linkedPopulation + updateData.totalPopulation as Float ; #DEBUG_LINE_NO:1230
    If vendorPopulation >= minVendorIncomePopulation as Float ; #DEBUG_LINE_NO:1233
      linkedPopulation = WorkshopParent.GetLinkedPopulation(Self, True) ; #DEBUG_LINE_NO:1235
      vendorPopulation = (updateData.totalPopulation as Float * updateData.productivity) + linkedPopulation ; #DEBUG_LINE_NO:1240
      Float incomeBonus = updateData.vendorIncome * vendorIncomePopulationMult * vendorPopulation ; #DEBUG_LINE_NO:1243
      updateData.vendorIncome = updateData.vendorIncome + incomeBonus ; #DEBUG_LINE_NO:1245
      vendorIncomeFinal = Math.Ceiling(updateData.vendorIncome) ; #DEBUG_LINE_NO:1247
      vendorIncomeFinal = Math.min(vendorIncomeFinal as Float, maxVendorIncome) as Int ; #DEBUG_LINE_NO:1249
      If vendorIncomeFinal as Float >= 1.0 ; #DEBUG_LINE_NO:1251
        containerRef.AddItem(WorkshopParent.WorkshopProduceVendorIncome as Form, vendorIncomeFinal, False) ; #DEBUG_LINE_NO:1252
      EndIf
    EndIf
  EndIf
EndFunction

Function RepairDamage()
  workshopdatascript:workshopratingkeyword[] ratings = WorkshopParent.WorkshopRatings ; #DEBUG_LINE_NO:1271
  Self.RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingFood].resourceValue) ; #DEBUG_LINE_NO:1274
  Self.RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingWater].resourceValue) ; #DEBUG_LINE_NO:1275
  Self.RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue) ; #DEBUG_LINE_NO:1276
  Self.RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingPower].resourceValue) ; #DEBUG_LINE_NO:1277
  Self.RepairDamageToResource(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) ; #DEBUG_LINE_NO:1278
  Float currentDamage = Self.GetValue(ratings[WorkshopParent.WorkshopRatingDamageCurrent].resourceValue) ; #DEBUG_LINE_NO:1281
  If currentDamage > 0.0 ; #DEBUG_LINE_NO:1282
    WorkshopParent.UpdateCurrentDamage(Self) ; #DEBUG_LINE_NO:1284
  EndIf
EndFunction

Function RepairDamageToResource(ActorValue resourceValue)
  ActorValue damageRating = WorkshopParent.GetDamageRatingValue(resourceValue) ; #DEBUG_LINE_NO:1290
  workshopdatascript:workshopratingkeyword[] ratings = WorkshopParent.WorkshopRatings ; #DEBUG_LINE_NO:1293
  Bool bPopulationDamage = damageRating == ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue ; #DEBUG_LINE_NO:1295
  Float currentDamage = 0.0 ; #DEBUG_LINE_NO:1298
  If bPopulationDamage ; #DEBUG_LINE_NO:1299
    currentDamage = WorkshopParent.GetPopulationDamage(Self) ; #DEBUG_LINE_NO:1300
  Else
    currentDamage = Self.GetValue(damageRating) ; #DEBUG_LINE_NO:1302
  EndIf
  Int currentWorkshopID = WorkshopParent.WorkshopCurrentWorkshopID.GetValueInt() ; #DEBUG_LINE_NO:1308
  If currentDamage > 0.0 ; #DEBUG_LINE_NO:1309
    Float repairAmount = 1.0 ; #DEBUG_LINE_NO:1315
    Bool bHealedActor = False ; #DEBUG_LINE_NO:1316
    If damageRating != ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue ; #DEBUG_LINE_NO:1317
      repairAmount = Self.CalculateRepairAmount(ratings) ; #DEBUG_LINE_NO:1318
      repairAmount = Math.max(repairAmount, 1.0) ; #DEBUG_LINE_NO:1319
    Else
      Location[] linkedLocations = myLocation.GetAllLinkedLocations(WorkshopParent.WorkshopCaravanKeyword) ; #DEBUG_LINE_NO:1324
      If linkedLocations.Length > 0 ; #DEBUG_LINE_NO:1325
        Int index = 0 ; #DEBUG_LINE_NO:1328
        While index < WorkshopParent.CaravanActorAliases.GetCount() ; #DEBUG_LINE_NO:1329
          workshopnpcscript caravanActor = WorkshopParent.CaravanActorAliases.GetAt(index) as workshopnpcscript ; #DEBUG_LINE_NO:1331
          If (caravanActor as Bool && caravanActor.GetWorkshopID() == WorkshopID) && caravanActor.IsWounded() ; #DEBUG_LINE_NO:1332
            bHealedActor = True ; #DEBUG_LINE_NO:1334
            WorkshopParent.WoundActor(caravanActor, False) ; #DEBUG_LINE_NO:1335
            Return  ; #DEBUG_LINE_NO:1336
          EndIf
          index += 1 ; #DEBUG_LINE_NO:1338
        EndWhile
      EndIf
      If !bHealedActor ; #DEBUG_LINE_NO:1342
        If WorkshopID == currentWorkshopID ; #DEBUG_LINE_NO:1344
          Int I = 0 ; #DEBUG_LINE_NO:1345
          ObjectReference[] WorkshopActors = WorkshopParent.GetWorkshopActors(Self) ; #DEBUG_LINE_NO:1346
          While I < WorkshopActors.Length && !bHealedActor ; #DEBUG_LINE_NO:1347
            workshopnpcscript theActor = WorkshopActors[I] as workshopnpcscript ; #DEBUG_LINE_NO:1348
            If theActor as Bool && theActor.IsWounded() ; #DEBUG_LINE_NO:1349
              bHealedActor = True ; #DEBUG_LINE_NO:1350
              WorkshopParent.WoundActor(theActor, False) ; #DEBUG_LINE_NO:1351
            EndIf
            I += 1 ; #DEBUG_LINE_NO:1353
          EndWhile
        EndIf
      EndIf
    EndIf
    If !bHealedActor ; #DEBUG_LINE_NO:1359
      repairAmount = Math.min(repairAmount, currentDamage) ; #DEBUG_LINE_NO:1361
      WorkshopParent.ModifyResourceData(damageRating, Self, repairAmount * -1.0) ; #DEBUG_LINE_NO:1362
      If WorkshopID == currentWorkshopID && damageRating != ratings[WorkshopParent.WorkshopRatingDamagePopulation].resourceValue ; #DEBUG_LINE_NO:1365
        Int i = 0 ; #DEBUG_LINE_NO:1367
        ObjectReference[] ResourceObjects = Self.GetWorkshopResourceObjects(resourceValue, 1) ; #DEBUG_LINE_NO:1369
        While i < ResourceObjects.Length && repairAmount > 0.0 ; #DEBUG_LINE_NO:1370
          workshopobjectscript theObject = ResourceObjects[i] as workshopobjectscript ; #DEBUG_LINE_NO:1371
          Float damage = theObject.GetResourceDamage(resourceValue) ; #DEBUG_LINE_NO:1372
          If damage > 0.0 ; #DEBUG_LINE_NO:1374
            Float modDamage = Math.min(repairAmount, damage) * -1.0 ; #DEBUG_LINE_NO:1375
            If theObject.ModifyResourceDamage(resourceValue, modDamage) ; #DEBUG_LINE_NO:1376
              repairAmount += modDamage ; #DEBUG_LINE_NO:1377
            EndIf
          EndIf
          i += 1 ; #DEBUG_LINE_NO:1380
        EndWhile
      EndIf
    EndIf
  EndIf
EndFunction

Float Function CalculateRepairAmount(workshopdatascript:workshopratingkeyword[] ratings)
  Float uninjuredPopulation = Self.GetValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) ; #DEBUG_LINE_NO:1390
  Float productivityMult = Self.GetProductivityMultiplier(ratings) ; #DEBUG_LINE_NO:1391
  Float amountRepaired = Math.Ceiling(uninjuredPopulation * damageDailyPopulationMult * damageDailyRepairBase * productivityMult) as Float ; #DEBUG_LINE_NO:1392
  Return amountRepaired ; #DEBUG_LINE_NO:1394
EndFunction

Function CheckForAttack(Bool bForceAttack)
  workshopdatascript:workshopratingkeyword[] ratings = WorkshopParent.WorkshopRatings ; #DEBUG_LINE_NO:1405
  WorkshopParent.ModifyResourceData(ratings[WorkshopParent.WorkshopRatingLastAttackDaysSince].resourceValue, Self, 1.0) ; #DEBUG_LINE_NO:1409
  If AllowAttacks == False ; #DEBUG_LINE_NO:1412
    Return  ; #DEBUG_LINE_NO:1414
  EndIf
  If AllowAttacksBeforeOwned == False && OwnedByPlayer == False && bForceAttack == False ; #DEBUG_LINE_NO:1418
    Return  ; #DEBUG_LINE_NO:1420
  EndIf
  ObjectReference containerRef = Self.GetContainer() ; #DEBUG_LINE_NO:1424
  If !containerRef ; #DEBUG_LINE_NO:1425
    Return  ; #DEBUG_LINE_NO:1427
  EndIf
  Int totalPopulation = Self.GetBaseValue(ratings[WorkshopParent.WorkshopRatingPopulation].resourceValue) as Int ; #DEBUG_LINE_NO:1430
  Int safety = Self.GetValue(ratings[WorkshopParent.WorkshopRatingSafety].resourceValue) as Int ; #DEBUG_LINE_NO:1431
  Int safetyPerNPC = 0 ; #DEBUG_LINE_NO:1432
  If totalPopulation > 0 ; #DEBUG_LINE_NO:1433
    safetyPerNPC = Math.Ceiling((safety / totalPopulation) as Float) ; #DEBUG_LINE_NO:1434
  ElseIf bForceAttack
    safetyPerNPC = safety ; #DEBUG_LINE_NO:1436
  Else
    Return  ; #DEBUG_LINE_NO:1440
  EndIf
  Int daysSinceLastAttack = Self.GetValue(ratings[WorkshopParent.WorkshopRatingLastAttackDaysSince].resourceValue) as Int ; #DEBUG_LINE_NO:1443
  If (minDaysSinceLastAttack > daysSinceLastAttack as Float) && !bForceAttack ; #DEBUG_LINE_NO:1444
    Return  ; #DEBUG_LINE_NO:1447
  EndIf
  Int foodRating = Self.GetTotalFoodRating(ratings) ; #DEBUG_LINE_NO:1450
  Int waterRating = Self.GetTotalWaterRating(ratings) ; #DEBUG_LINE_NO:1451
  Float attackChance = attackChanceBase + (attackChanceResourceMult * (foodRating + waterRating) as Float) - (attackChanceSafetyMult * safety as Float) - (attackChancePopulationMult * totalPopulation as Float) ; #DEBUG_LINE_NO:1468
  If attackChance < attackChanceBase ; #DEBUG_LINE_NO:1469
    attackChance = attackChanceBase ; #DEBUG_LINE_NO:1470
  EndIf
  Float attackRoll = Utility.RandomFloat(0.0, 1.0) ; #DEBUG_LINE_NO:1474
  If attackRoll <= attackChance || bForceAttack ; #DEBUG_LINE_NO:1476
    Int attackStrength = WorkshopParent.CalculateAttackStrength(foodRating, waterRating) ; #DEBUG_LINE_NO:1477
    WorkshopParent.TriggerAttack(Self, attackStrength) ; #DEBUG_LINE_NO:1478
  EndIf
EndFunction

Int Function GetTotalFoodRating(workshopdatascript:workshopratingkeyword[] ratings)
  Int foodRating = Self.GetValue(ratings[WorkshopParent.WorkshopRatingFood].resourceValue) as Int ; #DEBUG_LINE_NO:1484
  foodRating += Self.GetContainer().GetItemCount(WorkshopParent.WorkshopConsumeFood as Form) ; #DEBUG_LINE_NO:1485
  Return foodRating ; #DEBUG_LINE_NO:1487
EndFunction

Int Function GetTotalWaterRating(workshopdatascript:workshopratingkeyword[] ratings)
  Int waterRating = Self.GetValue(ratings[WorkshopParent.WorkshopRatingWater].resourceValue) as Int ; #DEBUG_LINE_NO:1492
  waterRating += Self.GetContainer().GetItemCount(WorkshopParent.WorkshopConsumeWater as Form) ; #DEBUG_LINE_NO:1493
  Return waterRating ; #DEBUG_LINE_NO:1495
EndFunction

Float Function CheckActorHappiness(Float currentHappiness, Bool bFood, Bool bWater, Bool bBed, Bool bShelter)
  If !bWater && currentHappiness > maxHappinessNoWater ; #DEBUG_LINE_NO:1502
    currentHappiness = maxHappinessNoWater ; #DEBUG_LINE_NO:1504
  EndIf
  If !bFood && currentHappiness > maxHappinessNoFood ; #DEBUG_LINE_NO:1507
    currentHappiness = maxHappinessNoFood ; #DEBUG_LINE_NO:1509
  EndIf
  If !bShelter && currentHappiness > maxHappinessNoShelter ; #DEBUG_LINE_NO:1512
    currentHappiness = maxHappinessNoShelter ; #DEBUG_LINE_NO:1514
  EndIf
  Return currentHappiness ; #DEBUG_LINE_NO:1517
EndFunction

Float Function GetProductivityMultiplier(workshopdatascript:workshopratingkeyword[] ratings)
  Float currentHappiness = Self.GetValue(ratings[WorkshopParent.WorkshopRatingHappiness].resourceValue) ; #DEBUG_LINE_NO:1522
  Return minProductivity + currentHappiness / 100.0 * (1.0 - minProductivity) ; #DEBUG_LINE_NO:1523
EndFunction

Int Function GetWorkshopID()
  If WorkshopID < 0 ; #DEBUG_LINE_NO:1527
    Self.InitWorkshopID(WorkshopParent.GetWorkshopID(Self)) ; #DEBUG_LINE_NO:1528
  EndIf
  Return WorkshopID ; #DEBUG_LINE_NO:1530
EndFunction

Function InitWorkshopID(Int newWorkshopID)
  If WorkshopID < 0 ; #DEBUG_LINE_NO:1534
    WorkshopID = newWorkshopID ; #DEBUG_LINE_NO:1535
  EndIf
EndFunction

Bool Function RecalculateWorkshopResources(Bool bOnlyIfLocationLoaded)
  If bOnlyIfLocationLoaded == False || myLocation.IsLoaded() ; #DEBUG_LINE_NO:1543
    Self.RecalculateResources() ; #DEBUG_LINE_NO:1545
    Return True ; #DEBUG_LINE_NO:1546
  Else
    Return False ; #DEBUG_LINE_NO:1549
  EndIf
EndFunction
