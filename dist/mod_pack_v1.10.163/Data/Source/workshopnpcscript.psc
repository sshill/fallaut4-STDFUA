ScriptName WorkshopNPCScript Extends Actor conditional
{ script for all NPCs that can be assigned to a workshop }

;-- Variables ---------------------------------------
Bool bSavedAllowCaravan
Bool bSavedAllowMove
Bool bSavedCommandable
Int iSelfActivationCount = 0
Float timerAssignedSeconds = 120.0
Float timerCommandStateSeconds = 5.0
Int timerIDAssigned = 2
Int timerIDCommandState = 1
Int workshopID = -1 conditional

;-- Properties --------------------------------------
Group WorkerData
  Bool Property bCommandable = False Auto conditional
  { TRUE = commandable by player - can be ordered to different work objects (default)
	  FALSE = player can't command although will still count as worker if given default work }
  Bool Property bAllowCaravan = False Auto conditional
  { TRUE = can be assigned to caravan duty }
  Bool Property bAllowMove = False Auto conditional
  { TRUE = can be moved to different settlements }
  Bool Property bIsWorker = False Auto conditional
  { worker flag - used by package conditions
		set to TRUE if this NPC is a worker of any kind }
  Bool Property bWork24Hours = False Auto conditional
  { set to TRUE to have someone work 24 hours }
  Bool Property bIsGuard = False Auto conditional hidden
  { set to TRUE if this NPC is a "guard" - assigned to Safety work objects like guard posts etc. }
  Bool Property bIsScavenger = False Auto conditional hidden
  { set to TRUE if this NPC is a scavenger - assigned to Scavenge work objects }
  ActorValue Property assignedMultiResource Auto
  { if NONE this worker is assigned a single object to work on
	  otherwise, this is the rating keyword (food, safety, etc.) of the type of resource
	  this NPC can work on }
  Float Property multiResourceProduction = 0.0 Auto conditional hidden
  { if assignedMultiResource is set, this tracks how much production this NPC is assigned to }
  Bool Property bIsSynth = False Auto conditional hidden
  { set to TRUE if this NPC has been tagged as a synth - gives appropriate death item }
EndGroup

Group VendorData
  Int Property specialVendorType = -1 Auto Const
  { based on index from WorkshopParent VendorTypes - set for NPCs who have special vendor abilities }
  Int Property specialVendorMinLevel = 2 Auto Const
  { if a special vendor, what level does the vendor object have to be to allow special ability? }
  Container Property specialVendorContainerBase Auto Const
  { base object of special vendor container to link to when special ability is allowed }
  ObjectReference Property specialVendorContainerRef Auto hidden
  { reference (created by script) to link to when special ability is allowed }
  ObjectReference Property specialVendorContainerRefUnique Auto
  { reference to link to when special ability is allowed }
EndGroup

workshopparentscript Property WorkshopParent Auto Const
Bool Property bWorkshopStatusOn = True Auto conditional hidden
{ set to false when temporarily turning off - but saving - workshop NPC status, e.g. for companions }
Bool Property bResetDone = False Auto hidden
Actor Property myBrahmin Auto
Bool Property bNewSettler = False Auto conditional
{ set to true when new settlers are created - set back to false after player "meets" them }
Bool Property bCountsForPopulation = True Auto conditional
{ set to false for things like brahmin which don't count for total population }
Bool Property bApplyWorkshopOwnerFaction = True Auto conditional
{ set to false for NPCs that should not pick up the owner faction of their assigned workshop - e.g. companions }
LocationRefType Property CustomBossLocRefType Auto Const
{ Patch 1.4: custom loc ref type to use for this actor when assigning to workshop }

;-- Functions ---------------------------------------

Int Function GetWorkshopID()
  Return workshopID ; #DEBUG_LINE_NO:100
EndFunction

Function SetWorkshopID(Int newWorkshopID)
  workshopID = newWorkshopID ; #DEBUG_LINE_NO:104
  Self.SetValue(WorkshopParent.workshopIDActorValue, newWorkshopID as Float) ; #DEBUG_LINE_NO:105
  If newWorkshopID > -1 ; #DEBUG_LINE_NO:107
    Self.gotoState("assigned") ; #DEBUG_LINE_NO:108
  Else
    Self.gotoState("unassigned") ; #DEBUG_LINE_NO:110
  EndIf
EndFunction

Function UpdatePlayerOwnership(workshopscript workshopRef)
  If workshopRef == None ; #DEBUG_LINE_NO:116
    workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:117
  EndIf
  If workshopRef ; #DEBUG_LINE_NO:120
    Self.SetValue(WorkshopParent.WorkshopPlayerOwnership, (workshopRef.OwnedByPlayer as Int) as Float) ; #DEBUG_LINE_NO:122
  EndIf
EndFunction

Int Function GetCaravanDestinationID()
  Return Self.GetValue(WorkshopParent.WorkshopCaravanDestination) as Int ; #DEBUG_LINE_NO:128
EndFunction

Bool Function IsWounded()
  Return Self.GetValue(WorkshopParent.WorkshopActorWounded) as Bool ; #DEBUG_LINE_NO:133
EndFunction

Function SetWounded(Bool bIsWounded)
  Self.SetValue(WorkshopParent.WorkshopActorWounded, (bIsWounded as Int) as Float) ; #DEBUG_LINE_NO:137
  Int foundIndex = WorkshopParent.CaravanActorAliases.Find(Self as ObjectReference) ; #DEBUG_LINE_NO:139
  If foundIndex > -1 ; #DEBUG_LINE_NO:140
    WorkshopParent.TurnOnCaravanActor(Self, bIsWounded == False, True) ; #DEBUG_LINE_NO:141
  EndIf
EndFunction

Function SetWorker(Bool isWorker)
  bIsWorker = isWorker ; #DEBUG_LINE_NO:146
  If !isWorker ; #DEBUG_LINE_NO:147
    bIsGuard = False ; #DEBUG_LINE_NO:148
    bIsScavenger = False ; #DEBUG_LINE_NO:149
  EndIf
EndFunction

Function SetScavenger(Bool isScavenger)
  bIsScavenger = isScavenger ; #DEBUG_LINE_NO:154
EndFunction

Function SetSynth(Bool isSynth)
  bIsSynth = isSynth ; #DEBUG_LINE_NO:159
  Self.SetValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingPopulationSynths].resourceValue, (isSynth == True) as Float) ; #DEBUG_LINE_NO:160
  If Self.IsCreated() && workshopID > -1 ; #DEBUG_LINE_NO:162
    workshopscript workshopRef = WorkshopParent.GetWorkshop(Self.GetWorkshopID()) ; #DEBUG_LINE_NO:163
    If workshopRef.myLocation ; #DEBUG_LINE_NO:164
      If isSynth ; #DEBUG_LINE_NO:165
        Self.SetLocRefType(workshopRef.myLocation, WorkshopParent.WorkshopSynthRefType) ; #DEBUG_LINE_NO:166
      Else
        Self.SetLocRefType(workshopRef.myLocation, WorkshopParent.Boss) ; #DEBUG_LINE_NO:169
      EndIf
      Self.ClearFromOldLocations() ; #DEBUG_LINE_NO:171
    EndIf
  EndIf
