ScriptName WorkshopObjectScript Extends ObjectReference
{ script for workshop buildable objects
holds data about the object and sends event when build
(possibly all of this will turn out to be temp)
TODO - make const when it stops holding data }

;-- Variables ---------------------------------------
Int OnPowerOnTimer = 0
Int OnPowerOnTimerCount = 0
Float OnPowerOnTimerLength = 0.5
Int OnPowerOnTimerMaxCount = 10
Bool bHasMultiResource = False
Bool bMultiResourceInitialized = False
Float floraResetHarvestDays = 1.0 Const
ActorValue multiResourceValue
ObjectReference myDamageHelperRef
ObjectReference[] myFurnitureMarkerRefs

;-- Properties --------------------------------------
Group VendorData
  Int Property VendorType = -1 Auto Const
  { based on index from WorkshopParent VendorTypes }
  Int Property VendorLevel = 0 Auto Const
  { level of vendor for this store: 0-2 }
  Bool Property bVendorTopLevelValid = False Auto hidden
  { set to TRUE when this object counts as a valid top level vendor }
EndGroup

Group FurnitureMarker
  Form Property FurnitureBase Auto Const
  { if set, will be used to create reference (myFurnitureMarkerRef) when object is created }
  Bool Property bPlaceMarkerOnCreation = False Auto Const
  { true = place marker when object is created -- this is a very special case, currently used only for MQ206 teleporter objects
	  false = place marker only when object is assigned (and delete when unassigned) }
  Bool Property bMarkersGetOwnership = True Auto Const
  { true = markers get same ownership as object (e.g. flora work markers)
	  false = markers don't pick up object ownership (e.g. relaxation markers) }
  String[] Property FurnitureMarkerNodes Auto Const
  { Nodes to use to place furniture markers }
  Form Property SpecialFurnitureBase Auto Const
  { use this as a flag - whereever this appears place at SpecialFurnitureBaseNode }
  String Property SpecialFurnitureBaseNode Auto Const
  { see above - node in FurnitureMarkerNodes array to place SpecialFurnitureBase }
  Bool Property bSpecialMarkerGetsOwnership = True Auto Const
  { true = special marker gets same ownership as object
	  false = marker doesn't pick up object ownership }
  Keyword Property SpecialFurniturePlacementKeyword Auto Const
  { OPTIONAL - if it exists, only place SpecialFurnitureBase if owning actor has this keyword }
EndGroup

workshopparentscript Property WorkshopParent Auto Const mandatory
Int Property workshopID = -1 Auto conditional hidden
Bool Property bAllowPlayerAssignment = True Auto conditional
{ TRUE = player can assign NPCs to work on this object (default)
	FALSE = ignore assignment by player - scripted/editor set assignment is all that is allowed }
Bool Property bAllowAutoRepair = True Auto conditional
{ TRUE = can be repaired automatically by daily update process
  FALSE = can ONLY be repaired manually by player }
Bool Property bDefaultPlayerOwnership = True Auto conditional
{ TRUE = set to player ownership when built - this allows objects which aren't work objects to be targeted by enemies
	FALSE = no default player ownership }
Bool Property bWork24Hours = False Auto conditional Const
{ TRUE = NPCs assigned to this will be set to work 24 hours a day (no sleep, no relaxation)
	FALSE = normal work hours }
Keyword Property AssignedActorLinkKeyword Auto conditional
{ OPTIONAL - if specified, assigned actor will be linked to this object using this keyword
  allows assigned actor to hold position near the object in combat }
Bool Property bResetDone = False Auto hidden
movablestatic Property DamageHelper Auto Const
{ OPTIONAL - if set, create a damage helper when built and link it to me }
Bool Property bRadioOn = True Auto hidden

;-- Functions ---------------------------------------

Function AssignActorCustom(workshopnpcscript newActor)
  ; Empty function
EndFunction

Event OnInit()
  Actor meActor = (Self as ObjectReference) as Actor ; #DEBUG_LINE_NO:115
  If (meActor as Bool && Self.IsPowered() == False) && Self.RequiresPower() ; #DEBUG_LINE_NO:116
    meActor.SetUnconscious(True) ; #DEBUG_LINE_NO:117
  EndIf
  If bPlaceMarkerOnCreation ; #DEBUG_LINE_NO:119
    Self.CreateFurnitureMarkers() ; #DEBUG_LINE_NO:120
  EndIf
  Self.HandleCreation(False) ; #DEBUG_LINE_NO:122
EndEvent

Event OnLoad()
  If AssignedActorLinkKeyword ; #DEBUG_LINE_NO:127
    Actor myOwner = Self.GetActorRefOwner() ; #DEBUG_LINE_NO:128
    If myOwner ; #DEBUG_LINE_NO:129
      myOwner.SetLinkedRef(Self as ObjectReference, AssignedActorLinkKeyword) ; #DEBUG_LINE_NO:130
    EndIf
  EndIf
EndEvent

Event OnUnload()
  If AssignedActorLinkKeyword ; #DEBUG_LINE_NO:137
    Actor myOwner = Self.GetActorRefOwner() ; #DEBUG_LINE_NO:138
    If myOwner ; #DEBUG_LINE_NO:139
      myOwner.SetLinkedRef(None, AssignedActorLinkKeyword) ; #DEBUG_LINE_NO:140
    EndIf
  EndIf
EndEvent

Bool Function HasMultiResource()
  If bMultiResourceInitialized ; #DEBUG_LINE_NO:147
    Return bHasMultiResource ; #DEBUG_LINE_NO:148
  Else
    Self.GetMultiResourceValue() ; #DEBUG_LINE_NO:150
    Return bHasMultiResource ; #DEBUG_LINE_NO:151
  EndIf
EndFunction

ActorValue Function GetMultiResourceValue()
  If bMultiResourceInitialized ; #DEBUG_LINE_NO:158
    If bHasMultiResource ; #DEBUG_LINE_NO:159
      Return multiResourceValue ; #DEBUG_LINE_NO:160
    Else
      Return None ; #DEBUG_LINE_NO:162
    EndIf
  EndIf
  workshopdatascript:workshopactorvalue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs ; #DEBUG_LINE_NO:168
  Int ArrayLength = WorkshopResourceAVs.Length ; #DEBUG_LINE_NO:169
  Int I = 0 ; #DEBUG_LINE_NO:170
  While I < ArrayLength ; #DEBUG_LINE_NO:171
    If Self.GetBaseValue(WorkshopResourceAVs[I].resourceValue) > 0.0 && WorkshopParent.WorkshopRatings[WorkshopResourceAVs[I].workshopRatingIndex].maxProductionPerNPC > 0 ; #DEBUG_LINE_NO:174
      bHasMultiResource = True ; #DEBUG_LINE_NO:176
      multiResourceValue = WorkshopResourceAVs[I].resourceValue ; #DEBUG_LINE_NO:177
      I = ArrayLength ; #DEBUG_LINE_NO:178
    EndIf
    I += 1 ; #DEBUG_LINE_NO:180
  EndWhile
  bMultiResourceInitialized = True ; #DEBUG_LINE_NO:182
EndFunction

Bool Function RequiresActor()
  Return Self.HasKeyword(WorkshopParent.WorkshopWorkObject) ; #DEBUG_LINE_NO:187
EndFunction

Bool Function IsBed()
  Float val = Self.GetBaseValue(WorkshopParent.WorkshopRatings[WorkshopParent.WorkshopRatingBeds].resourceValue) ; #DEBUG_LINE_NO:192
  Return val > 0.0 ; #DEBUG_LINE_NO:194
EndFunction

Bool Function IsActorAssigned()
  Bool val = Self.GetAssignedActor() == None ; #DEBUG_LINE_NO:199
  val = !val ; #DEBUG_LINE_NO:199
  If !val && Self.IsBed() && Self.GetFactionOwner() != None ; #DEBUG_LINE_NO:200
    val = True ; #DEBUG_LINE_NO:203
  EndIf
  Return val ; #DEBUG_LINE_NO:206
EndFunction

workshopnpcscript Function GetAssignedActor()
  workshopnpcscript assignedActor = Self.GetActorRefOwner() as workshopnpcscript ; #DEBUG_LINE_NO:210
  If !assignedActor ; #DEBUG_LINE_NO:211
    ActorBase baseActor = Self.GetActorOwner() ; #DEBUG_LINE_NO:213
    If baseActor as Bool && baseActor.IsUnique() ; #DEBUG_LINE_NO:215
      assignedActor = baseActor.GetUniqueActor() as workshopnpcscript ; #DEBUG_LINE_NO:217
    EndIf
  EndIf
  Return assignedActor ; #DEBUG_LINE_NO:221
EndFunction

Bool Function RequiresPower()
  Return Self.GetValue(WorkshopParent.PowerRequired) > 0.0 ; #DEBUG_LINE_NO:225
EndFunction

Bool Function GeneratesPower()
  Return Self.GetValue(WorkshopParent.PowerGenerated) > 0.0 ; #DEBUG_LINE_NO:229
EndFunction

Event OnTimer(Int aiTimerID)
  If aiTimerID == OnPowerOnTimer ; #DEBUG_LINE_NO:241
    OnPowerOnTimerCount += 1 ; #DEBUG_LINE_NO:242
    If OnPowerOnTimerCount <= OnPowerOnTimerMaxCount ; #DEBUG_LINE_NO:243
      Self.HandlePowerStateChange(True) ; #DEBUG_LINE_NO:244
    EndIf
  EndIf
EndEvent

Bool Function IsFactionOwner(workshopnpcscript theActor)
  Faction theFaction = Self.GetFactionOwner() ; #DEBUG_LINE_NO:250
  Return theFaction as Bool && theActor.IsInFaction(theFaction) ; #DEBUG_LINE_NO:251
EndFunction

Function AssignActorOwnership(Actor newActor)
  If newActor ; #DEBUG_LINE_NO:257
    Self.SetActorRefOwner(newActor, True) ; #DEBUG_LINE_NO:258
    If FurnitureBase as Bool && myFurnitureMarkerRefs.Length == 0 ; #DEBUG_LINE_NO:260
      Self.CreateFurnitureMarkers() ; #DEBUG_LINE_NO:261
      Self.UpdatePosition() ; #DEBUG_LINE_NO:262
    EndIf
    Self.SetFurnitureMarkerOwnership(newActor) ; #DEBUG_LINE_NO:264
  Else
    Self.SetActorRefOwner(None, False) ; #DEBUG_LINE_NO:266
    If bPlaceMarkerOnCreation ; #DEBUG_LINE_NO:268
      Self.SetFurnitureMarkerOwnership(None) ; #DEBUG_LINE_NO:269
    Else
      Self.DeleteFurnitureMarkers() ; #DEBUG_LINE_NO:272
    EndIf
  EndIf
EndFunction

Function SetFurnitureMarkerOwnership(Actor newActor)
  If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:279
    Int I = 0 ; #DEBUG_LINE_NO:280
    While I < myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:281
      If newActor ; #DEBUG_LINE_NO:282
        Bool bSetOwnership = bMarkersGetOwnership ; #DEBUG_LINE_NO:284
        If SpecialFurnitureBase ; #DEBUG_LINE_NO:285
          If myFurnitureMarkerRefs[I].GetBaseObject() == SpecialFurnitureBase && bSpecialMarkerGetsOwnership ; #DEBUG_LINE_NO:286
            bSetOwnership = True ; #DEBUG_LINE_NO:287
          EndIf
        EndIf
        If bSetOwnership ; #DEBUG_LINE_NO:290
          myFurnitureMarkerRefs[I].SetActorRefOwner(newActor, True) ; #DEBUG_LINE_NO:291
        EndIf
      Else
        myFurnitureMarkerRefs[I].SetActorRefOwner(None, False) ; #DEBUG_LINE_NO:294
      EndIf
      I += 1 ; #DEBUG_LINE_NO:296
    EndWhile
  EndIf
EndFunction

Function DeleteFurnitureMarkers()
  If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:303
    Int I = 0 ; #DEBUG_LINE_NO:304
    While I < myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:305
      myFurnitureMarkerRefs[I].Delete() ; #DEBUG_LINE_NO:306
      I += 1 ; #DEBUG_LINE_NO:307
    EndWhile
    myFurnitureMarkerRefs.clear() ; #DEBUG_LINE_NO:309
  EndIf
EndFunction

Function AssignActor(workshopnpcscript newActor)
  If newActor ; #DEBUG_LINE_NO:316
    If Self.IsBed() && Self.IsOwnedBy(newActor as Actor) ; #DEBUG_LINE_NO:318
      
    Else
      Self.SetActorRefOwner(newActor as Actor, True) ; #DEBUG_LINE_NO:322
    EndIf
    If FurnitureBase as Bool && myFurnitureMarkerRefs.Length == 0 ; #DEBUG_LINE_NO:326
      Self.CreateFurnitureMarkers() ; #DEBUG_LINE_NO:327
      Self.UpdatePosition() ; #DEBUG_LINE_NO:328
    EndIf
    If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:330
      Self.SetFurnitureMarkerOwnership(newActor as Actor) ; #DEBUG_LINE_NO:331
    EndIf
    If AssignedActorLinkKeyword ; #DEBUG_LINE_NO:335
      newActor.SetLinkedRef(Self as ObjectReference, AssignedActorLinkKeyword) ; #DEBUG_LINE_NO:336
    EndIf
  Else
    Self.SetActorRefOwner(None, False) ; #DEBUG_LINE_NO:339
    Self.SetActorOwner(Game.GetPlayer().GetActorBase(), False) ; #DEBUG_LINE_NO:341
    If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:343
      If bPlaceMarkerOnCreation ; #DEBUG_LINE_NO:345
        Self.SetFurnitureMarkerOwnership(None) ; #DEBUG_LINE_NO:346
      Else
        Self.DeleteFurnitureMarkers() ; #DEBUG_LINE_NO:349
      EndIf
    EndIf
  EndIf
  Self.AssignActorCustom(newActor) ; #DEBUG_LINE_NO:354
EndFunction

Function CreateFurnitureMarkers()
  If FurnitureBase == None ; #DEBUG_LINE_NO:388
    Return  ; #DEBUG_LINE_NO:389
  Else
    If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:392
      Self.DeleteFurnitureMarkers() ; #DEBUG_LINE_NO:393
    EndIf
    myFurnitureMarkerRefs = new ObjectReference[0] ; #DEBUG_LINE_NO:396
  EndIf
  Form myFurnitureBase = None ; #DEBUG_LINE_NO:399
  FormList myFormList = FurnitureBase as FormList ; #DEBUG_LINE_NO:400
  Int I = 0 ; #DEBUG_LINE_NO:402
  While I < FurnitureMarkerNodes.Length ; #DEBUG_LINE_NO:403
    If myFormList ; #DEBUG_LINE_NO:405
      Int pickIndex = Utility.RandomInt(0, myFormList.GetSize() - 1) ; #DEBUG_LINE_NO:407
      myFurnitureBase = myFormList.GetAt(pickIndex) ; #DEBUG_LINE_NO:408
    Else
      myFurnitureBase = FurnitureBase ; #DEBUG_LINE_NO:411
    EndIf
    If SpecialFurnitureBase ; #DEBUG_LINE_NO:415
      String currentNode = FurnitureMarkerNodes[I] ; #DEBUG_LINE_NO:417
      If currentNode == SpecialFurnitureBaseNode ; #DEBUG_LINE_NO:418
        If SpecialFurniturePlacementKeyword ; #DEBUG_LINE_NO:419
          Actor myOwner = Self.GetActorRefOwner() ; #DEBUG_LINE_NO:421
          If myOwner as Bool && myOwner.HasKeyword(SpecialFurniturePlacementKeyword) ; #DEBUG_LINE_NO:422
            myFurnitureBase = SpecialFurnitureBase ; #DEBUG_LINE_NO:423
          Else
            myFurnitureBase = None ; #DEBUG_LINE_NO:425
          EndIf
        Else
          myFurnitureBase = SpecialFurnitureBase ; #DEBUG_LINE_NO:428
        EndIf
      EndIf
    EndIf
    If myFurnitureBase ; #DEBUG_LINE_NO:433
      ObjectReference newMarker = Self.PlaceAtMe(myFurnitureBase, 1, False, False, True) ; #DEBUG_LINE_NO:434
      myFurnitureMarkerRefs.add(newMarker, 1) ; #DEBUG_LINE_NO:436
      If Self.HasNode(FurnitureMarkerNodes[I]) ; #DEBUG_LINE_NO:437
        newMarker.MoveToNode(Self as ObjectReference, FurnitureMarkerNodes[I], "") ; #DEBUG_LINE_NO:438
      EndIf
      newMarker.MoveToNearestNavmeshLocation() ; #DEBUG_LINE_NO:441
    EndIf
    I += 1 ; #DEBUG_LINE_NO:444
  EndWhile
EndFunction

Function HandleDestruction()
  workshopscript workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:454
  Self.RecalculateResourceDamage(workshopRef, False) ; #DEBUG_LINE_NO:456
  WorkshopParent.UpdateWorkshopRatingsForResourceObject(Self, WorkshopParent.GetWorkshop(workshopID), False, False) ; #DEBUG_LINE_NO:459
  Int I = 0 ; #DEBUG_LINE_NO:462
  While I < myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:463
    myFurnitureMarkerRefs[I].SetDestroyed(True) ; #DEBUG_LINE_NO:464
    I += 1 ; #DEBUG_LINE_NO:465
  EndWhile
  If Self.GetBaseObject() as Flora ; #DEBUG_LINE_NO:469
    Self.SetHarvested(True) ; #DEBUG_LINE_NO:470
  EndIf
  WorkshopParent.SendDestructionStateChangedEvent(Self, workshopRef) ; #DEBUG_LINE_NO:473
EndFunction

Function RecalculateResourceDamage(workshopscript workshopRef, Bool clearAllDamage)
  If workshopRef == None ; #DEBUG_LINE_NO:478
    workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:480
  EndIf
  workshopdatascript:workshopactorvalue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs ; #DEBUG_LINE_NO:484
  Int I = 0 ; #DEBUG_LINE_NO:487
  Int ArrayLength = WorkshopResourceAVs.Length ; #DEBUG_LINE_NO:488
  While I < ArrayLength ; #DEBUG_LINE_NO:489
    ActorValue resourceValue = WorkshopResourceAVs[I].resourceValue ; #DEBUG_LINE_NO:490
    Float baseValue = Self.GetBaseValue(resourceValue) ; #DEBUG_LINE_NO:491
    If baseValue > 0.0 ; #DEBUG_LINE_NO:492
      If clearAllDamage ; #DEBUG_LINE_NO:493
        Self.RestoreValue(resourceValue, baseValue) ; #DEBUG_LINE_NO:495
      EndIf
      WorkshopParent.RecalculateResourceDamageForResource(workshopRef, resourceValue) ; #DEBUG_LINE_NO:499
    EndIf
    I += 1 ; #DEBUG_LINE_NO:501
  EndWhile
  WorkshopParent.UpdateCurrentDamage(workshopRef) ; #DEBUG_LINE_NO:505
EndFunction

Event OnDestructionStageChanged(Int aiOldStage, Int aiCurrentStage)
  If Self.IsDestroyed() ; #DEBUG_LINE_NO:511
    Self.HandleDestruction() ; #DEBUG_LINE_NO:512
  ElseIf aiCurrentStage == 0 ; #DEBUG_LINE_NO:513
    workshopscript workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:514
    Self.RecalculateResourceDamage(workshopRef, True) ; #DEBUG_LINE_NO:516
    WorkshopParent.SendDestructionStateChangedEvent(Self, workshopRef) ; #DEBUG_LINE_NO:518
  EndIf
EndEvent

Event OnPowerOn(ObjectReference akPowerGenerator)
  Self.HandlePowerStateChange(True) ; #DEBUG_LINE_NO:524
EndEvent

Event OnPowerOff()
  Self.HandlePowerStateChange(False) ; #DEBUG_LINE_NO:529
EndEvent

Function HandlePowerStateChange(Bool bPowerOn)
  If bPowerOn ; #DEBUG_LINE_NO:533
    If workshopID < 0 ; #DEBUG_LINE_NO:535
      Self.StartTimer(OnPowerOnTimerLength, OnPowerOnTimer) ; #DEBUG_LINE_NO:537
      Return  ; #DEBUG_LINE_NO:538
    EndIf
    OnPowerOnTimerCount = 0 ; #DEBUG_LINE_NO:542
  EndIf
  WorkshopParent.UpdateWorkshopRatingsForResourceObject(Self, WorkshopParent.GetWorkshop(workshopID), False, False) ; #DEBUG_LINE_NO:544
  workshopscript workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:547
  WorkshopParent.SendPowerStateChangedEvent(Self, workshopRef) ; #DEBUG_LINE_NO:548
EndFunction

Event OnActivate(ObjectReference akActionRef)
  If akActionRef == Game.GetPlayer() as ObjectReference ; #DEBUG_LINE_NO:564
    If Self.CanProduceForWorkshop() ; #DEBUG_LINE_NO:566
      If Self.HasKeyword(WorkshopParent.WorkshopRadioObject) ; #DEBUG_LINE_NO:567
        bRadioOn = !bRadioOn ; #DEBUG_LINE_NO:570
        WorkshopParent.UpdateRadioObject(Self) ; #DEBUG_LINE_NO:571
      EndIf
    EndIf
    If Self.IsBed() == False ; #DEBUG_LINE_NO:576
      WorkshopParent.PlayerComment(Self) ; #DEBUG_LINE_NO:577
    EndIf
  EndIf
  If Self.GetBaseObject() as Flora ; #DEBUG_LINE_NO:581
    Self.SetValue(WorkshopParent.WorkshopFloraHarvestTime, Utility.GetCurrentGameTime()) ; #DEBUG_LINE_NO:582
  EndIf
EndEvent

Function ActivatedByWorkshopActor(workshopnpcscript workshopNPC)
  If (workshopNPC as Bool && workshopNPC.IsDoingFavor()) && workshopNPC.IsInFaction(WorkshopParent.Followers.CurrentCompanionFaction) == False ; #DEBUG_LINE_NO:587
    If bAllowPlayerAssignment ; #DEBUG_LINE_NO:589
      workshopNPC.setDoingFavor(False, False) ; #DEBUG_LINE_NO:591
      workshopNPC.UnregisterForDistanceEvents(workshopNPC as ScriptObject, WorkshopParent.GetWorkshop(workshopID) as ScriptObject) ; #DEBUG_LINE_NO:593
      If Self.RequiresActor() || Self.IsBed() ; #DEBUG_LINE_NO:595
        workshopNPC.SayCustom(WorkshopParent.WorkshopParentAssignConfirmTopicType, None, False, None) ; #DEBUG_LINE_NO:596
        WorkshopParent.AssignActorToObjectPUBLIC(workshopNPC, Self, False) ; #DEBUG_LINE_NO:597
        WorkshopParent.WorkshopResourceAssignedMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:598
        workshopNPC.StartAssignmentTimer(True) ; #DEBUG_LINE_NO:599
        If Self.IsBed() == False ; #DEBUG_LINE_NO:601
          workshopscript workshopRef = WorkshopParent.GetWorkshop(workshopID) ; #DEBUG_LINE_NO:602
          workshopRef.RecalculateResources() ; #DEBUG_LINE_NO:603
        EndIf
      EndIf
      workshopNPC.EvaluatePackage(False) ; #DEBUG_LINE_NO:607
    Else
      WorkshopParent.WorkshopResourceNoAssignmentMessage.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:609
    EndIf
  EndIf
EndFunction

Bool Function ModifyResourceDamage(ActorValue akActorValue, Float aiDamageMod)
  Float totalDamage = 0.0 ; #DEBUG_LINE_NO:619
  Float baseValue = Self.GetBaseValue(akActorValue) ; #DEBUG_LINE_NO:620
  Bool returnVal = False ; #DEBUG_LINE_NO:621
  If baseValue > 0.0 ; #DEBUG_LINE_NO:623
    If aiDamageMod < 0.0 ; #DEBUG_LINE_NO:624
      If bAllowAutoRepair ; #DEBUG_LINE_NO:626
        Self.RestoreValue(akActorValue, aiDamageMod * -1.0) ; #DEBUG_LINE_NO:628
        returnVal = True ; #DEBUG_LINE_NO:629
      EndIf
    Else
      Float currentDamage = baseValue - Self.GetValue(akActorValue) ; #DEBUG_LINE_NO:633
      If currentDamage + aiDamageMod > baseValue ; #DEBUG_LINE_NO:637
        aiDamageMod -= currentDamage + aiDamageMod - baseValue ; #DEBUG_LINE_NO:639
      EndIf
      Self.DamageValue(akActorValue, aiDamageMod) ; #DEBUG_LINE_NO:642
      returnVal = True ; #DEBUG_LINE_NO:643
    EndIf
    totalDamage += baseValue - Self.GetValue(akActorValue) ; #DEBUG_LINE_NO:647
  EndIf
  Bool bDestroyed = totalDamage > 0.0 ; #DEBUG_LINE_NO:652
  If bDestroyed ; #DEBUG_LINE_NO:654
    If Self.IsDestroyed() == False ; #DEBUG_LINE_NO:655
      Self.SetDestroyed(True) ; #DEBUG_LINE_NO:657
      Self.DamageObject(9999.0) ; #DEBUG_LINE_NO:658
      Self.HandleDestruction() ; #DEBUG_LINE_NO:659
    EndIf
  Else
    Self.Repair() ; #DEBUG_LINE_NO:664
    Int I = 0 ; #DEBUG_LINE_NO:675
    While I < myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:676
      myFurnitureMarkerRefs[I].SetDestroyed(False) ; #DEBUG_LINE_NO:677
      I += 1 ; #DEBUG_LINE_NO:678
    EndWhile
    If myDamageHelperRef ; #DEBUG_LINE_NO:681
      myDamageHelperRef.ClearDestruction() ; #DEBUG_LINE_NO:682
    EndIf
  EndIf
  Return returnVal ; #DEBUG_LINE_NO:686
EndFunction

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
  Self.HideMarkers() ; #DEBUG_LINE_NO:692
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
  Self.UpdatePosition() ; #DEBUG_LINE_NO:697
EndEvent

Function UpdatePosition()
  Int I = 0 ; #DEBUG_LINE_NO:701
  Int size = myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:702
  While I < size ; #DEBUG_LINE_NO:703
    ObjectReference theMarker = myFurnitureMarkerRefs[I] ; #DEBUG_LINE_NO:704
    theMarker.Enable(False) ; #DEBUG_LINE_NO:707
    theMarker.MoveTo(Self as ObjectReference, 0.0, 0.0, 0.0, True) ; #DEBUG_LINE_NO:708
    If Self.HasNode(FurnitureMarkerNodes[I]) ; #DEBUG_LINE_NO:710
      theMarker.MoveToNode(Self as ObjectReference, FurnitureMarkerNodes[I], "") ; #DEBUG_LINE_NO:712
    EndIf
    theMarker.MoveToNearestNavmeshLocation() ; #DEBUG_LINE_NO:718
    I += 1 ; #DEBUG_LINE_NO:720
  EndWhile
  If myDamageHelperRef ; #DEBUG_LINE_NO:723
    myDamageHelperRef.MoveTo(Self as ObjectReference, 0.0, 0.0, 0.0, True) ; #DEBUG_LINE_NO:724
    myDamageHelperRef.Enable(False) ; #DEBUG_LINE_NO:726
  EndIf
EndFunction

Function HideMarkers()
  Int I = 0 ; #DEBUG_LINE_NO:731
  Int size = myFurnitureMarkerRefs.Length ; #DEBUG_LINE_NO:732
  While I < size ; #DEBUG_LINE_NO:733
    myFurnitureMarkerRefs[I].Disable(False) ; #DEBUG_LINE_NO:734
    I += 1 ; #DEBUG_LINE_NO:735
  EndWhile
  If myDamageHelperRef ; #DEBUG_LINE_NO:737
    myDamageHelperRef.Disable(False) ; #DEBUG_LINE_NO:738
  EndIf
EndFunction

Function HandleCreation(Bool bNewlyBuilt)
  If DamageHelper as Bool && !myDamageHelperRef ; #DEBUG_LINE_NO:745
    myDamageHelperRef = Self.PlaceAtMe(DamageHelper as Form, 1, False, False, True) ; #DEBUG_LINE_NO:746
    myDamageHelperRef.SetLinkedRef(Self as ObjectReference, None) ; #DEBUG_LINE_NO:748
  EndIf
  If bNewlyBuilt ; #DEBUG_LINE_NO:751
    If Self.GetBaseObject() as Flora ; #DEBUG_LINE_NO:753
      Self.SetHarvested(True) ; #DEBUG_LINE_NO:754
    EndIf
  EndIf
  If Self.HasOwner() == False && Self.IsBed() == False && bDefaultPlayerOwnership ; #DEBUG_LINE_NO:759
    Self.SetFactionOwner(WorkshopParent.PlayerFaction, False) ; #DEBUG_LINE_NO:761
  EndIf
EndFunction

Function HandleDeletion()
  If myFurnitureMarkerRefs.Length > 0 ; #DEBUG_LINE_NO:768
    Self.DeleteFurnitureMarkers() ; #DEBUG_LINE_NO:769
  EndIf
  If myDamageHelperRef ; #DEBUG_LINE_NO:771
    myDamageHelperRef.Delete() ; #DEBUG_LINE_NO:772
  EndIf
EndFunction

Function HandleWorkshopReset()
  Float harvestTime = Self.GetValue(WorkshopParent.WorkshopFloraHarvestTime) ; #DEBUG_LINE_NO:779
  If Self.GetBaseObject() as Flora ; #DEBUG_LINE_NO:780
    If Self.IsActorAssigned() && Utility.GetCurrentGameTime() > harvestTime + floraResetHarvestDays ; #DEBUG_LINE_NO:782
      Self.SetHarvested(False) ; #DEBUG_LINE_NO:783
    EndIf
  EndIf
EndFunction

Bool Function HasResourceValue(ActorValue akValue)
  If akValue as Bool && Self.GetBaseValue(akValue) > 0.0 ; #DEBUG_LINE_NO:789
    Return True ; #DEBUG_LINE_NO:790
  Else
    Return False ; #DEBUG_LINE_NO:792
  EndIf
EndFunction

Float Function GetResourceRating(ActorValue akValue)
  Return Self.GetValue(akValue) ; #DEBUG_LINE_NO:798
EndFunction

Bool Function HasResourceDamage()
  Int I = 0 ; #DEBUG_LINE_NO:803
  Float totalDamage = 0.0 ; #DEBUG_LINE_NO:804
  workshopdatascript:workshopactorvalue[] WorkshopResourceAVs = WorkshopParent.WorkshopResourceAVs ; #DEBUG_LINE_NO:807
  Int ArrayLength = WorkshopResourceAVs.Length ; #DEBUG_LINE_NO:808
  While I < WorkshopResourceAVs.Length && totalDamage == 0.0 ; #DEBUG_LINE_NO:809
    ActorValue testValue = WorkshopResourceAVs[I].resourceValue ; #DEBUG_LINE_NO:810
    Float damage = Self.GetBaseValue(testValue) - Self.GetValue(testValue) ; #DEBUG_LINE_NO:811
    totalDamage += damage ; #DEBUG_LINE_NO:812
    I += 1 ; #DEBUG_LINE_NO:813
  EndWhile
  Return totalDamage > 0.0 ; #DEBUG_LINE_NO:815
EndFunction

Function testGetResourceDamage(ActorValue akAV)
  Float damage = Self.GetResourceDamage(akAV) ; #DEBUG_LINE_NO:819
EndFunction
