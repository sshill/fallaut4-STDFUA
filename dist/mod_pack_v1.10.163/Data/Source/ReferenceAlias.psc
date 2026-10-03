ScriptName ReferenceAlias Extends Alias Native hidden

;-- Functions ---------------------------------------

Function ApplyToRef(ObjectReference akRef) Native

Function Clear() Native

Function ForceRefTo(ObjectReference akNewRef) Native

ObjectReference Function GetReference() Native

Event OnActivate(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnCellAttach()
  ; Empty function
EndEvent

Event OnCellDetach()
  ; Empty function
EndEvent

Event OnCellLoad()
  ; Empty function
EndEvent

Event OnClose(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)
  ; Empty function
EndEvent

Event OnCommandModeCompleteCommand(Int aeCommandType, ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnCommandModeEnter()
  ; Empty function
EndEvent

Event OnCommandModeExit()
  ; Empty function
EndEvent

Event OnCommandModeGiveCommand(Int aeCommandType, ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnCompanionDismiss()
  ; Empty function
EndEvent

Event OnConsciousnessStateChanged(Bool abUnconscious)
  ; Empty function
EndEvent

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
  ; Empty function
EndEvent

Event OnCripple(ActorValue akActorValue, Bool abCrippled)
  ; Empty function
EndEvent

Event OnDeath(Actor akKiller)
  ; Empty function
EndEvent

Event OnDeferredKill(Actor akKiller)
  ; Empty function
EndEvent

Event OnDestructionStageChanged(Int aiOldStage, Int aiCurrentStage)
  ; Empty function
EndEvent

Event OnDifficultyChanged(Int aOldDifficulty, Int aNewDifficulty)
  ; Empty function
EndEvent

Event OnDying(Actor akKiller)
  ; Empty function
EndEvent

Event OnEnterBleedout()
  ; Empty function
EndEvent

Event OnEnterSneaking()
  ; Empty function
EndEvent

Event OnEquipped(Actor akActor)
  ; Empty function
EndEvent

Event OnEscortWaitStart()
  ; Empty function
EndEvent

Event OnEscortWaitStop()
  ; Empty function
EndEvent

Event OnExitFurniture(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnGetUp(ObjectReference akFurniture)
  ; Empty function
EndEvent

Event OnGrab()
  ; Empty function
EndEvent

Event OnHolotapeChatter(String astrChatter, Float afNumericData)
  ; Empty function
EndEvent

Event OnHolotapePlay(ObjectReference aTerminalRef)
  ; Empty function
EndEvent

Event OnItemAdded(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
  ; Empty function
EndEvent

Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnItemRemoved(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
  ; Empty function
EndEvent

Event OnItemUnequipped(Form akBaseObject, ObjectReference akReference)
  ; Empty function
EndEvent

Event OnKill(Actor akVictim)
  ; Empty function
EndEvent

Event OnLoad()
  ; Empty function
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
  ; Empty function
EndEvent

Event OnLockStateChanged()
  ; Empty function
EndEvent

Event OnOpen(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnPackageChange(Package akOldPackage)
  ; Empty function
EndEvent

Event OnPackageEnd(Package akOldPackage)
  ; Empty function
EndEvent

Event OnPackageStart(Package akNewPackage)
  ; Empty function
EndEvent

Event OnPartialCripple(ActorValue akActorValue, Bool abCrippled)
  ; Empty function
EndEvent

Event OnPickpocketFailed()
  ; Empty function
EndEvent

Event OnPipboyRadioDetection(Bool abDetected)
  ; Empty function
EndEvent

Event OnPlayerCreateRobot(Actor akNewRobot)
  ; Empty function
EndEvent

Event OnPlayerDialogueTarget()
  ; Empty function
EndEvent

Event OnPlayerEnterVertibird(ObjectReference akVertibird)
  ; Empty function
EndEvent

Event OnPlayerFallLongDistance(Float afDamage)
  ; Empty function
EndEvent

Event OnPlayerFireWeapon(Form akBaseObject)
  ; Empty function
EndEvent

Event OnPlayerHealTeammate(Actor akTeammate)
  ; Empty function
EndEvent

Event OnPlayerLoadGame()
  ; Empty function
EndEvent

Event OnPlayerModArmorWeapon(Form akBaseObject, objectmod akModBaseObject)
  ; Empty function
EndEvent

Event OnPlayerModRobot(Actor akRobot, objectmod akModBaseObject)
  ; Empty function
EndEvent

Event OnPlayerSwimming()
  ; Empty function
EndEvent

Event OnPlayerUseWorkBench(ObjectReference akWorkBench)
  ; Empty function
EndEvent

Event OnPowerOff()
  ; Empty function
EndEvent

Event OnPowerOn(ObjectReference akPowerGenerator)
  ; Empty function
EndEvent

Event OnRaceSwitchComplete()
  ; Empty function
EndEvent

Event OnRead()
  ; Empty function
EndEvent

Event OnRelease()
  ; Empty function
EndEvent

Event OnReset()
  ; Empty function
EndEvent

Event OnSell(Actor akSeller)
  ; Empty function
EndEvent

Event OnSit(ObjectReference akFurniture)
  ; Empty function
EndEvent

Event OnSpeechChallengeAvailable(ObjectReference akSpeaker)
  ; Empty function
EndEvent

Event OnSpellCast(Form akSpell)
  ; Empty function
EndEvent

Event OnTranslationAlmostComplete()
  ; Empty function
EndEvent

Event OnTranslationComplete()
  ; Empty function
EndEvent

Event OnTranslationFailed()
  ; Empty function
EndEvent

Event OnTrapHitStart(ObjectReference akTarget, Float afXVel, Float afYVel, Float afZVel, Float afXPos, Float afYPos, Float afZPos, Int aeMaterial, Bool abInitialHit, Int aeMotionType)
  ; Empty function
EndEvent

Event OnTrapHitStop(ObjectReference akTarget)
  ; Empty function
EndEvent

Event OnTriggerEnter(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnTriggerLeave(ObjectReference akActionRef)
  ; Empty function
EndEvent

Event OnUnequipped(Actor akActor)
  ; Empty function
EndEvent

Event OnUnload()
  ; Empty function
EndEvent

Event OnWorkshopMode(Bool aStart)
  ; Empty function
EndEvent

Event OnWorkshopNPCTransfer(Location akNewWorkshop, Keyword akActionKW)
  ; Empty function
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akReference)
  ; Empty function
EndEvent

Event OnWorkshopObjectRepaired(ObjectReference akReference)
  ; Empty function
EndEvent

Function RemoveFromRef(ObjectReference akRef) Native

Bool Function ForceRefIfEmpty(ObjectReference akNewRef)
  If Self.GetReference() ; #DEBUG_LINE_NO:19
    Return False ; #DEBUG_LINE_NO:20
  Else
    Self.ForceRefTo(akNewRef) ; #DEBUG_LINE_NO:22
    Return True ; #DEBUG_LINE_NO:23
  EndIf
EndFunction

Actor Function GetActorReference()
  Return Self.GetReference() as Actor ; #DEBUG_LINE_NO:29
EndFunction

ObjectReference Function GetRef()
  Return Self.GetReference() ; #DEBUG_LINE_NO:34
EndFunction

Actor Function GetActorRef()
  Return Self.GetActorReference() ; #DEBUG_LINE_NO:39
EndFunction

Bool Function TryToAddToFaction(Faction FactionToAddTo)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:48
  If ActorRef ; #DEBUG_LINE_NO:50
    ActorRef.AddToFaction(FactionToAddTo) ; #DEBUG_LINE_NO:51
    Return True ; #DEBUG_LINE_NO:52
  EndIf
  Return False ; #DEBUG_LINE_NO:55
EndFunction

Bool Function TryToRemoveFromFaction(Faction FactionToRemoveFrom)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:60
  If ActorRef ; #DEBUG_LINE_NO:62
    ActorRef.RemoveFromFaction(FactionToRemoveFrom) ; #DEBUG_LINE_NO:63
    Return True ; #DEBUG_LINE_NO:64
  EndIf
  Return False ; #DEBUG_LINE_NO:67
EndFunction

Bool Function TryToStopCombat()
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:72
  If ActorRef ; #DEBUG_LINE_NO:74
    ActorRef.StopCombat() ; #DEBUG_LINE_NO:75
    Return True ; #DEBUG_LINE_NO:76
  EndIf
  Return False ; #DEBUG_LINE_NO:79
EndFunction

Bool Function TryToDisable()
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:84
  If Ref ; #DEBUG_LINE_NO:86
    Ref.Disable(False) ; #DEBUG_LINE_NO:87
    Return True ; #DEBUG_LINE_NO:88
  EndIf
  Return False ; #DEBUG_LINE_NO:91
EndFunction

Bool Function TryToDisableNoWait()
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:96
  If Ref ; #DEBUG_LINE_NO:98
    Ref.DisableNoWait(False) ; #DEBUG_LINE_NO:99
    Return True ; #DEBUG_LINE_NO:100
  EndIf
  Return False ; #DEBUG_LINE_NO:103
EndFunction

Bool Function TryToEnable()
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:108
  If Ref ; #DEBUG_LINE_NO:110
    Ref.Enable(False) ; #DEBUG_LINE_NO:111
    Return True ; #DEBUG_LINE_NO:112
  EndIf
  Return False ; #DEBUG_LINE_NO:115
EndFunction

Bool Function TryToEnableNoWait()
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:120
  If Ref ; #DEBUG_LINE_NO:122
    Ref.EnableNoWait(False) ; #DEBUG_LINE_NO:123
    Return True ; #DEBUG_LINE_NO:124
  EndIf
  Return False ; #DEBUG_LINE_NO:127
EndFunction

Bool Function TryToEvaluatePackage()
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:132
  If ActorRef ; #DEBUG_LINE_NO:134
    ActorRef.EvaluatePackage(False) ; #DEBUG_LINE_NO:135
    Return True ; #DEBUG_LINE_NO:136
  EndIf
  Return False ; #DEBUG_LINE_NO:139
EndFunction

Bool Function TryToKill()
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:144
  If ActorRef ; #DEBUG_LINE_NO:146
    ActorRef.Kill(None) ; #DEBUG_LINE_NO:147
    Return True ; #DEBUG_LINE_NO:148
  EndIf
  Return False ; #DEBUG_LINE_NO:151
EndFunction

Bool Function TryToMoveTo(ObjectReference RefToMoveTo)
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:156
  If Ref ; #DEBUG_LINE_NO:158
    Ref.MoveTo(RefToMoveTo, 0.0, 0.0, 0.0, True) ; #DEBUG_LINE_NO:159
    Return True ; #DEBUG_LINE_NO:160
  EndIf
  Return False ; #DEBUG_LINE_NO:163
EndFunction

Bool Function TryToReset()
  ObjectReference Ref = Self.GetReference() ; #DEBUG_LINE_NO:168
  If Ref ; #DEBUG_LINE_NO:170
    Ref.Reset(None) ; #DEBUG_LINE_NO:171
    Return True ; #DEBUG_LINE_NO:172
  EndIf
  Return False ; #DEBUG_LINE_NO:175
EndFunction

Bool Function TryToClear()
  If Self.GetReference() ; #DEBUG_LINE_NO:180
    Self.Clear() ; #DEBUG_LINE_NO:181
    Return True ; #DEBUG_LINE_NO:182
  EndIf
  Return False ; #DEBUG_LINE_NO:185
EndFunction

Float Function TryToGetActorValue(ActorValue ActorValueToGet)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:190
  If ActorRef ; #DEBUG_LINE_NO:192
    Return ActorRef.GetValue(ActorValueToGet) ; #DEBUG_LINE_NO:193
  EndIf
  Return 0.0 ; #DEBUG_LINE_NO:196
EndFunction

Float Function TryToGetValue(ActorValue akAV)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:202
  If ActorRef ; #DEBUG_LINE_NO:204
    Return ActorRef.GetValue(akAV) ; #DEBUG_LINE_NO:205
  EndIf
  Return 0.0 ; #DEBUG_LINE_NO:208
EndFunction

Bool Function TryToSetActorValue(ActorValue ValueToSet, Float afValue)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:215
  If ActorRef ; #DEBUG_LINE_NO:217
    ActorRef.SetValue(ValueToSet, afValue) ; #DEBUG_LINE_NO:218
    Return True ; #DEBUG_LINE_NO:219
  EndIf
  Return False ; #DEBUG_LINE_NO:222
EndFunction

Bool Function TryToSetValue(ActorValue akAV, Float afValue)
  Actor ActorRef = Self.GetActorReference() ; #DEBUG_LINE_NO:227
  If ActorRef ; #DEBUG_LINE_NO:229
    ActorRef.SetValue(akAV, afValue) ; #DEBUG_LINE_NO:230
    Return True ; #DEBUG_LINE_NO:231
  EndIf
  Return False ; #DEBUG_LINE_NO:234
EndFunction