EndFunction

Function SetMultiResource(ActorValue resourceValue)
  assignedMultiResource = resourceValue ; #DEBUG_LINE_NO:179
  If assignedMultiResource == WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingSafety].resourceValue ; #DEBUG_LINE_NO:180
    bIsGuard = True ; #DEBUG_LINE_NO:181
  Else
    bIsGuard = False ; #DEBUG_LINE_NO:183
  EndIf
  If !assignedMultiResource ; #DEBUG_LINE_NO:186
    multiResourceProduction = 0.0 ; #DEBUG_LINE_NO:188
  EndIf
EndFunction

Function AddMultiResourceProduction(Float newProduction)
  multiResourceProduction += newProduction ; #DEBUG_LINE_NO:193
EndFunction

Function SetAsBoss(Location newLocation)
  If CustomBossLocRefType ; #DEBUG_LINE_NO:198
    Self.SetLocRefType(newLocation, CustomBossLocRefType) ; #DEBUG_LINE_NO:199
  Else
    Self.SetLocRefType(newLocation, WorkshopParent.Boss) ; #DEBUG_LINE_NO:201
  EndIf
  Self.ClearFromOldLocations() ; #DEBUG_LINE_NO:203
EndFunction

Event FollowersScript.CompanionChange(followersscript akSender, Var[] akArgs)
  Actor EventActor = akArgs[0] as Actor ; #DEBUG_LINE_NO:303
  Bool IsNowCompanion = akArgs[1] as Bool ; #DEBUG_LINE_NO:304
  If EventActor == Self as Actor ; #DEBUG_LINE_NO:306
    If IsNowCompanion ; #DEBUG_LINE_NO:307
      Self.SetWorkshopStatus(False) ; #DEBUG_LINE_NO:309
    Else
      Self.SetWorkshopStatus(True) ; #DEBUG_LINE_NO:312
    EndIf
  EndIf
