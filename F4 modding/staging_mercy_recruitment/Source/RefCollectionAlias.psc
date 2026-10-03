ScriptName RefCollectionAlias Extends Alias Native hidden

;-- Functions ---------------------------------------

Int Function Find(ObjectReference akFindRef) Native

ObjectReference Function GetAt(Int aiIndex) Native

Int Function GetCount() Native

Event OnActivate(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnCellAttach(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnCellDetach(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnCellLoad(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnClose(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnCombatStateChanged(ObjectReference akSenderRef, Actor akTarget, Int aeCombatState)
  ; Empty function
EndEvent

Event OnCommandModeCompleteCommand(ObjectReference akSenderRef, Int aeCommand, ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnCommandModeEnter(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnCommandModeExit(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnCommandModeGiveCommand(ObjectReference akSenderRef, Int aeCommand, ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnCompanionDismiss(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnConsciousnessStateChanged(ObjectReference akSenderRef, Bool abUnconscious)
  ; Empty function
EndEvent

Event OnContainerChanged(ObjectReference akSenderRef, ObjectReference akNewContainer, ObjectReference akOldContainer)
  ; Empty function
EndEvent

Event OnCripple(ObjectReference akSenderRef, ActorValue akActorValue, Bool abCrippled)
  ; Empty function
EndEvent

Event OnDeath(ObjectReference akSenderRef, Actor akKiller)
  ; Empty function
EndEvent

Event OnDeferredKill(ObjectReference akSenderRef, Actor akKiller)
  ; Empty function
EndEvent

Event OnDestructionStageChanged(ObjectReference akSenderRef, Int aiOldStage, Int aiCurrentStage)
  ; Empty function
EndEvent

Event OnDifficultyChanged(ObjectReference akSenderRef, Int aOldDifficulty, Int aNewDifficulty)
  ; Empty function
EndEvent

Event OnDying(ObjectReference akSenderRef, Actor akKiller)
  ; Empty function
EndEvent

Event OnEnterBleedout(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnEnterSneaking(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnEquipped(ObjectReference akSenderRef, Actor akActor)
  ; Empty function
EndEvent

Event OnEscortWaitStart(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnEscortWaitStop(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnExitFurniture(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnGetUp(ObjectReference akSenderRef, ObjectReference akFurniture)
  ; Empty function
EndEvent

Event OnGrab(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnHolotapeChatter(ObjectReference akSenderRef, String astrChatter, Float afNumericData)
  ; Empty function
EndEvent

Event OnHolotapePlay(ObjectReference akSenderRef, ObjectReference aTerminalRef)
  ; Empty function
EndEvent

Event OnItemAdded(ObjectReference akSenderRef, Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
  ; Empty function
EndEvent

Event OnItemEquipped(ObjectReference akSenderRef, Form akBaseObject, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnItemRemoved(ObjectReference akSenderRef, Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
  ; Empty function
EndEvent

Event OnItemUnequipped(ObjectReference akSenderRef, Form akBaseObject, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnKill(ObjectReference akSenderRef, Actor akVictim)
  ; Empty function
EndEvent

Event OnLoad(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnLocationChange(ObjectReference akSenderRef, Location akOldLoc, Location akNewLoc)
  ; Empty function
EndEvent

Event OnLockStateChanged(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnOpen(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnPackageChange(ObjectReference akSenderRef, Package akOldPackage)
  ; Empty function
EndEvent

Event OnPackageEnd(ObjectReference akSenderRef, Package akOldPackage)
  ; Empty function
EndEvent

Event OnPackageStart(ObjectReference akSenderRef, Package akNewPackage)
  ; Empty function
EndEvent

Event OnPartialCripple(ObjectReference akSenderRef, ActorValue akActorValue, Bool abCrippled)
  ; Empty function
EndEvent

Event OnPickpocketFailed(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnPipboyRadioDetection(ObjectReference akSenderRef, Bool abDetected)
  ; Empty function
EndEvent

Event OnPlayerCreateRobot(ObjectReference akSenderRef, Actor akNewRobot)
  ; Empty function
EndEvent

Event OnPlayerDialogueTarget(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnPlayerEnterVertibird(ObjectReference akSenderRef, ObjectReference akVertibird)
  ; Empty function
EndEvent

Event OnPlayerFallLongDistance(ObjectReference akSenderRef, Float afDamage)
  ; Empty function
EndEvent

Event OnPlayerFireWeapon(ObjectReference akSenderRef, Form akBaseObject)
  ; Empty function
EndEvent

Event OnPlayerHealTeammate(ObjectReference akSenderRef, Actor akTeammate)
  ; Empty function
EndEvent

Event OnPlayerLoadGame(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnPlayerModArmorWeapon(ObjectReference akSenderRef, Form akBaseObject, objectmod akModBaseObject)
  ; Empty function
EndEvent

Event OnPlayerModRobot(ObjectReference akSenderRef, Actor akRobot, objectmod akModBaseObject)
  ; Empty function
EndEvent

Event OnPlayerSwimming(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnPlayerUseWorkBench(ObjectReference akSenderRef, ObjectReference akWorkBench)
  ; Empty function
EndEvent

Event OnPowerOff(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnPowerOn(ObjectReference akSenderRef, ObjectReference akPowerGenerator)
  ; Empty function
EndEvent

Event OnRaceSwitchComplete(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnRead(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnRelease(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnReset(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnSell(ObjectReference akSenderRef, Actor akSeller)
  ; Empty function
EndEvent

Event OnSit(ObjectReference akSenderRef, ObjectReference akFurniture)
  ; Empty function
EndEvent

Event OnSpeechChallengeAvailable(ObjectReference akSenderRef, ObjectReference akSpeaker)
  ; Empty function
EndEvent

Event OnSpellCast(ObjectReference akSenderRef, Form akSpell)
  ; Empty function
EndEvent

Event OnTranslationAlmostComplete(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnTranslationComplete(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnTranslationFailed(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnTrapHitStart(ObjectReference akSenderRef, ObjectReference akTarget, Float afXVel, Float afYVel, Float afZVel, Float afXPos, Float afYPos, Float afZPos, Int aeMaterial, Bool abInitialHit, Int aeMotionType)
  ; Empty function
EndEvent

Event OnTrapHitStop(ObjectReference akSenderRef, ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnTriggerEnter(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnTriggerLeave(ObjectReference akSenderRef, ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnUnequipped(ObjectReference akSenderRef, Actor akActor)
  ; Empty function
EndEvent

Event OnUnload(ObjectReference akSenderRef)
  ; Empty function
EndEvent

Event OnWorkshopMode(ObjectReference akSenderRef, Bool aStart)
  ; Empty function
EndEvent

Event OnWorkshopNPCTransfer(ObjectReference akSenderRef, Location akNewWorkshop, Keyword akActionKW)
  ; Empty function
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akSenderRef, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectGrabbed(ObjectReference akSenderRef, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akSenderRef, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akSenderRef, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectRepaired(ObjectReference akSenderRef, ObjectReference akReference)
  ; Empty function
EndEvent

Function RemoveAll() Native

Function RemoveRef(ObjectReference akRemoveRef) Native

Function addRef(ObjectReference akNewRef) Native

Function AddToFaction(Faction akFaction)
  Int I = 0 ; #DEBUG_LINE_NO:7
  While I < Self.GetCount() ; #DEBUG_LINE_NO:8
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:9
    If theActor ; #DEBUG_LINE_NO:10
      theActor.AddToFaction(akFaction) ; #DEBUG_LINE_NO:11
    EndIf
    I += 1 ; #DEBUG_LINE_NO:13
  EndWhile
EndFunction

Function BlockActivation(Bool abBlocked, Bool abHideActivateText)
  Int I = 0 ; #DEBUG_LINE_NO:20
  While I < Self.GetCount() ; #DEBUG_LINE_NO:21
    ObjectReference theRef = Self.GetAt(I) ; #DEBUG_LINE_NO:22
    If theRef ; #DEBUG_LINE_NO:23
      theRef.BlockActivation(abBlocked, abHideActivateText) ; #DEBUG_LINE_NO:24
    EndIf
    I += 1 ; #DEBUG_LINE_NO:26
  EndWhile
EndFunction

Actor Function GetActorAt(Int aiIndex)
  Return Self.GetAt(aiIndex) as Actor ; #DEBUG_LINE_NO:33
EndFunction

ObjectReference Function GetFirstOwnedObject(Actor actorOwner)
  Int I = 0 ; #DEBUG_LINE_NO:39
  Int ownerIndex = -1 ; #DEBUG_LINE_NO:40
  While I < Self.GetCount() && ownerIndex == -1 ; #DEBUG_LINE_NO:41
    If actorOwner.IsOwner(Self.GetAt(I)) ; #DEBUG_LINE_NO:42
      ownerIndex = I ; #DEBUG_LINE_NO:43
    EndIf
    I += 1 ; #DEBUG_LINE_NO:45
  EndWhile
  If ownerIndex > -1 ; #DEBUG_LINE_NO:47
    Return Self.GetAt(ownerIndex) ; #DEBUG_LINE_NO:48
  Else
    Return None ; #DEBUG_LINE_NO:50
  EndIf
EndFunction

Function EnableAll(Bool bFadeIn)
  Int I = 0 ; #DEBUG_LINE_NO:57
  While I < Self.GetCount() ; #DEBUG_LINE_NO:58
    ObjectReference theRef = Self.GetAt(I) ; #DEBUG_LINE_NO:59
    If theRef ; #DEBUG_LINE_NO:60
      theRef.EnableNoWait(bFadeIn) ; #DEBUG_LINE_NO:61
    EndIf
    I += 1 ; #DEBUG_LINE_NO:63
  EndWhile
EndFunction

Function DisableAll(Bool bFadeOut)
  Int I = 0 ; #DEBUG_LINE_NO:70
  While I < Self.GetCount() ; #DEBUG_LINE_NO:71
    ObjectReference theRef = Self.GetAt(I) ; #DEBUG_LINE_NO:72
    If theRef ; #DEBUG_LINE_NO:73
      theRef.DisableNoWait(bFadeOut) ; #DEBUG_LINE_NO:74
    EndIf
    I += 1 ; #DEBUG_LINE_NO:76
  EndWhile
EndFunction

Function EvaluateAll()
  Int I = 0 ; #DEBUG_LINE_NO:84
  While I < Self.GetCount() ; #DEBUG_LINE_NO:85
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:86
    If theActor ; #DEBUG_LINE_NO:87
      theActor.EvaluatePackage(False) ; #DEBUG_LINE_NO:88
    EndIf
    I += 1 ; #DEBUG_LINE_NO:90
  EndWhile
EndFunction

Function MoveAllTo(ObjectReference akTarget)
  Int I = 0 ; #DEBUG_LINE_NO:97
  While I < Self.GetCount() ; #DEBUG_LINE_NO:98
    ObjectReference theRef = Self.GetAt(I) ; #DEBUG_LINE_NO:99
    If theRef ; #DEBUG_LINE_NO:100
      theRef.MoveTo(akTarget, 0.0, 0.0, 0.0, True) ; #DEBUG_LINE_NO:101
    EndIf
    I += 1 ; #DEBUG_LINE_NO:103
  EndWhile
EndFunction

Bool Function IsOwnedObjectInList(Actor actorOwner)
  Int I = 0 ; #DEBUG_LINE_NO:111
  Bool foundOwner = False ; #DEBUG_LINE_NO:112
  While I < Self.GetCount() && !foundOwner ; #DEBUG_LINE_NO:113
    If actorOwner.IsOwner(Self.GetAt(I)) ; #DEBUG_LINE_NO:114
      foundOwner = True ; #DEBUG_LINE_NO:115
    EndIf
    I += 1 ; #DEBUG_LINE_NO:118
  EndWhile
  Return foundOwner ; #DEBUG_LINE_NO:120
EndFunction

Function KillAll(Actor akKiller)
  Int I = 0 ; #DEBUG_LINE_NO:126
  While I < Self.GetCount() ; #DEBUG_LINE_NO:127
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:128
    If theActor ; #DEBUG_LINE_NO:129
      theActor.Kill(akKiller) ; #DEBUG_LINE_NO:130
    EndIf
    I += 1 ; #DEBUG_LINE_NO:132
  EndWhile
EndFunction

Function StartCombatAll(Actor akCombatTarget)
  Int I = 0 ; #DEBUG_LINE_NO:139
  While I < Self.GetCount() ; #DEBUG_LINE_NO:140
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:141
    If theActor ; #DEBUG_LINE_NO:142
      theActor.StartCombat(akCombatTarget, False) ; #DEBUG_LINE_NO:143
    EndIf
    I += 1 ; #DEBUG_LINE_NO:145
  EndWhile
EndFunction

Function RemoveFromFaction(Faction akFaction)
  Int I = 0 ; #DEBUG_LINE_NO:152
  While I < Self.GetCount() ; #DEBUG_LINE_NO:153
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:154
    If theActor ; #DEBUG_LINE_NO:155
      theActor.RemoveFromFaction(akFaction) ; #DEBUG_LINE_NO:156
    EndIf
    I += 1 ; #DEBUG_LINE_NO:158
  EndWhile
EndFunction

Function RemoveFromAllFactions()
  Int I = 0 ; #DEBUG_LINE_NO:165
  While I < Self.GetCount() ; #DEBUG_LINE_NO:166
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:167
    If theActor ; #DEBUG_LINE_NO:168
      theActor.RemoveFromAllFactions() ; #DEBUG_LINE_NO:169
    EndIf
    I += 1 ; #DEBUG_LINE_NO:171
  EndWhile
EndFunction

Function ResetAll()
  Int I = 0 ; #DEBUG_LINE_NO:178
  While I < Self.GetCount() ; #DEBUG_LINE_NO:179
    ObjectReference theRef = Self.GetAt(I) ; #DEBUG_LINE_NO:180
    If theRef ; #DEBUG_LINE_NO:181
      theRef.Reset(None) ; #DEBUG_LINE_NO:182
    EndIf
    I += 1 ; #DEBUG_LINE_NO:184
  EndWhile
EndFunction

Function SetProtected(Bool bSetProtected)
  Int I = 0 ; #DEBUG_LINE_NO:191
  While I < Self.GetCount() ; #DEBUG_LINE_NO:192
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:193
    If theActor ; #DEBUG_LINE_NO:194
      theActor.SetProtected(bSetProtected) ; #DEBUG_LINE_NO:195
    EndIf
    I += 1 ; #DEBUG_LINE_NO:197
  EndWhile
EndFunction

Function SetEssential(Bool bSetEssential)
  Int I = 0 ; #DEBUG_LINE_NO:204
  While I < Self.GetCount() ; #DEBUG_LINE_NO:205
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:206
    If theActor ; #DEBUG_LINE_NO:207
      theActor.SetEssential(bSetEssential) ; #DEBUG_LINE_NO:208
    EndIf
    I += 1 ; #DEBUG_LINE_NO:210
  EndWhile
EndFunction

Function AddRefCollection(RefCollectionAlias refCollectionAliasToAdd)
  Int CollectionCount = refCollectionAliasToAdd.GetCount() ; #DEBUG_LINE_NO:216
  Int index = 0 ; #DEBUG_LINE_NO:217
  While index < CollectionCount ; #DEBUG_LINE_NO:218
    Self.addRef(refCollectionAliasToAdd.GetAt(index)) ; #DEBUG_LINE_NO:219
    index += 1 ; #DEBUG_LINE_NO:220
  EndWhile
EndFunction

Function AddArray(ObjectReference[] refArrayToAdd)
  Int index = 0 ; #DEBUG_LINE_NO:227
  While index < refArrayToAdd.Length ; #DEBUG_LINE_NO:228
    Self.addRef(refArrayToAdd[index]) ; #DEBUG_LINE_NO:229
    index += 1 ; #DEBUG_LINE_NO:230
  EndWhile
EndFunction

Function SetValue(ActorValue akActorValue, Float fValue)
  Int I = 0 ; #DEBUG_LINE_NO:237
  While I < Self.GetCount() ; #DEBUG_LINE_NO:238
    Actor theActor = Self.GetActorAt(I) ; #DEBUG_LINE_NO:239
    If theActor ; #DEBUG_LINE_NO:240
      theActor.SetValue(akActorValue, fValue) ; #DEBUG_LINE_NO:241
    EndIf
    I += 1 ; #DEBUG_LINE_NO:243
  EndWhile
EndFunction

Bool Function LinkCollectionTo(RefCollectionAlias LinkedRefCollectionAlias, Keyword LinkKeyword, Bool WrapLinks)
  Int index = 0 ; #DEBUG_LINE_NO:251
  Int LinkTargetCount = LinkedRefCollectionAlias.GetCount() ; #DEBUG_LINE_NO:252
  Int CollectionCount = Self.GetCount() ; #DEBUG_LINE_NO:253
  While index < CollectionCount ; #DEBUG_LINE_NO:254
    ObjectReference currentRef = Self.GetAt(index) ; #DEBUG_LINE_NO:255
    If currentRef ; #DEBUG_LINE_NO:256
      currentRef.SetLinkedRef(LinkedRefCollectionAlias.GetAt(index % LinkTargetCount), LinkKeyword) ; #DEBUG_LINE_NO:257
    EndIf
    index += 1 ; #DEBUG_LINE_NO:259
    If !WrapLinks && index >= LinkTargetCount ; #DEBUG_LINE_NO:260
      Return False ; #DEBUG_LINE_NO:261
    EndIf
  EndWhile
  Return True ; #DEBUG_LINE_NO:264
EndFunction