EndEvent

Event OnWorkshopNPCTransfer(Location akNewWorkshopLocation, Keyword akActionKW)
  If akActionKW == WorkshopParent.WorkshopAssignCaravan ; #DEBUG_LINE_NO:321
    WorkshopParent.AssignCaravanActorPUBLIC(Self, akNewWorkshopLocation) ; #DEBUG_LINE_NO:322
  Else
    workshopscript newWorkshop = WorkshopParent.GetWorkshopFromLocation(akNewWorkshopLocation) ; #DEBUG_LINE_NO:324
    If newWorkshop ; #DEBUG_LINE_NO:325
      If akActionKW == WorkshopParent.WorkshopAssignHome ; #DEBUG_LINE_NO:326
        WorkshopParent.AddActorToWorkshopPUBLIC(Self, newWorkshop, False) ; #DEBUG_LINE_NO:327
      ElseIf akActionKW == WorkshopParent.WorkshopAssignHomePermanentActor ; #DEBUG_LINE_NO:328
        WorkshopParent.AddPermanentActorToWorkshopPUBLIC(Self as Actor, newWorkshop.GetWorkshopID(), True) ; #DEBUG_LINE_NO:329
      EndIf
    EndIf
  EndIf
EndEvent

Function StartAssignmentTimer(Bool bStart)
  If bStart ; #DEBUG_LINE_NO:342
    Self.SetValue(WorkshopParent.WorkshopActorAssigned, 1.0) ; #DEBUG_LINE_NO:344
    Self.StartTimer(timerAssignedSeconds, timerIDAssigned) ; #DEBUG_LINE_NO:345
    Self.EvaluatePackage(False) ; #DEBUG_LINE_NO:346
  Else
    Self.SetValue(WorkshopParent.WorkshopActorAssigned, 0.0) ; #DEBUG_LINE_NO:349
    Self.CancelTimer(timerIDAssigned) ; #DEBUG_LINE_NO:350
  EndIf
EndFunction

Function StartCommandState()
  iSelfActivationCount = 0 ; #DEBUG_LINE_NO:357
  workshopscript myWorkshop = WorkshopParent.GetWorkshop(Self.GetWorkshopID()) ; #DEBUG_LINE_NO:359
  If myWorkshop ; #DEBUG_LINE_NO:360
    Self.StartTimer(timerCommandStateSeconds, timerIDCommandState) ; #DEBUG_LINE_NO:361
    Self.setDoingFavor(True, True) ; #DEBUG_LINE_NO:362
  EndIf
EndFunction

Event OnTimer(Int aiTimerID)
  If aiTimerID == timerIDCommandState ; #DEBUG_LINE_NO:367
    workshopscript myWorkshop = WorkshopParent.GetWorkshop(Self.GetWorkshopID()) ; #DEBUG_LINE_NO:368
    If myWorkshop as Bool && Self.IsWithinBuildableArea(myWorkshop as ObjectReference) ; #DEBUG_LINE_NO:369
      Self.StartTimer(timerCommandStateSeconds, timerIDCommandState) ; #DEBUG_LINE_NO:371
    Else
      Self.setDoingFavor(False, False) ; #DEBUG_LINE_NO:374
    EndIf
  ElseIf aiTimerID == timerIDAssigned ; #DEBUG_LINE_NO:376
    Self.StartAssignmentTimer(False) ; #DEBUG_LINE_NO:377
  EndIf
EndEvent

Function SetCommandable(Bool bFlag)
  bSavedCommandable = bFlag ; #DEBUG_LINE_NO:384
  If bWorkshopStatusOn ; #DEBUG_LINE_NO:386
    bCommandable = bFlag ; #DEBUG_LINE_NO:387
    If bCommandable ; #DEBUG_LINE_NO:388
      Self.AddKeyword(WorkshopParent.WorkshopAllowCommand) ; #DEBUG_LINE_NO:390
    Else
      Self.RemoveKeyword(WorkshopParent.WorkshopAllowCommand) ; #DEBUG_LINE_NO:392
    EndIf
  EndIf
EndFunction

Function SetAllowCaravan(Bool bFlag)
  bSavedAllowCaravan = bFlag ; #DEBUG_LINE_NO:402
  If bWorkshopStatusOn ; #DEBUG_LINE_NO:404
    bAllowCaravan = bFlag ; #DEBUG_LINE_NO:405
    If bAllowCaravan ; #DEBUG_LINE_NO:406
      Self.AddKeyword(WorkshopParent.WorkshopAllowCaravan) ; #DEBUG_LINE_NO:407
    Else
      Self.RemoveKeyword(WorkshopParent.WorkshopAllowCaravan) ; #DEBUG_LINE_NO:409
    EndIf
  EndIf
EndFunction

Function SetAllowMove(Bool bFlag)
  bSavedAllowMove = bFlag ; #DEBUG_LINE_NO:419
  If bWorkshopStatusOn ; #DEBUG_LINE_NO:421
    bAllowMove = bFlag ; #DEBUG_LINE_NO:422
    If bAllowMove ; #DEBUG_LINE_NO:423
      Self.AddKeyword(WorkshopParent.WorkshopAllowMove) ; #DEBUG_LINE_NO:424
    Else
      Self.RemoveKeyword(WorkshopParent.WorkshopAllowMove) ; #DEBUG_LINE_NO:426
    EndIf
  EndIf
EndFunction

Function SetWorkshopStatus(Bool setWorkshopStatusOn)
  bWorkshopStatusOn = setWorkshopStatusOn ; #DEBUG_LINE_NO:435
  If bWorkshopStatusOn ; #DEBUG_LINE_NO:436
    Self.SetCommandable(bSavedCommandable) ; #DEBUG_LINE_NO:438
    Self.SetAllowMove(bSavedAllowMove) ; #DEBUG_LINE_NO:439
    Self.SetAllowCaravan(bSavedAllowCaravan) ; #DEBUG_LINE_NO:440
  Else
    bSavedAllowMove = bAllowMove ; #DEBUG_LINE_NO:443
    bSavedAllowCaravan = bAllowCaravan ; #DEBUG_LINE_NO:444
    bSavedCommandable = bCommandable ; #DEBUG_LINE_NO:445
    Self.RemoveKeyword(WorkshopParent.WorkshopAllowCommand) ; #DEBUG_LINE_NO:447
    Self.RemoveKeyword(WorkshopParent.WorkshopAllowMove) ; #DEBUG_LINE_NO:448
    Self.RemoveKeyword(WorkshopParent.WorkshopAllowCaravan) ; #DEBUG_LINE_NO:449
    bAllowMove = False ; #DEBUG_LINE_NO:450
    bAllowCaravan = False ; #DEBUG_LINE_NO:451
    bCommandable = False ; #DEBUG_LINE_NO:452
    WorkshopParent.UnassignActor(Self, False, True) ; #DEBUG_LINE_NO:454
  EndIf
EndFunction

Function TestKill()
  Self.KillEssential(None) ; #DEBUG_LINE_NO:459
EndFunction

;-- State -------------------------------------------
State assigned

  Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)
    If aeCombatState == 0 && Self.IsWounded()
      WorkshopParent.WoundActor(Self, False)
    EndIf
  EndEvent

  Event OnCommandModeGiveCommand(Int aeCommandType, ObjectReference akTarget)
    workshopobjectscript workObject = akTarget as workshopobjectscript
    If workObject as Bool && aeCommandType == 10
      workObject.ActivatedByWorkshopActor(Self)
    EndIf
  EndEvent

  Event OnDeath(Actor akKiller)
    If bIsSynth
      Self.AddItem(WorkshopParent.SynthDeathItem as Form, 1, False)
    EndIf
    WorkshopParent.HandleActorDeath(Self, akKiller)
  EndEvent

  Event OnEnterBleedout()
    If Self.IsWounded()
      
    Else
      WorkshopParent.WoundActor(Self, True)
    EndIf
  EndEvent

  Event OnLoad()
    If bWorkshopStatusOn
      Self.SetCommandable(bCommandable)
      Self.SetAllowCaravan(bAllowCaravan)
      Self.SetAllowMove(bAllowMove)
    EndIf
    If Self.IsDead() == False && Self.IsWounded()
      WorkshopParent.WoundActor(Self, False)
    EndIf
    WorkshopParent.CaravanActorBrahminCheck(Self, True)
  EndEvent

  Event OnActivate(ObjectReference akActionRef)
    If WorkshopParent.GetWorkshop(Self.GetWorkshopID()).OwnedByPlayer ; #DEBUG_LINE_NO:234
      If Self.IsDoingFavor() && (akActionRef == Self as ObjectReference) && bCommandable ; #DEBUG_LINE_NO:236
        iSelfActivationCount += 1 ; #DEBUG_LINE_NO:238
        If iSelfActivationCount > 1 ; #DEBUG_LINE_NO:239
          Self.setDoingFavor(False, True) ; #DEBUG_LINE_NO:241
        EndIf
      EndIf
    EndIf
  EndEvent
EndState

;-- State -------------------------------------------
Auto State unassigned

  Event OnInit()
    If (Self as Actor) is companionactorscript ; #DEBUG_LINE_NO:211
      Self.RegisterForCustomEvent(followersscript.GetScript() as ScriptObject, "followersscript_CompanionChange") ; #DEBUG_LINE_NO:213
    EndIf
    Self.SetCommandable(bCommandable) ; #DEBUG_LINE_NO:215
    Self.SetAllowCaravan(bAllowCaravan) ; #DEBUG_LINE_NO:216
    Self.SetAllowMove(bAllowMove) ; #DEBUG_LINE_NO:217
    If Self.GetLinkedRef(WorkshopParent.WorkshopLinkWork) ; #DEBUG_LINE_NO:220
      workshopobjectscript workObject = Self.GetLinkedRef(WorkshopParent.WorkshopLinkWork) as workshopobjectscript ; #DEBUG_LINE_NO:221
      workObject.AssignActor(Self) ; #DEBUG_LINE_NO:223
    EndIf
  EndEvent
EndState
