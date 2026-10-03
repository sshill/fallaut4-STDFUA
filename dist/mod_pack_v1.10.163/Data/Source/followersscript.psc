ScriptName FollowersScript Extends Quest conditional
{ Script for handling follower and companion systems:
FOLLOWERS, COMPANIONS, COMMANDS
LOITERING
COMPANION AFFINITY
SITUATION AWARENESS }

;-- Structs -----------------------------------------
Struct AffinityEventData
  Keyword EventKeyword
  { Keyword associated with this event. Used as the primary event identifier.
Filter: "CA_Event_*" }
  GlobalVariable EventSize
  { Global representing the size of the event.
Filter: "CA_Size_*" 
USUALLY: CA_Size_DialogueOnly for events that shouldn't change how the companion feels about the player. }
  GlobalVariable CoolDownDays
  { Global representing the cool down period for the event. Value in terms of GameDaysPassed.
Filter: "CA_CoolDownDays_*" }
  Keyword TopicSubType
  { Keyword TopicSubType. Dialogue to say when this event happens.
Filter: "CAT_*" }
  ActorValue AssociatedActorValue
  { USUALLY: NONE -- when in doubt leave this one blank.) 
The AssociatedActorValue. }
  Float NextDayAllowed
EndStruct

Struct CrippleEventDatum
  ActorValue LimbConditionActorValue
  Keyword AffinityKeyword_Companion
  Keyword AffinityKeyword_Player
EndStruct

Struct EncDefinition
  Keyword LocEncKeyword
  Faction Associated_Faction
  GlobalVariable LocEncGlobal
EndStruct

Struct LastCombatDefinition
  GlobalVariable SAC_Global
  Float SAC_Time
EndStruct

Struct SetDefinition
  Keyword LocSetKeyword
  GlobalVariable LocSetGlobal
EndStruct


;-- Variables ---------------------------------------
Actor[] AchievementCompanions
Float CompanionIdleChatterTimeMax = 300.0
Float CompanionIdleChatterTimeMin = 240.0
Float CurrentLoiterCoolDownTime
Bool DebugDropMarkers = False
Bool DebugTrace_Loitering = False
Bool DebugTrace_OnCombatStateChanged = False
Bool DebugTrace_OnHit = False
Bool DebugTrace_SA = True
Float FollowCommandLoiterCoolDownTime = 90.0
String HandlingOnHit = "HandlingOnHit"
Bool LockSendAffinityEvent
Int LoiterBufferSize = 10
Float LoiterRadius = 1500.0 Const
Float[] PlayerPosX
Float[] PlayerPosY
Float[] PlayerPosZ
Float SAC_LastCombat = -1.0
GlobalVariable SAC_LastCombat_Global
Float SAC_LastCombat_Timestamp
Float SAEClutter = -1.0 conditional
GlobalVariable SAEClutter_Global
ScriptObject SAEClutter_ScriptObject
Float SAEClutter_TimeStamp
Float SAECombatant = -1.0 conditional
GlobalVariable SAECombatant_Global
ScriptObject SAECombatant_ScriptObject
Float SAECombatant_TimeStamp
Float SAS = -1.0 conditional
GlobalVariable SAS_Global
ScriptObject SAS_ScriptObject
Float SAS_TimeStamp
Actor SleepCompanionActor
Float StandardLoiterCoolDownTime = 30.0
Float TimerInterval_LoiterSample = 1.0 Const
Float TimerInterval_SAC_LastCombat = 0.25 Const
Float TimerInterval_SAECombatantExpiry = 0.25 Const
ObjectReference[] debugMarkers
Int iTimerID_GameTime_SAC_LastCombat = 4 Const
Int iTimerID_GameTime_SAECombatantExpiry = 3 Const
Int iTimerID_LoiterSample = 1 Const
Actor playerRef

;-- Properties --------------------------------------
Group CommandLockHackProperties
  Keyword Property Followers_Command_LockPick_Allowed Auto Const
  { autofill - used to start the lockpick scene if you command an actor to inspect a locked door or container }
  Scene Property Command_LockPick_Scene Auto Const
  { autofill - scene used for commanded lock pick scenes }
  Keyword Property Followers_Command_HackTerminal_Allowed Auto Const
  { autofill - used to start the hack terminal  scene if you command an actor to inspect a locked terminal }
  Scene Property Command_HackTerminal_Scene Auto Const
  { autofill - scene used for commanded hack terminal scenes }
  ActorValue Property ValentineFailedToHack Auto Const
  Int Property CommandUnlockAttempts Auto conditional hidden
  Bool Property CommandUnlockSuccess Auto conditional hidden
  MiscObject Property BobbyPin Auto Const
  Sound Property NPCHumanLockpickingPickBreak Auto Const
  Sound Property NPCHumanLockpickingUnlock Auto Const
  Idle Property IdleLockPickingLowHeight Auto Const
  Idle Property IdleLockPickingMediumHeight Auto Const
  Idle Property IdleStop Auto Const
  Sound Property NPCHumanHackingPasswordBad Auto Const
  Sound Property NPCHumanHackingPasswordGood Auto Const
EndGroup

Group FollowerControl
  Message Property FollowersCompanionMenuMain Auto Const
  Message Property FollowersCompanionMenuTactics Auto Const
  Message Property FollowersCompanionMenuWait Auto Const
  Message Property FollowersCompanionMenuFollow Auto Const
  GlobalVariable Property iFollower_Com_Follow Auto Const
  GlobalVariable Property iFollower_Com_Wait Auto Const
  GlobalVariable Property iFollower_Com_GoHome Auto Const
  Topic Property FollowersSayCommandFollow Auto Const
  Topic Property FollowersSayCommandWait Auto Const
  Topic Property FollowersSayCommandGoHome Auto Const
  GlobalVariable Property iFollower_Dist_Near Auto Const
  GlobalVariable Property iFollower_Dist_Medium Auto Const
  GlobalVariable Property iFollower_Dist_Far Auto Const
  Topic Property FollowersSayCommandDistanceNear Auto Const
  Topic Property FollowersSayCommandDistanceMedium Auto Const
  Topic Property FollowersSayCommandDistanceFar Auto Const
  GlobalVariable Property iFollower_Stance_Aggressive Auto Const
  GlobalVariable Property iFollower_Stance_Defensive Auto Const
  Topic Property FollowersSayCommandStanceAggressive Auto Const
  Topic Property FollowersSayCommandStanceDefensive Auto Const
  Topic Property FollowersSayCommandTrade Auto Const
  Topic Property FollowersSayCommandFavor Auto Const
  GlobalVariable Property iFollower_Stance_CombatOverride_True Auto Const
  GlobalVariable Property iFollower_Stance_CombatOverride_False Auto Const
EndGroup

Group SceneData
  Keyword Property CIS_Companion_Scene_Start Auto Const
  { Keyword used to start Companion Interaction Scenes }
  GlobalVariable Property CIS_Type_EnterNewLocation Auto Const
  { AUTOFILL }
EndGroup

Group Affinity
  ActorValue Property CA_Affinity Auto Const
  ActorValue Property CA_CurrentThreshold Auto Const
  ActorValue Property CA_WantsToTalk Auto Const
  { Used for conditions on affinity scene greetings:
0 = doesn't want to talk
1 = wants to talk, will forcegreet player
2 = wants to talk, will not forcegreet playe }
  ActorValue Property CA_WantsToTalkRomanceRetry Auto Const
  GlobalVariable Property CA_DialogueBump_Dislike Auto Const
  GlobalVariable Property CA_DialogueBump_Hate Auto Const
  GlobalVariable Property CA_DialogueBump_Like Auto Const
  GlobalVariable Property CA_DialogueBump_Love Auto Const
  Keyword Property CAT_DialogueBump_Disliked Auto Const
  Keyword Property CAT_DialogueBump_Hated Auto Const
  Keyword Property CAT_DialogueBump_Liked Auto Const
  Keyword Property CAT_DialogueBump_Loved Auto Const
  ActorValue Property CA_AffinitySceneToPlay Auto Const
  ActorValue Property CA_Custom Auto Const
  ActorValue Property CA_HighestThreshold Auto Const
  ActorValue Property CA_LowestThreshold Auto Const
  ActorValue Property CA_LastChangePositive Auto Const
  ActorValue Property CA_HighestReached Auto Const
  ActorValue Property CA_LowestReached Auto Const
  ActorValue Property CA_MurderSessionCount Auto Const
  { how many murder sessions did the companion witness }
  ActorValue Property CA_MurderSessionDay Auto Const
  { The last murder session occured on this day (in terms of game days passed) }
  ActorValue Property CA_MurderSessionVictimCount Auto Const
  { The last murder sessions victim count - might be less than actual if people died in rapid succession }
  Location[] Property LocationsToIgnoreMurderIn Auto hidden
  { When it's okay to kill anyone in this location, add it to this list. For example, end game "attack XYZ faction" quests }
  ActorValue Property CA_IsRomantic Auto Const
  ActorValue Property CA_IsRomanceableNow Auto Const
  GlobalVariable Property SmallAffinityEvent Auto Const
  GlobalVariable Property NormalAffinityEvent Auto Const
  GlobalVariable Property LargeAffinityEvent Auto Const
  Spell Property SleepNearInfatuatedCompanionBonus Auto Const
  { The spell to cast on the player if he sleeps near a companion who is infatuated with him. }
  MagicEffect Property CA_AddictionEffect Auto Const
  followersscript:affinityeventdata[] Property AffinityEvents Auto
EndGroup

Group AffinityEventSending
{ Used by scripting to respond to game events. }
  Keyword Property AskedForMoreCapsKeyword Auto Const
  { CA__Event_SpeechForMoreCaps }
  Keyword Property GenerousKeyword Auto Const
  { CA__CustomEvent_Generous }
  Keyword Property SelfishKeyword Auto Const
  { CA__CustomEvent_Selfish }
  Keyword Property NiceKeyword Auto Const
  { CA__CustomEvent_Nice }
  Keyword Property MeanKeyword Auto Const
  { CA__CustomEvent_Mean }
  Keyword Property PeacefulKeyword Auto Const
  { CA__CustomEvent_Generous }
  Keyword Property ViolentKeyword Auto Const
  { CA__CustomEvent_Generous }
  Keyword Property AddictionKeyword Auto Const
  { CA_Event_ChemAddiction }
  Keyword Property DogmeatBleedoutKeyword Auto Const
  { CA_Event_DogmeatBleedout }
  Keyword Property VertibirdKeyword Auto Const
  { CA_Event_EnterVertibird{ }
  Keyword Property WorkbenchKeyword Auto Const
  { CA_Event_UseWorkbench{ }
  Keyword Property SwimmingKeyword Auto Const
  { CA_Event_Swim }
  Keyword Property RadiationKeyword Auto Const
  { CA_Event_RadDamage }
  Keyword Property ModArmorKeyword Auto Const
  { CA_Event_ModArmor }
  Keyword Property ModWeaponKeyword Auto Const
  { CA_Event_ModWeapon }
  followersscript:crippleeventdatum[] Property CrippleEventData Auto Const
  { Holds mapping between actor values and affinity event keyword }
  Keyword Property EnterPowerArmorKeyword Auto Const
  { CA_Event_EnterPowerArmor }
  Keyword Property isPowerArmorFrame Auto Const
  { Pointer to Power Armor Furniture keyword so Companion can comment when you get into it. }
  Keyword Property DischargeWeapon Auto Const
  { CA_Event_DischargeWeapon }
  Keyword Property JumpFromHeight Auto Const
  { CA_Event_JumpFromHeight }
  Keyword Property HealCompanion Auto Const
  { CA_Event_HealCompanion }
  Keyword Property HealDogmeat Auto Const
  { CA_Event_HealDogmeant }
EndGroup

Group SituationAwareness
  followersscript:setdefinition[] Property SetDefinitions Auto Const
  { Holds definitions for a Location Set - Keyword on locations and an associated Global used in dialogue conditions }
  followersscript:encdefinition[] Property EncDefinitions Auto Const
  { Holds definitions for a Location Encounter Type - keyword on locations, a faction associated with that keyword, and an associated Global used in dialogue conditions }
  FormList Property SA_CurrentSAEClutterTriggersList Auto Const
  { Autofill 
list of triggers the player is in 
see SAEClutterTriggerScript 
needed to make sure we know exactly which trigger box the player actually in, in cases where triggerboxes might over lap and player teeters in/out of them }
  FormList Property SA_CurrentSASTriggersList Auto Const
  { Autofill 
list of triggers the player is in 
see SASTriggerScript 
needed to make sure we know exactly which trigger box the player actually in, in cases where triggerboxes might over lap and player teeters in/out of them }
  followersscript:lastcombatdefinition[] Property LastCombatDefinitions Auto Const
  { Holds Globals that are human readable and associated floats which are in terms of GameDaysPassed
Globals named like: SAC_LastCombat_ShortTimeAgo | MediumTimeAgo | LongTimeAgo
Floats are in terms of GameDaysPassed (1 = 24 hours, 0.04166 = 1 hour)
Suggested values: Short: 0.0, Medium: 0.2, Long: 3.0

IMPORTANT: Arrange in ascending order of distance
Short time ago in index 0, very long time ago in last index
Note: first value is always treated as 0.0 }
EndGroup

Quest Property Tutorial Auto Const
Quest Property Achievements Auto Const
workshopparentscript Property WorkshopParent Auto
LocationAlias Property DismissMessageLocation Auto Const
Message Property FollowersCompanionDismissMessage Auto Const
Message Property FollowersDogmeatCompanionDismissMessage Auto Const
Message Property FollowersDogmeatCompanionDismissMessageNameUnknown Auto Const
GlobalVariable Property PlayerKnowsDogmeatName Auto Const
Keyword Property workshopItemKeyword Auto Const
ReferenceAlias Property Companion Auto Const
ReferenceAlias Property DogmeatCompanion Auto Const
RefCollectionAlias Property ActiveCompanions Auto Const
ReferenceAlias Property AvailableMessageActor Auto Const
Message Property FollowersCompanionAvailableMessage Auto Const
ReferenceAlias Property SleepCompanion Auto Const
ReferenceAlias Property SleepCompanionBed Auto Const
Keyword Property FollowersCompanionSleepNearPlayerFlag Auto Const
Faction Property CurrentCompanionFaction Auto Const
Faction Property HasBeenCompanionFaction Auto Const
Faction Property DisallowedCompanionFaction Auto Const
ReferenceAlias Property CommandActor Auto Const
ReferenceAlias Property CommandTarget Auto Const
GlobalVariable Property PlayerHasActiveCompanion Auto Const
GlobalVariable Property PlayerHasActiveDogmeatCompanion Auto Const
ReferenceAlias Property LastPlayerVertibird Auto Const
Int Property AllFollowerState = 1 Auto conditional hidden
Float Property CachedIdleChatterTimeMin Auto hidden
Float Property CachedIdleChatterTimeMax Auto hidden
Bool Property isPlayerLoitering Auto conditional hidden
Bool Property AutonomyAllowed = True Auto conditional hidden
ScriptObject[] Property AutonomyDisallowedByObjects Auto hidden

;-- Functions ---------------------------------------

Function TracePlayerFollowers() Global
  ; Empty function
EndFunction

Event OnInit()
  playerRef = Game.GetPlayer() ; #DEBUG_LINE_NO:56
  PlayerPosX = new Float[LoiterBufferSize] ; #DEBUG_LINE_NO:60
  PlayerPosY = new Float[LoiterBufferSize] ; #DEBUG_LINE_NO:61
  PlayerPosZ = new Float[LoiterBufferSize] ; #DEBUG_LINE_NO:62
  Self.InitializeLoiterBuffer() ; #DEBUG_LINE_NO:64
  Self.startTimer(TimerInterval_LoiterSample, iTimerID_LoiterSample) ; #DEBUG_LINE_NO:66
  AutonomyDisallowedByObjects = new ScriptObject[0] ; #DEBUG_LINE_NO:70
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnLocationChange") ; #DEBUG_LINE_NO:73
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnCombatStateChanged") ; #DEBUG_LINE_NO:74
  Self.RegisterForHitEvent(playerRef as ScriptObject, None, None, None, -1, -1, -1, -1, True) ; #DEBUG_LINE_NO:76
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerFireWeapon") ; #DEBUG_LINE_NO:79
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerFallLongDistance") ; #DEBUG_LINE_NO:80
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerHealTeammate") ; #DEBUG_LINE_NO:82
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnCripple") ; #DEBUG_LINE_NO:85
  Self.RegisterForRemoteEvent(Companion as ScriptObject, "OnCripple") ; #DEBUG_LINE_NO:86
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnItemEquipped") ; #DEBUG_LINE_NO:88
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerEnterVertibird") ; #DEBUG_LINE_NO:90
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerUseWorkBench") ; #DEBUG_LINE_NO:91
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerSwimming") ; #DEBUG_LINE_NO:92
  Self.RegisterForRadiationDamageEvent(playerRef as ScriptObject) ; #DEBUG_LINE_NO:93
  Self.RegisterForRemoteEvent(playerRef as ScriptObject, "OnPlayerModArmorWeapon") ; #DEBUG_LINE_NO:94
  Self.RegisterForRemoteEvent(DogmeatCompanion as ScriptObject, "OnEnterBleedout") ; #DEBUG_LINE_NO:96
  Self.RegisterForPlayerSleep() ; #DEBUG_LINE_NO:98
  Self.RegisterForRemoteEvent(Companion as ScriptObject, "OnCommandModeGiveCommand") ; #DEBUG_LINE_NO:101
  Self.RegisterForRemoteEvent(DogmeatCompanion as ScriptObject, "OnCommandModeGiveCommand") ; #DEBUG_LINE_NO:102
  Self.RegisterForRemoteEvent(DogmeatCompanion as ScriptObject, "OnCommandModeCompleteCommand") ; #DEBUG_LINE_NO:103
  Self.RegisterForMagicEffectApplyEvent(playerRef as ScriptObject, None, CA_AddictionEffect as Form, True) ; #DEBUG_LINE_NO:105
  Self.RegisterForPlayerTeleport() ; #DEBUG_LINE_NO:107
EndEvent

Event OnTimer(Int aiTimerID)
  If aiTimerID == iTimerID_LoiterSample ; #DEBUG_LINE_NO:128
    Self.HandleTimer_LoiterSample() ; #DEBUG_LINE_NO:129
  EndIf
EndEvent

Event OnTimerGameTime(Int aiTimerID)
  If aiTimerID == iTimerID_GameTime_SAECombatantExpiry ; #DEBUG_LINE_NO:134
    Self.HandleTimer_GameTime_SAECombatantExpiry() ; #DEBUG_LINE_NO:135
  ElseIf aiTimerID == iTimerID_GameTime_SAC_LastCombat ; #DEBUG_LINE_NO:137
    Self.Handletimer_GameTime_SAC_LastCombat() ; #DEBUG_LINE_NO:138
  EndIf
EndEvent

Event OnMagicEffectApply(ObjectReference akTarget, ObjectReference akCaster, MagicEffect akEffect)
  If (akTarget == playerRef as ObjectReference) && akEffect == CA_AddictionEffect ; #DEBUG_LINE_NO:154
    FollowersScript.SendAffinityEvent(Self as ScriptObject, AddictionKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:155
  EndIf
EndEvent

Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
  If akSender == playerRef ; #DEBUG_LINE_NO:162
    FollowersScript.StartCompanionInteractionScene(CIS_Type_EnterNewLocation, playerRef as ObjectReference, akNewLoc, None) ; #DEBUG_LINE_NO:164
    Self.SetSituationAwarenessBasedOnLocation(akNewLoc, True, False, akNewLoc as ScriptObject) ; #DEBUG_LINE_NO:165
  EndIf
EndEvent

Event OnHit(ObjectReference RemoteSource, ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked, String asMaterialName)
  Self.GoToState(HandlingOnHit) ; #DEBUG_LINE_NO:172
  If DebugTrace_OnHit
    
  EndIf
  Actor CompanionActor = Companion.GetActorReference() ; #DEBUG_LINE_NO:178
  If (RemoteSource == CompanionActor as ObjectReference) || (RemoteSource == playerRef as ObjectReference) ; #DEBUG_LINE_NO:180
    Self.HandleCombatMessageToSituationAwareness(akAggressor as Actor) ; #DEBUG_LINE_NO:181
  EndIf
  Self.GoToState("None") ; #DEBUG_LINE_NO:184
  Self.RegisterForHitEvent(playerRef as ScriptObject, None, None, None, -1, -1, -1, -1, True) ; #DEBUG_LINE_NO:187
  Self.RegisterForHitEvent(Companion as ScriptObject, None, None, None, -1, -1, -1, -1, True) ; #DEBUG_LINE_NO:188
EndEvent

Event Actor.OnCombatStateChanged(Actor RemoteSource, Actor akTarget, Int aeCombatState)
  If DebugTrace_OnCombatStateChanged
    
  EndIf
  Actor CompanionActor = Companion.GetActorReference() ; #DEBUG_LINE_NO:200
  If RemoteSource == CompanionActor || RemoteSource == playerRef ; #DEBUG_LINE_NO:202
    If akTarget ; #DEBUG_LINE_NO:203
      Self.HandleCombatMessageToSituationAwareness(akTarget) ; #DEBUG_LINE_NO:204
    EndIf
  EndIf
EndEvent

Event Actor.OnPlayerFireWeapon(Actor akSender, Form akBaseObject)
  Float radiusToLookForActors = 3000.0 ; #DEBUG_LINE_NO:213
  Location locToTest = akSender.GetCurrentLocation() ; #DEBUG_LINE_NO:221
  If (akBaseObject as Bool && akBaseObject.HasKeyword(Game.GetCommonProperties().WeaponTypeMelee1H) == False) && akBaseObject.HasKeyword(Game.GetCommonProperties().WeaponTypeMelee2H) == False && akBaseObject.HasKeyword(Game.GetCommonProperties().WeaponTypeUnarmed) == False ; #DEBUG_LINE_NO:223
    If locToTest.HasKeyword(Game.GetCommonProperties().LocTypeSettlement) || locToTest.HasKeyword(Game.GetCommonProperties().LocTypeWorkshopSettlement) ; #DEBUG_LINE_NO:225
      ObjectReference[] NPCs = akSender.FindAllReferencesWithKeyword(Game.GetCommonProperties().ActorTypeNPC as Form, radiusToLookForActors) ; #DEBUG_LINE_NO:228
      Bool AnyHostiles = commonarrayfunctions.IsActorInArrayHostileToActor(akSender, NPCs) ; #DEBUG_LINE_NO:230
      If AnyHostiles == False ; #DEBUG_LINE_NO:232
        FollowersScript.SendAffinityEvent(Self as ScriptObject, DischargeWeapon, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:235
      EndIf
    EndIf
  EndIf
EndEvent

Event Actor.OnPlayerFallLongDistance(Actor akSender, Float afDamage)
  FollowersScript.SendAffinityEvent(Self as ScriptObject, JumpFromHeight, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:248
EndEvent

Event Actor.OnPlayerHealTeammate(Actor akSender, Actor akTeammate)
  If akTeammate == Companion.GetActorReference() ; #DEBUG_LINE_NO:255
    FollowersScript.SendAffinityEvent(Self as ScriptObject, HealCompanion, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:256
  ElseIf akTeammate == DogmeatCompanion.GetActorReference() ; #DEBUG_LINE_NO:257
    FollowersScript.SendAffinityEvent(Self as ScriptObject, HealDogmeat, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:258
  EndIf
EndEvent

Event Actor.OnCripple(Actor akSender, ActorValue akActorValue, Bool abCrippled)
  Self.HandleOnCrippleEvent(akSender as Var, akActorValue, abCrippled) ; #DEBUG_LINE_NO:265
EndEvent

Event ReferenceAlias.OnCripple(ReferenceAlias akSender, ActorValue akActorValue, Bool abCrippled)
  Self.HandleOnCrippleEvent(akSender as Var, akActorValue, abCrippled) ; #DEBUG_LINE_NO:269
EndEvent

Event ReferenceAlias.OnEnterBleedout(ReferenceAlias akSender)
  If akSender == DogmeatCompanion ; #DEBUG_LINE_NO:273
    FollowersScript.SendAffinityEvent(Self as ScriptObject, DogmeatBleedoutKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:274
  EndIf
EndEvent

Event Actor.OnPlayerEnterVertibird(Actor askSender, ObjectReference akVertibird)
  LastPlayerVertibird.ForceRefTo(akVertibird) ; #DEBUG_LINE_NO:280
  Self.HandleVertibirdEvent(akVertibird) ; #DEBUG_LINE_NO:281
EndEvent

Event Actor.OnPlayerUseWorkBench(Actor akSender, ObjectReference akWorkBench)
  Self.HandleOnWorkbench(akWorkBench) ; #DEBUG_LINE_NO:286
EndEvent

Event Actor.OnPlayerSwimming(Actor akSender)
  Self.HandleOnSwimming(Game.GetPlayer().GetCurrentLocation()) ; #DEBUG_LINE_NO:292
EndEvent

Event OnRadiationDamage(ObjectReference akTarget, Bool abIngested)
  If Game.GetPlayer().IsInCombat() == False && abIngested == False ; #DEBUG_LINE_NO:299
    Self.HandleOnRadiation(akTarget.GetCurrentLocation()) ; #DEBUG_LINE_NO:300
  EndIf
  Self.RegisterForRadiationDamageEvent(playerRef as ScriptObject) ; #DEBUG_LINE_NO:303
EndEvent

Event Actor.OnPlayerModArmorWeapon(Actor akSender, Form akBaseObject, objectmod akModBaseObject)
  Self.HandleOnMod(akBaseObject) ; #DEBUG_LINE_NO:308
EndEvent

Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
  Self.HandleOnItemEquipped(akSender as ObjectReference, akBaseObject) ; #DEBUG_LINE_NO:315
EndEvent

Event OnPlayerSleepStart(Float afSleepStartTime, Float afDesiredSleepEndTime, ObjectReference akBed)
  Self.HandleOnSleepStart(akBed) ; #DEBUG_LINE_NO:320
EndEvent

Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
  Self.HandleOnSleepEnd() ; #DEBUG_LINE_NO:324
EndEvent

Event OnPlayerTeleport()
  Self.AllowAutonomyOnTeleport() ; #DEBUG_LINE_NO:329
EndEvent

Event ReferenceAlias.OnCommandModeGiveCommand(ReferenceAlias akSender, Int aeCommandType, ObjectReference akTarget)
  If akSender == Companion ; #DEBUG_LINE_NO:351
    If (akTarget.GetBaseObject() is Container || akTarget.GetBaseObject() is Door) && akTarget.IsLocked() && akSender.GetActorReference().HasKeyword(Followers_Command_LockPick_Allowed) ; #DEBUG_LINE_NO:353
      akSender.GetActorReference().EvaluatePackage(True) ; #DEBUG_LINE_NO:354
      Command_LockPick_Scene.stop() ; #DEBUG_LINE_NO:355
      CommandActor.ForceRefTo(akSender.GetReference()) ; #DEBUG_LINE_NO:356
      CommandTarget.ForceRefTo(akTarget) ; #DEBUG_LINE_NO:357
      Command_LockPick_Scene.start() ; #DEBUG_LINE_NO:358
    ElseIf akTarget.GetBaseObject() is terminal && akTarget.IsLocked() && akSender.GetActorReference().HasKeyword(Followers_Command_HackTerminal_Allowed) ; #DEBUG_LINE_NO:360
      akSender.GetActorReference().EvaluatePackage(True) ; #DEBUG_LINE_NO:361
      Command_HackTerminal_Scene.stop() ; #DEBUG_LINE_NO:362
      CommandActor.ForceRefTo(akSender.GetReference()) ; #DEBUG_LINE_NO:363
      CommandTarget.ForceRefTo(akTarget) ; #DEBUG_LINE_NO:364
      Command_HackTerminal_Scene.start() ; #DEBUG_LINE_NO:365
    EndIf
  ElseIf akSender == DogmeatCompanion && aeCommandType == 6 ; #DEBUG_LINE_NO:370
    dogmeatidles.BarkPlayful() ; #DEBUG_LINE_NO:371
    dogmeatidles.SetDogmeatAlert(180.0) ; #DEBUG_LINE_NO:372
  EndIf
EndEvent

Event ReferenceAlias.OnCommandModeCompleteCommand(ReferenceAlias akSender, Int aeCommandType, ObjectReference akTarget)
  If akSender == DogmeatCompanion && aeCommandType == 6 && !Game.GetPlayer().isSneaking() ; #DEBUG_LINE_NO:394
    dogmeatidles.BarkPlayful() ; #DEBUG_LINE_NO:397
    dogmeatidles.SetDogmeatPlayful(15.0) ; #DEBUG_LINE_NO:398
    dogmeatidles.FaceHappy(True) ; #DEBUG_LINE_NO:399
  EndIf
EndEvent

FollowersScript Function GetScript() Global
  Return (Game.GetFormFromFile(166372, "Fallout4.esm") as Quest) as FollowersScript ; #DEBUG_LINE_NO:412
EndFunction

Bool Function Trace(ScriptObject CallingObject, String asTextToPrint, Int aiSeverity) Global
  String logName = "Followers" ; #DEBUG_LINE_NO:417
  Debug.OpenUserLog(logName) ; #DEBUG_LINE_NO:418
  Return Debug.TraceUser(logName, (CallingObject as String + ": ") + asTextToPrint, aiSeverity) ; #DEBUG_LINE_NO:419
EndFunction

Bool Function TraceConditional(ScriptObject CallingObject, String asTextToPrint, Bool ShowTrace, Int aiSeverity) Global
  String logName = "Followers" ; #DEBUG_LINE_NO:426
  If ShowTrace ; #DEBUG_LINE_NO:428
    Debug.OpenUserLog(logName) ; #DEBUG_LINE_NO:429
    Return Debug.TraceUser(logName, (CallingObject as String + ": ") + asTextToPrint, aiSeverity) ; #DEBUG_LINE_NO:430
  Else
    Return False ; #DEBUG_LINE_NO:432
  EndIf
EndFunction

Function CommandUnlockStartNewAttempt()
  CommandUnlockSuccess = False ; #DEBUG_LINE_NO:526
  CommandUnlockAttempts = 0 ; #DEBUG_LINE_NO:527
EndFunction

Function CommandUnlockPlayAnim()
  Actor source = CommandActor.GetActorReference() ; #DEBUG_LINE_NO:532
  ObjectReference target = CommandTarget.GetReference() ; #DEBUG_LINE_NO:533
  If target.GetBaseObject() is Door ; #DEBUG_LINE_NO:536
    source.playidle(IdleLockPickingMediumHeight) ; #DEBUG_LINE_NO:537
  Else
    Float zOffset = target.Z - source.Z ; #DEBUG_LINE_NO:539
    If zOffset > 50.0 ; #DEBUG_LINE_NO:542
      source.playidle(IdleLockPickingMediumHeight) ; #DEBUG_LINE_NO:543
    Else
      source.playidle(IdleLockPickingLowHeight) ; #DEBUG_LINE_NO:545
    EndIf
  EndIf
EndFunction

Function CommandUnlockAttempt()
  ObjectReference source = CommandActor.GetReference() ; #DEBUG_LINE_NO:553
  ObjectReference target = CommandTarget.GetReference() ; #DEBUG_LINE_NO:554
  Int lockLevel = target.GetLockLevel() ; #DEBUG_LINE_NO:555
  Int roll = Utility.RandomInt(0, 110) ; #DEBUG_LINE_NO:558
  CommandUnlockSuccess = roll > lockLevel ; #DEBUG_LINE_NO:561
  If CommandUnlockSuccess ; #DEBUG_LINE_NO:565
    target.unlock(False) ; #DEBUG_LINE_NO:566
    If target.GetBaseObject() is terminal ; #DEBUG_LINE_NO:568
      NPCHumanHackingPasswordGood.play(source) ; #DEBUG_LINE_NO:569
    Else
      NPCHumanLockpickingUnlock.play(source) ; #DEBUG_LINE_NO:571
    EndIf
  ElseIf target.GetBaseObject() is terminal ; #DEBUG_LINE_NO:575
    NPCHumanHackingPasswordBad.play(source) ; #DEBUG_LINE_NO:576
  Else
    NPCHumanLockpickingPickBreak.play(source) ; #DEBUG_LINE_NO:578
    CommandActor.GetActorReference().RemoveItem(BobbyPin as Form, 1, False, None) ; #DEBUG_LINE_NO:579
  EndIf
  CommandUnlockAttempts += 1 ; #DEBUG_LINE_NO:584
EndFunction

Function CommandUnlockFailedHack()
  ObjectReference target = CommandTarget.GetReference() ; #DEBUG_LINE_NO:590
  target.setvalue(ValentineFailedToHack, 1.0) ; #DEBUG_LINE_NO:591
EndFunction

Bool Function IsCompanion(Actor ActorToCheck)
  Return Companion.GetActorReference() == ActorToCheck ; #DEBUG_LINE_NO:691
EndFunction

Bool Function IsPossibleCompanion(Actor ActorToCheck)
  Return (ActorToCheck as companionactorscript) as Bool ; #DEBUG_LINE_NO:695
EndFunction

Bool Function IsFollowing(Actor ActorToCheck)
  Return ActorToCheck.GetValue(Game.GetCommonProperties().FollowerState) == iFollower_Com_Follow.value ; #DEBUG_LINE_NO:699
EndFunction

Bool Function IsCompanionAndFollowing(Actor ActorToCheck)
  Return Self.IsCompanion(ActorToCheck) && Self.IsFollowing(ActorToCheck) ; #DEBUG_LINE_NO:703
EndFunction

Function SendCompanionChangeEvent(Actor ActorThatChanged, Bool IsNowCompanion)
  Var[] args = new Var[2] ; #DEBUG_LINE_NO:715
  args[0] = ActorThatChanged as Var ; #DEBUG_LINE_NO:717
  args[1] = IsNowCompanion as Var ; #DEBUG_LINE_NO:718
  Self.sendCustomEvent("followersscript_CompanionChange", args) ; #DEBUG_LINE_NO:722
EndFunction

Function SetAvailableToBeCompanion(Actor ActorToMakeAvailable)
  ActorToMakeAvailable.AddToFaction(HasBeenCompanionFaction) ; #DEBUG_LINE_NO:726
  If ActorToMakeAvailable.IsInFaction(CurrentCompanionFaction) == False ; #DEBUG_LINE_NO:728
    AvailableMessageActor.ForceRefTo(ActorToMakeAvailable as ObjectReference) ; #DEBUG_LINE_NO:729
    FollowersCompanionAvailableMessage.show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:730
  EndIf
EndFunction

Function ManageAchievementCompanions(Actor CompanionActor)
  If AchievementCompanions == None ; #DEBUG_LINE_NO:751
    AchievementCompanions = new Actor[0] ; #DEBUG_LINE_NO:752
  EndIf
  If AchievementCompanions.find(CompanionActor, 0) < 0 ; #DEBUG_LINE_NO:755
    AchievementCompanions.add(CompanionActor, 1) ; #DEBUG_LINE_NO:756
    Achievements.setStage(320) ; #DEBUG_LINE_NO:757
  EndIf
EndFunction

Function SetCompanion(Actor ActorToMakeCompanion, Bool SetCompanion, Bool FillCompanionAlias, Bool SuppressDismissMessage)
  If !Tutorial.getStageDone(600) ; #DEBUG_LINE_NO:763
    Tutorial.setStage(600) ; #DEBUG_LINE_NO:764
  EndIf
  Actor CurrentCompanionActor = Companion.GetActorReference() ; #DEBUG_LINE_NO:767
  If SetCompanion == False ; #DEBUG_LINE_NO:769
    If CurrentCompanionActor == ActorToMakeCompanion ; #DEBUG_LINE_NO:770
      Self.DismissCompanion(ActorToMakeCompanion, True, SuppressDismissMessage) ; #DEBUG_LINE_NO:771
    EndIf
    Return  ; #DEBUG_LINE_NO:774
  EndIf
  Self.DismissDogmeatCompanion(True, False) ; #DEBUG_LINE_NO:778
  If FillCompanionAlias ; #DEBUG_LINE_NO:780
    If CurrentCompanionActor as Bool && ActorToMakeCompanion.IsInFaction(CurrentCompanionFaction) == False ; #DEBUG_LINE_NO:783
      Self.DismissCompanion(Companion.GetActorReference(), True, False) ; #DEBUG_LINE_NO:784
    EndIf
    Companion.ForceRefTo(ActorToMakeCompanion as ObjectReference) ; #DEBUG_LINE_NO:787
    If ActiveCompanions.find(ActorToMakeCompanion as ObjectReference) < 0 ; #DEBUG_LINE_NO:790
      ActiveCompanions.addRef(ActorToMakeCompanion as ObjectReference) ; #DEBUG_LINE_NO:791
    EndIf
  EndIf
  Self.CompanionDataToggle(True, True, True, True) ; #DEBUG_LINE_NO:796
  Self.ManageAchievementCompanions(ActorToMakeCompanion) ; #DEBUG_LINE_NO:799
  ActorToMakeCompanion.AddToFaction(HasBeenCompanionFaction) ; #DEBUG_LINE_NO:801
  Self.FollowerFollow(ActorToMakeCompanion) ; #DEBUG_LINE_NO:803
  Self.FollowerSetDistanceMedium(ActorToMakeCompanion) ; #DEBUG_LINE_NO:804
  Self.RegisterForHitEvent(playerRef as ScriptObject, None, None, None, -1, -1, -1, -1, True) ; #DEBUG_LINE_NO:807
  Self.SendCompanionChangeEvent(ActorToMakeCompanion, True) ; #DEBUG_LINE_NO:809
  PlayerHasActiveCompanion.setvalue(1.0) ; #DEBUG_LINE_NO:811
  companionactorscript CompanionActor = ActorToMakeCompanion as companionactorscript ; #DEBUG_LINE_NO:813
  If CompanionActor.ShouldGivePlayerItems ; #DEBUG_LINE_NO:814
    CompanionActor.StartHasItemTimer() ; #DEBUG_LINE_NO:815
  EndIf
EndFunction

Function DismissCompanion(Actor CompanionToDismiss, Bool ShowLocationAssignmentListIfAvailable, Bool SuppressDismissMessage)
  companionactorscript CAS = Companion.GetActorReference() as companionactorscript ; #DEBUG_LINE_NO:825
  If CAS as Actor == CompanionToDismiss ; #DEBUG_LINE_NO:827
    If SuppressDismissMessage == False ; #DEBUG_LINE_NO:829
      Location WorkshopHome = None ; #DEBUG_LINE_NO:834
      If ShowLocationAssignmentListIfAvailable ; #DEBUG_LINE_NO:836
        If CAS.AllowDismissToSettlements == None && WorkshopParent.PlayerOwnsAWorkshop || (CAS.AllowDismissToSettlements as Bool && CAS.AllowDismissToSettlements.GetValue() > 0.0) ; #DEBUG_LINE_NO:838
          If CAS.DismissCompanionSettlementKeywordList ; #DEBUG_LINE_NO:839
            Location previousLocation = None ; #DEBUG_LINE_NO:843
            Int previousWorkshopID = (CompanionToDismiss as workshopnpcscript).GetWorkshopID() ; #DEBUG_LINE_NO:844
            If previousWorkshopID > -1 ; #DEBUG_LINE_NO:845
              workshopscript previousWorkshop = WorkshopParent.GetWorkshop(previousWorkshopID) ; #DEBUG_LINE_NO:846
              If previousWorkshop ; #DEBUG_LINE_NO:847
                previousLocation = previousWorkshop.myLocation ; #DEBUG_LINE_NO:848
              EndIf
            EndIf
            WorkshopHome = CompanionToDismiss.OpenWorkshopSettlementMenuEx(WorkshopParent.WorkshopAssignHomePermanentActor, None, previousLocation, CAS.DismissCompanionSettlementKeywordList, None, False, True, False, False, False) ; #DEBUG_LINE_NO:851
          Else
            WorkshopHome = WorkshopParent.AddPermanentActorToWorkshopPlayerChoice(Companion.GetActorReference(), True) ; #DEBUG_LINE_NO:854
          EndIf
        EndIf
      EndIf
      If WorkshopHome == None ; #DEBUG_LINE_NO:861
        WorkshopHome = (CompanionToDismiss.GetLinkedRef(workshopItemKeyword) as workshopscript).myLocation ; #DEBUG_LINE_NO:862
      EndIf
      If WorkshopHome ; #DEBUG_LINE_NO:866
        CAS.HomeLocation = WorkshopHome ; #DEBUG_LINE_NO:867
      EndIf
      DismissMessageLocation.ForceLocationTo(CAS.HomeLocation) ; #DEBUG_LINE_NO:870
      FollowersCompanionDismissMessage.show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:871
    EndIf
    Self.ClearCompanion() ; #DEBUG_LINE_NO:876
  EndIf
EndFunction

Function DismissDogmeatCompanion(Bool ShowLocationAssignmentListIfAvailable, Bool SuppressDismissMessage)
  dogmeatactorscript DAS = DogmeatCompanion.GetActorReference() as dogmeatactorscript ; #DEBUG_LINE_NO:888
  If DAS ; #DEBUG_LINE_NO:895
    If SuppressDismissMessage == False ; #DEBUG_LINE_NO:897
      Location WorkshopHome = None ; #DEBUG_LINE_NO:899
      If ShowLocationAssignmentListIfAvailable && WorkshopParent.PlayerOwnsAWorkshop ; #DEBUG_LINE_NO:901
        WorkshopHome = WorkshopParent.AddPermanentActorToWorkshopPlayerChoice(DAS as Actor, False) ; #DEBUG_LINE_NO:902
      EndIf
      If WorkshopHome == None ; #DEBUG_LINE_NO:908
        WorkshopHome = (DAS.GetLinkedRef(workshopItemKeyword) as workshopscript).myLocation ; #DEBUG_LINE_NO:909
      EndIf
      If WorkshopHome ; #DEBUG_LINE_NO:912
        DAS.HomeLocation = WorkshopHome ; #DEBUG_LINE_NO:913
      EndIf
      DismissMessageLocation.ForceLocationTo(DAS.HomeLocation) ; #DEBUG_LINE_NO:916
      If PlayerKnowsDogmeatName.GetValue() == 1.0 ; #DEBUG_LINE_NO:919
        FollowersDogmeatCompanionDismissMessage.show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:920
      Else
        FollowersDogmeatCompanionDismissMessageNameUnknown.show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0) ; #DEBUG_LINE_NO:922
      EndIf
    EndIf
    Self.ClearDogmeatCompanion() ; #DEBUG_LINE_NO:927
  EndIf
EndFunction

Function SetDogmeatCompanion(Actor DogmeatRef)
  If !Tutorial.getStageDone(602) ; #DEBUG_LINE_NO:939
    Tutorial.setStage(602) ; #DEBUG_LINE_NO:940
  EndIf
  If DogmeatRef.GetRace() != Game.GetCommonProperties().DogmeatRace ; #DEBUG_LINE_NO:943
    DogmeatRef = None ; #DEBUG_LINE_NO:945
  EndIf
  If DogmeatRef == None ; #DEBUG_LINE_NO:948
    DogmeatRef = Game.GetCommonProperties().DogmeatRef ; #DEBUG_LINE_NO:949
  EndIf
  Actor CompanionActor = Companion.GetActorReference() ; #DEBUG_LINE_NO:954
  If CompanionActor ; #DEBUG_LINE_NO:955
    Self.DismissCompanion(CompanionActor, True, False) ; #DEBUG_LINE_NO:956
  EndIf
  Self.ManageAchievementCompanions(DogmeatRef) ; #DEBUG_LINE_NO:960
  DogmeatCompanion.ForceRefTo(DogmeatRef as ObjectReference) ; #DEBUG_LINE_NO:962
  DogmeatRef.IgnoreFriendlyHits(True) ; #DEBUG_LINE_NO:964
  DogmeatRef.SetPlayerTeammate(True, True, True) ; #DEBUG_LINE_NO:965
  DogmeatRef.AddToFaction(HasBeenCompanionFaction) ; #DEBUG_LINE_NO:968
  Self.FollowerFollow(DogmeatRef) ; #DEBUG_LINE_NO:970
  Self.FollowerSetDistanceMedium(DogmeatRef) ; #DEBUG_LINE_NO:971
  aoscript.GetScript().DogmeatLoading(True) ; #DEBUG_LINE_NO:974
  Self.SendCompanionChangeEvent(DogmeatRef, True) ; #DEBUG_LINE_NO:977
  PlayerHasActiveDogmeatCompanion.setvalue(1.0) ; #DEBUG_LINE_NO:979
EndFunction

Function ClearCompanion()
  Actor actorToClear = Companion.GetActorReference() ; #DEBUG_LINE_NO:987
  If actorToClear ; #DEBUG_LINE_NO:991
    Self.CompanionDataToggle(False, False, True, True) ; #DEBUG_LINE_NO:992
    actorToClear.StopCombatAlarm() ; #DEBUG_LINE_NO:994
    Companion.Clear() ; #DEBUG_LINE_NO:996
    Self.SendCompanionChangeEvent(actorToClear, False) ; #DEBUG_LINE_NO:998
    PlayerHasActiveCompanion.setvalue(0.0) ; #DEBUG_LINE_NO:1000
  EndIf
EndFunction

Function DisallowCompanion(Actor ActorToDisallow, Bool SuppressDismissMessage)
  ActorToDisallow.AddToFaction(DisallowedCompanionFaction) ; #DEBUG_LINE_NO:1012
  If ActorToDisallow.GetRace() == Game.GetCommonProperties().DogmeatRace ; #DEBUG_LINE_NO:1014
    Self.DismissDogmeatCompanion(True, SuppressDismissMessage) ; #DEBUG_LINE_NO:1015
  Else
    Self.DismissCompanion(ActorToDisallow, True, SuppressDismissMessage) ; #DEBUG_LINE_NO:1017
  EndIf
EndFunction

Function AllowCompanion(Actor ActorToAllow, Bool MakeCompanionIfNoneCurrently, Bool ForceCompanion)
  ActorToAllow.RemoveFromFaction(DisallowedCompanionFaction) ; #DEBUG_LINE_NO:1026
  If PlayerHasActiveCompanion.GetValue() == 0.0 && PlayerHasActiveDogmeatCompanion.GetValue() == 0.0 && MakeCompanionIfNoneCurrently || ForceCompanion ; #DEBUG_LINE_NO:1027
    If ActorToAllow.GetRace() == Game.GetCommonProperties().DogmeatRace ; #DEBUG_LINE_NO:1029
      Self.SetDogmeatCompanion(ActorToAllow) ; #DEBUG_LINE_NO:1030
    Else
      Self.SetCompanion(ActorToAllow, True, True, False) ; #DEBUG_LINE_NO:1032
    EndIf
  EndIf
EndFunction

Function ClearDogmeatCompanion()
  Actor actorToClear = DogmeatCompanion.GetActorReference() ; #DEBUG_LINE_NO:1042
  If actorToClear ; #DEBUG_LINE_NO:1046
    actorToClear.IgnoreFriendlyHits(False) ; #DEBUG_LINE_NO:1047
    actorToClear.SetPlayerTeammate(False, True, False) ; #DEBUG_LINE_NO:1048
    DogmeatCompanion.Clear() ; #DEBUG_LINE_NO:1050
    Self.SendCompanionChangeEvent(actorToClear, False) ; #DEBUG_LINE_NO:1052
    PlayerHasActiveDogmeatCompanion.setvalue(0.0) ; #DEBUG_LINE_NO:1054
  EndIf
EndFunction

Function CompanionDataToggle(Bool toggleOn, Bool canDoFavor, Bool givePlayerXP, Bool SetNotShowOnStealthMeter)
  companionactorscript CompanionActor = Companion.GetActorReference() as companionactorscript ; #DEBUG_LINE_NO:1063
  CompanionActor.IgnoreFriendlyHits(toggleOn) ; #DEBUG_LINE_NO:1065
  CompanionActor.SetPlayerTeammate(toggleOn, canDoFavor, givePlayerXP) ; #DEBUG_LINE_NO:1066
  ActorValue IdleChatterTimeMin = Game.GetCommonProperties().IdleChatterTimeMin ; #DEBUG_LINE_NO:1071
  ActorValue IdleChatterTimeMax = Game.GetCommonProperties().IdleChatterTimeMax ; #DEBUG_LINE_NO:1072
  If toggleOn ; #DEBUG_LINE_NO:1075
    If SetNotShowOnStealthMeter ; #DEBUG_LINE_NO:1076
      CompanionActor.SetNotShowOnStealthMeter(True) ; #DEBUG_LINE_NO:1077
    EndIf
    CachedIdleChatterTimeMin = CompanionActor.GetValue(IdleChatterTimeMin) ; #DEBUG_LINE_NO:1082
    CachedIdleChatterTimeMax = CompanionActor.GetValue(IdleChatterTimeMax) ; #DEBUG_LINE_NO:1083
    CompanionActor.setvalue(IdleChatterTimeMin, CompanionIdleChatterTimeMin) ; #DEBUG_LINE_NO:1084
    CompanionActor.setvalue(IdleChatterTimeMax, CompanionIdleChatterTimeMax) ; #DEBUG_LINE_NO:1085
    Int I = 0 ; #DEBUG_LINE_NO:1091
    While I < CompanionActor.KeywordsToAddWhileCurrentCompanion.Length ; #DEBUG_LINE_NO:1092
      CompanionActor.AddKeyword(CompanionActor.KeywordsToAddWhileCurrentCompanion[I]) ; #DEBUG_LINE_NO:1093
      I += 1 ; #DEBUG_LINE_NO:1094
    EndWhile
    Self.RegisterForHitEvent(Companion as ScriptObject, None, None, None, -1, -1, -1, -1, True) ; #DEBUG_LINE_NO:1097
    Self.RegisterForRemoteEvent(CompanionActor as ScriptObject, "OnCombatStateChanged") ; #DEBUG_LINE_NO:1098
  Else
    CompanionActor.SetNotShowOnStealthMeter(False) ; #DEBUG_LINE_NO:1100
    CompanionActor.setvalue(IdleChatterTimeMin, CachedIdleChatterTimeMin) ; #DEBUG_LINE_NO:1103
    CompanionActor.setvalue(IdleChatterTimeMax, CachedIdleChatterTimeMax) ; #DEBUG_LINE_NO:1104
    Int i = 0 ; #DEBUG_LINE_NO:1107
    While i < CompanionActor.KeywordsToAddWhileCurrentCompanion.Length ; #DEBUG_LINE_NO:1108
      CompanionActor.RemoveKeyword(CompanionActor.KeywordsToAddWhileCurrentCompanion[i]) ; #DEBUG_LINE_NO:1109
      i += 1 ; #DEBUG_LINE_NO:1110
    EndWhile
    Self.UnregisterForAllHitEvents(Companion as ScriptObject) ; #DEBUG_LINE_NO:1113
    Self.UnRegisterForRemoteEvent(CompanionActor as ScriptObject, "OnCombatStateChanged") ; #DEBUG_LINE_NO:1114
  EndIf
EndFunction

Function TryToTeleportCompanion(ObjectReference TeleportDestinationRef, Bool ShouldPlayTeleportInEffect, Bool ShouldPlayTeleportOutEffect)
  Actor CompanionActor = Companion.GetActorReference() ; #DEBUG_LINE_NO:1122
  If CompanionActor ; #DEBUG_LINE_NO:1124
    Self.TeleportActor(CompanionActor, TeleportDestinationRef, ShouldPlayTeleportInEffect, ShouldPlayTeleportOutEffect) ; #DEBUG_LINE_NO:1125
  EndIf
EndFunction

Function TryToTeleportDogmeat(ObjectReference TeleportDestinationRef, Bool ShouldPlayTeleportInEffect, Bool ShouldPlayTeleportOutEffect)
  Actor DogmeatActor = DogmeatCompanion.GetActorReference() ; #DEBUG_LINE_NO:1132
  If DogmeatActor ; #DEBUG_LINE_NO:1134
    Self.TeleportActor(DogmeatActor, TeleportDestinationRef, ShouldPlayTeleportInEffect, ShouldPlayTeleportOutEffect) ; #DEBUG_LINE_NO:1135
  EndIf
EndFunction

Function TeleportActor(Actor ActorToTeleport, ObjectReference TeleportDestinationRef, Bool ShouldPlayTeleportInEffect, Bool ShouldPlayTeleportOutEffect)
  teleportactorscript TeleportActor = ActorToTeleport as teleportactorscript ; #DEBUG_LINE_NO:1143
  If ShouldPlayTeleportOutEffect ; #DEBUG_LINE_NO:1145
    If TeleportActor ; #DEBUG_LINE_NO:1146
      TeleportActor.TeleportIn() ; #DEBUG_LINE_NO:1147
    EndIf
  EndIf
  Utility.wait(5.0) ; #DEBUG_LINE_NO:1153
  TeleportActor.MoveTo(TeleportDestinationRef, 0.0, 0.0, 0.0, True) ; #DEBUG_LINE_NO:1156
  If ShouldPlayTeleportInEffect ; #DEBUG_LINE_NO:1159
    If TeleportActor ; #DEBUG_LINE_NO:1160
      TeleportActor.TeleportIn() ; #DEBUG_LINE_NO:1161
    EndIf
  EndIf
EndFunction

Function FollowerWait(Actor Follower)
  Self.SetFollowerActorValue(Follower, Game.GetCommonProperties().FollowerState, iFollower_Com_Wait) ; #DEBUG_LINE_NO:1176
EndFunction

Function FollowerFollow(Actor Follower)
  Self.SetFollowerActorValue(Follower, Game.GetCommonProperties().FollowerState, iFollower_Com_Follow) ; #DEBUG_LINE_NO:1180
EndFunction

Function FollowerSetDistanceNear(Actor Follower)
  Self.SetFollowerActorValue(Follower, Game.GetCommonProperties().FollowerDistance, iFollower_Dist_Near) ; #DEBUG_LINE_NO:1184
EndFunction

Function FollowerSetDistanceMedium(Actor Follower)
  Self.SetFollowerActorValue(Follower, Game.GetCommonProperties().FollowerDistance, iFollower_Dist_Medium) ; #DEBUG_LINE_NO:1188
EndFunction

Function FollowerSetDistanceFar(Actor Follower)
  Self.SetFollowerActorValue(Follower, Game.GetCommonProperties().FollowerDistance, iFollower_Dist_Far) ; #DEBUG_LINE_NO:1192
EndFunction

Function SetFollowerActorValue(Actor Follower, ActorValue WhichValueToSet, GlobalVariable iFollower_Global)
  Follower.setvalue(WhichValueToSet, iFollower_Global.GetValue()) ; #DEBUG_LINE_NO:1196
EndFunction

Bool Function StartCompanionInteractionScene(GlobalVariable SceneTypeGlobal, ObjectReference SceneRef, Location SceneLoc, Actor CompanionActor) Global
  FollowersScript selfScript = FollowersScript.GetScript() ; #DEBUG_LINE_NO:1237
  If CompanionActor == None ; #DEBUG_LINE_NO:1239
    CompanionActor = selfScript.Companion.GetActorReference() ; #DEBUG_LINE_NO:1240
  EndIf
  Return selfScript.CIS_Companion_Scene_Start.SendStoryEventAndWait(SceneLoc, CompanionActor as ObjectReference, SceneRef, SceneTypeGlobal.GetValue() as Int, 0) ; #DEBUG_LINE_NO:1245
EndFunction

Function SendLoiteringEvent(Bool isNowLoitering)
  Var[] args = new Var[2] ; #DEBUG_LINE_NO:1308
  args[0] = isNowLoitering as Var ; #DEBUG_LINE_NO:1310
  args[1] = Companion as Var ; #DEBUG_LINE_NO:1311
  Self.sendCustomEvent("followersscript_Loitering", args) ; #DEBUG_LINE_NO:1315
EndFunction

Function InitializeLoiterBuffer()
  Float PlayerX = playerRef.X ; #DEBUG_LINE_NO:1321
  Float PlayerY = playerRef.Y ; #DEBUG_LINE_NO:1322
  Float PlayerZ = playerRef.Z ; #DEBUG_LINE_NO:1323
  Int I = 0 ; #DEBUG_LINE_NO:1325
  While I < LoiterBufferSize - 1 ; #DEBUG_LINE_NO:1326
    Self.BufferCurrentPosition(I, PlayerX, PlayerY, PlayerZ) ; #DEBUG_LINE_NO:1327
    I += 1 ; #DEBUG_LINE_NO:1329
  EndWhile
EndFunction

Function HandleTimer_LoiterSample()
  Float FurthestDistance = Self.GetFurthestDistanceAndPromoteSamples() ; #DEBUG_LINE_NO:1336
  If DebugDropMarkers == True ; #DEBUG_LINE_NO:1339
    
  EndIf
  Bool LoiterCoolingDown = False ; #DEBUG_LINE_NO:1343
  CurrentLoiterCoolDownTime -= TimerInterval_LoiterSample ; #DEBUG_LINE_NO:1345
  LoiterCoolingDown = CurrentLoiterCoolDownTime > 0.0 ; #DEBUG_LINE_NO:1346
  Bool Traveled = FurthestDistance > LoiterRadius ; #DEBUG_LINE_NO:1348
  Bool InCombat = playerRef.IsInCombat() ; #DEBUG_LINE_NO:1349
  Bool Sneaking = playerRef.isSneaking() ; #DEBUG_LINE_NO:1350
  Bool Sprinting = playerRef.IsSprinting() ; #DEBUG_LINE_NO:1351
  Bool WeaponOut = playerRef.IsWeaponDrawn() ; #DEBUG_LINE_NO:1352
  Bool NotSitting = playerRef.GetSitState() == 3 ; #DEBUG_LINE_NO:1353
  NotSitting = !NotSitting ; #DEBUG_LINE_NO:1353
  If DebugTrace_Loitering
    
  EndIf
  Bool shouldEVPFollowers = False ; #DEBUG_LINE_NO:1366
  If (Traveled || LoiterCoolingDown || InCombat || Sneaking || Sprinting || WeaponOut) && NotSitting ; #DEBUG_LINE_NO:1368
    If isPlayerLoitering == True ; #DEBUG_LINE_NO:1370
      Self.SendLoiteringEvent(False) ; #DEBUG_LINE_NO:1373
      shouldEVPFollowers = True ; #DEBUG_LINE_NO:1375
      Self.SetLoiterCoolDown(StandardLoiterCoolDownTime) ; #DEBUG_LINE_NO:1377
    EndIf
    isPlayerLoitering = False ; #DEBUG_LINE_NO:1380
  Else
    If isPlayerLoitering == False ; #DEBUG_LINE_NO:1383
      Self.SendLoiteringEvent(True) ; #DEBUG_LINE_NO:1386
      shouldEVPFollowers = True ; #DEBUG_LINE_NO:1388
    EndIf
    isPlayerLoitering = True ; #DEBUG_LINE_NO:1391
  EndIf
  If isPlayerLoitering
    
  EndIf
  If Companion.GetActorReference() as Bool && shouldEVPFollowers ; #DEBUG_LINE_NO:1407
    Companion.GetActorReference().EvaluatePackage(False) ; #DEBUG_LINE_NO:1408
  EndIf
  If DogmeatCompanion.GetActorReference() as Bool && shouldEVPFollowers ; #DEBUG_LINE_NO:1412
    DogmeatCompanion.GetActorReference().EvaluatePackage(False) ; #DEBUG_LINE_NO:1416
  EndIf
  Self.startTimer(TimerInterval_LoiterSample, iTimerID_LoiterSample) ; #DEBUG_LINE_NO:1419
EndFunction

Float Function GetFurthestDistanceAndPromoteSamples()
  Float FurthestDistance = 0.0 ; #DEBUG_LINE_NO:1429
  Float bufferedDistance = 0.0 ; #DEBUG_LINE_NO:1430
  Float PlayerX = playerRef.X ; #DEBUG_LINE_NO:1432
  Float PlayerY = playerRef.Y ; #DEBUG_LINE_NO:1433
  Float PlayerZ = playerRef.Z ; #DEBUG_LINE_NO:1434
  Int I = LoiterBufferSize - 1 ; #DEBUG_LINE_NO:1436
  While I >= 0 ; #DEBUG_LINE_NO:1437
    If I > 0 ; #DEBUG_LINE_NO:1439
      PlayerPosX[I] = PlayerPosX[I - 1] ; #DEBUG_LINE_NO:1440
      PlayerPosY[I] = PlayerPosY[I - 1] ; #DEBUG_LINE_NO:1441
      PlayerPosZ[I] = PlayerPosZ[I - 1] ; #DEBUG_LINE_NO:1442
    Else
      Self.BufferCurrentPosition(0, PlayerX, PlayerY, PlayerZ) ; #DEBUG_LINE_NO:1445
    EndIf
    bufferedDistance = Self.GetDistanceFromSamplePosition(I, PlayerX, PlayerY, PlayerZ) ; #DEBUG_LINE_NO:1449
    If bufferedDistance > FurthestDistance ; #DEBUG_LINE_NO:1451
      FurthestDistance = bufferedDistance ; #DEBUG_LINE_NO:1452
    EndIf
    I -= 1 ; #DEBUG_LINE_NO:1457
  EndWhile
  Return FurthestDistance ; #DEBUG_LINE_NO:1460
EndFunction

Function BufferCurrentPosition(Int bufferToSet, Float X, Float Y, Float Z)
  PlayerPosX[bufferToSet] = X ; #DEBUG_LINE_NO:1465
  PlayerPosY[bufferToSet] = Y ; #DEBUG_LINE_NO:1466
  PlayerPosZ[bufferToSet] = Z ; #DEBUG_LINE_NO:1467
EndFunction

Function SetLoiterCoolDown(Float CoolDownTime)
  CurrentLoiterCoolDownTime = CoolDownTime ; #DEBUG_LINE_NO:1474
EndFunction

Int Function GetLastBufferIndex()
  Return LoiterBufferSize - 1 ; #DEBUG_LINE_NO:1480
EndFunction

Float Function GetDistanceFromSamplePosition(Int BufferIndex, Float X, Float Y, Float Z)
  Float xFactor = PlayerPosX[BufferIndex] - X ; #DEBUG_LINE_NO:1489
  Float yFactor = PlayerPosY[BufferIndex] - Y ; #DEBUG_LINE_NO:1490
  Float zFactor = PlayerPosZ[BufferIndex] - Z ; #DEBUG_LINE_NO:1491
  xFactor *= xFactor ; #DEBUG_LINE_NO:1493
  yFactor *= yFactor ; #DEBUG_LINE_NO:1494
  zFactor *= zFactor ; #DEBUG_LINE_NO:1495
  Return Math.sqrt(xFactor + yFactor + zFactor) ; #DEBUG_LINE_NO:1497
EndFunction

Function DropDebugMarkers()
  If DebugDropMarkers == True ; #DEBUG_LINE_NO:1501
    If debugMarkers == None ; #DEBUG_LINE_NO:1505
      debugMarkers = new ObjectReference[LoiterBufferSize] ; #DEBUG_LINE_NO:1506
      Static markerToDrop = Game.GetFormFromFile(202764, "Fallout4.esm") as Static ; #DEBUG_LINE_NO:1508
      Int i = 0 ; #DEBUG_LINE_NO:1510
      While i < debugMarkers.Length - 1 ; #DEBUG_LINE_NO:1511
        debugMarkers[i] = playerRef.placeAtMe(markerToDrop as Form, 1, False, False, True) ; #DEBUG_LINE_NO:1512
        i += 1 ; #DEBUG_LINE_NO:1513
      EndWhile
    EndIf
    Int I = 0 ; #DEBUG_LINE_NO:1519
    While I < debugMarkers.Length - 1 ; #DEBUG_LINE_NO:1520
      debugMarkers[I].setPosition(PlayerPosX[I], PlayerPosY[I], PlayerPosZ[I]) ; #DEBUG_LINE_NO:1521
      I += 1 ; #DEBUG_LINE_NO:1523
    EndWhile
  EndIf
EndFunction

Bool Function SendAffinityEvent(ScriptObject Sender, Keyword EventKeyword, ObjectReference target, GlobalVariable EventSizeOverride, Bool CheckCompanionProximity, Bool ShouldSuppressComment, Bool IsDialogueBump, Float ResponseDelay) Global
  Return FollowersScript.GetScript().LocalSendAffinityEvent(Sender, EventKeyword, target, EventSizeOverride, CheckCompanionProximity, ShouldSuppressComment, IsDialogueBump, ResponseDelay) ; #DEBUG_LINE_NO:1728
EndFunction

Bool Function LocalSendAffinityEvent(ScriptObject Sender, Keyword EventKeyword, ObjectReference target, GlobalVariable EventSizeOverride, Bool CheckCompanionProximity, Bool ShouldSuppressComment, Bool IsDialogueBump, Float ResponseDelay)
  While LockSendAffinityEvent
    Utility.wait(0.100000001) ; #DEBUG_LINE_NO:1736
  EndWhile
  LockSendAffinityEvent = True ; #DEBUG_LINE_NO:1738
  followersscript:affinityeventdata CurrentAffinityEventData = FollowersScript.GetAffinityEventData(EventKeyword) ; #DEBUG_LINE_NO:1744
  If !CurrentAffinityEventData ; #DEBUG_LINE_NO:1745
    LockSendAffinityEvent = False ; #DEBUG_LINE_NO:1746
    Return False ; #DEBUG_LINE_NO:1747
  EndIf
  If CurrentAffinityEventData.NextDayAllowed > Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:1750
    LockSendAffinityEvent = False ; #DEBUG_LINE_NO:1752
    Return False ; #DEBUG_LINE_NO:1753
  EndIf
  Float NextDayAllowed = CurrentAffinityEventData.CoolDownDays.GetValue() + Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:1757
  CurrentAffinityEventData.NextDayAllowed = NextDayAllowed ; #DEBUG_LINE_NO:1761
  GlobalVariable EventSize = None ; #DEBUG_LINE_NO:1763
  If EventSizeOverride ; #DEBUG_LINE_NO:1765
    EventSize = EventSizeOverride ; #DEBUG_LINE_NO:1766
  Else
    EventSize = CurrentAffinityEventData.EventSize ; #DEBUG_LINE_NO:1768
  EndIf
  Var[] args = new Var[8] ; #DEBUG_LINE_NO:1771
  args[0] = EventKeyword as Var ; #DEBUG_LINE_NO:1772
  args[1] = EventSize as Var ; #DEBUG_LINE_NO:1773
  args[2] = CheckCompanionProximity as Var ; #DEBUG_LINE_NO:1776
  args[3] = CurrentAffinityEventData.AssociatedActorValue as Var ; #DEBUG_LINE_NO:1777
  If ShouldSuppressComment == False ; #DEBUG_LINE_NO:1779
    args[4] = CurrentAffinityEventData.TopicSubType as Var ; #DEBUG_LINE_NO:1780
  EndIf
  args[5] = IsDialogueBump as Var ; #DEBUG_LINE_NO:1783
  args[6] = ResponseDelay as Var ; #DEBUG_LINE_NO:1784
  args[7] = target as Var ; #DEBUG_LINE_NO:1785
  Self.sendCustomEvent("followersscript_AffinityEvent", args) ; #DEBUG_LINE_NO:1787
  LockSendAffinityEvent = False ; #DEBUG_LINE_NO:1789
  Return True ; #DEBUG_LINE_NO:1790
EndFunction

followersscript:affinityeventdata Function GetAffinityEventData(Keyword EventKeyword) Global
  followersscript:affinityeventdata[] myAffinityEvents = FollowersScript.GetScript().AffinityEvents ; #DEBUG_LINE_NO:1798
  Int I = 0 ; #DEBUG_LINE_NO:1800
  While I < myAffinityEvents.Length ; #DEBUG_LINE_NO:1801
    If myAffinityEvents[I].EventKeyword == EventKeyword ; #DEBUG_LINE_NO:1802
      Return myAffinityEvents[I] ; #DEBUG_LINE_NO:1803
    EndIf
    I += 1 ; #DEBUG_LINE_NO:1806
  EndWhile
EndFunction

Function SendPossibleMurderEvent(Actor ActorVictim, Actor ActorKiller, Bool GameConsidersMurder) Global
  FollowersScript thisScript = FollowersScript.GetScript() ; #DEBUG_LINE_NO:1815
  Var[] args = new Var[3] ; #DEBUG_LINE_NO:1817
  args[0] = ActorVictim as Var ; #DEBUG_LINE_NO:1819
  args[1] = ActorKiller as Var ; #DEBUG_LINE_NO:1820
  args[2] = GameConsidersMurder as Var ; #DEBUG_LINE_NO:1821
  If thisScript.IsActorInLocationWhereMurderShouldBeIgnored(ActorKiller) ; #DEBUG_LINE_NO:1823
    Return  ; #DEBUG_LINE_NO:1825
  EndIf
  thisScript.sendCustomEvent("followersscript_PossibleMurderEvent", args) ; #DEBUG_LINE_NO:1828
EndFunction

Function SetLocationForCompanionsToIgnoreMurder(Location LocationToIgnoreMurderIn)
  If LocationsToIgnoreMurderIn == None ; #DEBUG_LINE_NO:1834
    LocationsToIgnoreMurderIn = new Location[0] ; #DEBUG_LINE_NO:1835
  EndIf
  If LocationsToIgnoreMurderIn.find(LocationToIgnoreMurderIn, 0) < 0 ; #DEBUG_LINE_NO:1838
    LocationsToIgnoreMurderIn.add(LocationToIgnoreMurderIn, 1) ; #DEBUG_LINE_NO:1839
  EndIf
EndFunction

Bool Function IsActorInLocationWhereMurderShouldBeIgnored(Actor ActorToTest)
  Int I = 0 ; #DEBUG_LINE_NO:1844
  While I < LocationsToIgnoreMurderIn.Length ; #DEBUG_LINE_NO:1845
    If ActorToTest.IsInLocation(LocationsToIgnoreMurderIn[I]) ; #DEBUG_LINE_NO:1846
      Return True ; #DEBUG_LINE_NO:1848
    EndIf
    I += 1 ; #DEBUG_LINE_NO:1851
  EndWhile
  Return False ; #DEBUG_LINE_NO:1854
EndFunction

Function HandleOnCrippleEvent(Var akSender, ActorValue akActorValue, Bool abCrippled)
  If abCrippled ; #DEBUG_LINE_NO:1860
    If akSender as Actor == playerRef ; #DEBUG_LINE_NO:1861
      Self.SendAffinityCrippledEvent(akSender as Actor, akActorValue, True, False) ; #DEBUG_LINE_NO:1862
    ElseIf akSender as ReferenceAlias == Companion ; #DEBUG_LINE_NO:1864
      Self.SendAffinityCrippledEvent((akSender as ReferenceAlias).GetActorReference(), akActorValue, False, True) ; #DEBUG_LINE_NO:1865
    EndIf
  EndIf
EndFunction

Function HandleVertibirdEvent(ObjectReference akVertibird)
  FollowersScript.SendAffinityEvent(akVertibird as ScriptObject, VertibirdKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1887
EndFunction

Function HandleOnWorkbench(ObjectReference akWorkBench)
  FollowersScript.SendAffinityEvent(akWorkBench as ScriptObject, WorkbenchKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1892
EndFunction

Function HandleOnSwimming(Location akLocation)
  FollowersScript.SendAffinityEvent(akLocation as ScriptObject, SwimmingKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1897
EndFunction

Function HandleOnRadiation(Location akLocation)
  FollowersScript.SendAffinityEvent(akLocation as ScriptObject, RadiationKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1901
EndFunction

Function HandleOnMod(Form ModdedBaseObject)
  If ModdedBaseObject is Weapon ; #DEBUG_LINE_NO:1905
    FollowersScript.SendAffinityEvent(ModdedBaseObject as ScriptObject, ModWeaponKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1906
  ElseIf ModdedBaseObject is Armor ; #DEBUG_LINE_NO:1907
    FollowersScript.SendAffinityEvent(ModdedBaseObject as ScriptObject, ModArmorKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1908
  EndIf
EndFunction

Function SendAffinityCrippledEvent(Actor akSenderActor, ActorValue akActorValue, Bool isPlayer, Bool IsCompanion)
  Keyword EventKeyword = None ; #DEBUG_LINE_NO:1918
  Int I = 0 ; #DEBUG_LINE_NO:1920
  While I < CrippleEventData.Length ; #DEBUG_LINE_NO:1921
    If CrippleEventData[I].LimbConditionActorValue == akActorValue ; #DEBUG_LINE_NO:1922
      If IsCompanion ; #DEBUG_LINE_NO:1924
        EventKeyword = CrippleEventData[I].AffinityKeyword_Companion ; #DEBUG_LINE_NO:1925
      ElseIf isPlayer
        EventKeyword = CrippleEventData[I].AffinityKeyword_Player ; #DEBUG_LINE_NO:1928
      EndIf
    EndIf
    I += 1 ; #DEBUG_LINE_NO:1932
  EndWhile
  If EventKeyword == None ; #DEBUG_LINE_NO:1935
    Return  ; #DEBUG_LINE_NO:1937
  EndIf
  FollowersScript.SendAffinityEvent(akSenderActor as ScriptObject, EventKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1940
EndFunction

Function HandleOnItemEquipped(ObjectReference akSender, Form akBaseObject)
  If (akSender == Game.GetPlayer() as ObjectReference) && akBaseObject.HasKeyword(isPowerArmorFrame) ; #DEBUG_LINE_NO:1946
    FollowersScript.SendAffinityEvent(akBaseObject as ScriptObject, EnterPowerArmorKeyword, None, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:1947
  EndIf
EndFunction

Actor Function GetNearbyInfatuatedRomanticCompanion()
  Actor NearbyInfatuatedActor = None ; #DEBUG_LINE_NO:1953
  companionactorscript CompanionActor = Companion.GetActorReference() as companionactorscript ; #DEBUG_LINE_NO:1955
  If (CompanionActor as Bool && CompanionActor.IsInfatuated()) && CompanionActor.IsRomantic() && CompanionActor.IsPlayerNearby() ; #DEBUG_LINE_NO:1958
    NearbyInfatuatedActor = CompanionActor as Actor ; #DEBUG_LINE_NO:1959
  Else
    Int I = 0 ; #DEBUG_LINE_NO:1962
    While I < ActiveCompanions.GetCount() ; #DEBUG_LINE_NO:1963
      CompanionActor = (ActiveCompanions.GetAt(I) as Actor) as companionactorscript ; #DEBUG_LINE_NO:1964
      If (CompanionActor as Bool && CompanionActor.IsInfatuated()) && CompanionActor.IsRomantic() && CompanionActor.IsPlayerNearby() ; #DEBUG_LINE_NO:1966
        If NearbyInfatuatedActor as Bool == False ; #DEBUG_LINE_NO:1967
          NearbyInfatuatedActor = CompanionActor as Actor ; #DEBUG_LINE_NO:1968
        ElseIf NearbyInfatuatedActor.GetDistance(playerRef as ObjectReference) > CompanionActor.GetDistance(playerRef as ObjectReference) ; #DEBUG_LINE_NO:1970
          NearbyInfatuatedActor = CompanionActor as Actor ; #DEBUG_LINE_NO:1971
        EndIf
      EndIf
      I += 1 ; #DEBUG_LINE_NO:1975
    EndWhile
  EndIf
  Return NearbyInfatuatedActor ; #DEBUG_LINE_NO:1981
EndFunction

Function HandleOnSleepStart(ObjectReference bedRef)
  SleepCompanionActor = Self.GetNearbyInfatuatedRomanticCompanion() ; #DEBUG_LINE_NO:1988
  If SleepCompanionActor ; #DEBUG_LINE_NO:1990
    SleepCompanionActor.AddKeyword(FollowersCompanionSleepNearPlayerFlag) ; #DEBUG_LINE_NO:1991
    SleepCompanion.ForceRefTo(SleepCompanionActor as ObjectReference) ; #DEBUG_LINE_NO:1992
    SleepCompanionBed.ForceRefTo(bedRef) ; #DEBUG_LINE_NO:1993
    SleepCompanionActor.EvaluatePackage(False) ; #DEBUG_LINE_NO:1994
  EndIf
EndFunction

Function HandleOnSleepEnd()
  If SleepCompanionActor ; #DEBUG_LINE_NO:2005
    SleepNearInfatuatedCompanionBonus.Cast(playerRef as ObjectReference, playerRef as ObjectReference) ; #DEBUG_LINE_NO:2006
    SleepCompanionActor.RemoveKeyword(FollowersCompanionSleepNearPlayerFlag) ; #DEBUG_LINE_NO:2007
  EndIf
  SleepCompanion.Clear() ; #DEBUG_LINE_NO:2010
EndFunction

Function AskedForMoreCaps(ScriptObject Sender) Global
  FollowersScript.SendAffinityEvent(Sender, FollowersScript.GetScript().AskedForMoreCapsKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2019
EndFunction

Function PlayerSaidGenerous(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().GenerousKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2023
EndFunction

Function PlayerSaidSelfish(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().SelfishKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2027
EndFunction

Function PlayerSaidNice(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().NiceKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2031
EndFunction

Function PlayerSaidMean(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().MeanKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2035
EndFunction

Function PlayerSaidPeaceful(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().PeacefulKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2039
EndFunction

Function PlayerSaidViolent(TopicInfo CallingTopicInfo) Global
  FollowersScript.SendAffinityEvent(CallingTopicInfo as ScriptObject, FollowersScript.GetScript().ViolentKeyword, None, None, True, True, False, 1.0) ; #DEBUG_LINE_NO:2043
EndFunction

Function FlagCompanionChatEvent(ActorValue ActorValueRepresentingEvent) Global
  companionactorscript CompanionActor = FollowersScript.GetScript().Companion.GetActorReference() as companionactorscript ; #DEBUG_LINE_NO:2050
  If CompanionActor as Bool && CompanionActor.IsPlayerNearby() ; #DEBUG_LINE_NO:2052
    CompanionActor.setvalue(ActorValueRepresentingEvent, 1.0) ; #DEBUG_LINE_NO:2054
  EndIf
EndFunction

Function ShowSA()
  String msg = "SITUATION AWARENESS:\n" ; #DEBUG_LINE_NO:2211
  msg += ("SAS = " + SAS as String) + "\n" ; #DEBUG_LINE_NO:2212
  msg += ("SAS_Global = " + SAS_Global as String) + "\n" ; #DEBUG_LINE_NO:2213
  msg += ("SAS_TimeStamp = " + SAS_TimeStamp as String) + "\n" ; #DEBUG_LINE_NO:2214
  msg += ("SAS_ScriptObject = " + SAS_ScriptObject as String) + "\n" ; #DEBUG_LINE_NO:2215
  msg += "\n" ; #DEBUG_LINE_NO:2216
  msg += ("SAEClutter = " + SAEClutter as String) + "\n" ; #DEBUG_LINE_NO:2217
  msg += ("SAEClutter_Global = " + SAEClutter_Global as String) + "\n" ; #DEBUG_LINE_NO:2218
  msg += ("SAEClutter_TimeStamp = " + SAEClutter_TimeStamp as String) + "\n" ; #DEBUG_LINE_NO:2219
  msg += ("SAEClutter_ScriptObject = " + SAEClutter_ScriptObject as String) + "\n" ; #DEBUG_LINE_NO:2220
  msg += "\n" ; #DEBUG_LINE_NO:2221
  msg += ("SAECombatant = " + SAECombatant as String) + "\n" ; #DEBUG_LINE_NO:2222
  msg += ("SAECombatant_Global = " + SAECombatant_Global as String) + "\n" ; #DEBUG_LINE_NO:2223
  msg += ("SAECombatant_TimeStamp = " + SAECombatant_TimeStamp as String) + "\n" ; #DEBUG_LINE_NO:2224
  msg += ("SAECombatant_ScriptObject = " + SAECombatant_ScriptObject as String) + "\n" ; #DEBUG_LINE_NO:2225
  msg += "\n" ; #DEBUG_LINE_NO:2226
  msg += ("SAC_LastCombat = " + SAC_LastCombat as String) + "\n" ; #DEBUG_LINE_NO:2227
  msg += ("SAECombatant_Global = " + SAECombatant_Global as String) + "\n" ; #DEBUG_LINE_NO:2228
  msg += ("SAC_LastCombat_Timestamp = " + SAC_LastCombat_Timestamp as String) + "\n" ; #DEBUG_LINE_NO:2229
EndFunction

followersscript:setdefinition Function GetSetDefinition(Keyword KeywordToFind, Location LocationToCheck)
  Int I = 0 ; #DEBUG_LINE_NO:2238
  While I < SetDefinitions.Length ; #DEBUG_LINE_NO:2239
    If KeywordToFind as Bool && SetDefinitions[I].LocSetKeyword == KeywordToFind ; #DEBUG_LINE_NO:2241
      Return SetDefinitions[I] ; #DEBUG_LINE_NO:2242
    EndIf
    If LocationToCheck as Bool && LocationToCheck.HasKeyword(SetDefinitions[I].LocSetKeyword) ; #DEBUG_LINE_NO:2245
      Return SetDefinitions[I] ; #DEBUG_LINE_NO:2246
    EndIf
    I += 1 ; #DEBUG_LINE_NO:2249
  EndWhile
EndFunction

followersscript:encdefinition Function GetEncDefinition(Keyword KeywordToFind, Location LocationToCheck, Faction FactionToCheck, Actor ActorToCheck)
  Int I = 0 ; #DEBUG_LINE_NO:2257
  While I < EncDefinitions.Length ; #DEBUG_LINE_NO:2258
    If KeywordToFind as Bool && EncDefinitions[I].LocEncKeyword == KeywordToFind ; #DEBUG_LINE_NO:2260
      Return EncDefinitions[I] ; #DEBUG_LINE_NO:2261
    EndIf
    If LocationToCheck as Bool && LocationToCheck.HasKeyword(EncDefinitions[I].LocEncKeyword) ; #DEBUG_LINE_NO:2264
      Return EncDefinitions[I] ; #DEBUG_LINE_NO:2265
    EndIf
    If FactionToCheck as Bool && EncDefinitions[I].Associated_Faction == FactionToCheck ; #DEBUG_LINE_NO:2268
      Return EncDefinitions[I] ; #DEBUG_LINE_NO:2269
    EndIf
    If ActorToCheck as Bool && ActorToCheck.IsInFaction(EncDefinitions[I].Associated_Faction) ; #DEBUG_LINE_NO:2272
      Return EncDefinitions[I] ; #DEBUG_LINE_NO:2273
    EndIf
    I += 1 ; #DEBUG_LINE_NO:2276
  EndWhile
EndFunction

Int Function GetIndexOfLastCombatDefinition(GlobalVariable GlobalToFind)
  Int I = 0 ; #DEBUG_LINE_NO:2284
  While I < LastCombatDefinitions.Length ; #DEBUG_LINE_NO:2285
    If GlobalToFind as Bool && LastCombatDefinitions[I].SAC_Global == GlobalToFind ; #DEBUG_LINE_NO:2287
      Return I ; #DEBUG_LINE_NO:2288
    EndIf
    I += 1 ; #DEBUG_LINE_NO:2291
  EndWhile
EndFunction

Function SetSAS(Keyword LocSetKeyword, ScriptObject SettingObject)
  followersscript:setdefinition FoundSetDefinition = Self.GetSetDefinition(LocSetKeyword, None) ; #DEBUG_LINE_NO:2303
  If FoundSetDefinition as Bool == False ; #DEBUG_LINE_NO:2305
    SAS_Global = None ; #DEBUG_LINE_NO:2308
    SAS = -1.0 ; #DEBUG_LINE_NO:2309
  Else
    SAS_Global = FoundSetDefinition.LocSetGlobal ; #DEBUG_LINE_NO:2311
    SAS = SAS_Global.value ; #DEBUG_LINE_NO:2312
  EndIf
  SAS_TimeStamp = Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:2315
  SAS_ScriptObject = SettingObject ; #DEBUG_LINE_NO:2316
EndFunction

Function SetSAE(Keyword LocEncKeyword, Bool shouldSetSAEClutter, Bool shouldSetSAECombatant, ScriptObject SettingObject)
  If shouldSetSAEClutter ; #DEBUG_LINE_NO:2324
    Self.SetSAEClutter(LocEncKeyword, SettingObject) ; #DEBUG_LINE_NO:2325
  EndIf
  If shouldSetSAECombatant ; #DEBUG_LINE_NO:2328
    Self.SetSAECombatant(LocEncKeyword, SettingObject) ; #DEBUG_LINE_NO:2329
  EndIf
EndFunction

Function SetSAEClutter(Keyword LocEncKeyword, ScriptObject SettingObject)
  followersscript:encdefinition FoundEncDefinition = Self.GetEncDefinition(LocEncKeyword, None, None, None) ; #DEBUG_LINE_NO:2337
  If FoundEncDefinition as Bool == False ; #DEBUG_LINE_NO:2339
    SAEClutter_Global = None ; #DEBUG_LINE_NO:2342
    SAEClutter = -1.0 ; #DEBUG_LINE_NO:2343
  Else
    SAEClutter_Global = FoundEncDefinition.LocEncGlobal ; #DEBUG_LINE_NO:2345
    SAEClutter = FoundEncDefinition.LocEncGlobal.value ; #DEBUG_LINE_NO:2346
  EndIf
  SAEClutter_TimeStamp = Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:2350
  SAEClutter_ScriptObject = SettingObject ; #DEBUG_LINE_NO:2351
EndFunction

Function ClearSAEClutter()
  SAEClutter_Global = None ; #DEBUG_LINE_NO:2359
  SAEClutter = -1.0 ; #DEBUG_LINE_NO:2360
EndFunction

Function SetSAECombatant(Keyword LocEncKeyword, ScriptObject SettingObject)
  followersscript:encdefinition FoundEncDefinition = Self.GetEncDefinition(LocEncKeyword, None, None, None) ; #DEBUG_LINE_NO:2368
  If FoundEncDefinition as Bool == False ; #DEBUG_LINE_NO:2370
    SAECombatant_Global = None ; #DEBUG_LINE_NO:2373
    SAECombatant = -1.0 ; #DEBUG_LINE_NO:2374
  Else
    SAECombatant_Global = FoundEncDefinition.LocEncGlobal ; #DEBUG_LINE_NO:2376
    SAECombatant = FoundEncDefinition.LocEncGlobal.value ; #DEBUG_LINE_NO:2377
  EndIf
  SAECombatant_TimeStamp = Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:2381
  SAECombatant_ScriptObject = SettingObject ; #DEBUG_LINE_NO:2382
  Self.startTimerGameTime(TimerInterval_SAECombatantExpiry, iTimerID_GameTime_SAECombatantExpiry) ; #DEBUG_LINE_NO:2388
EndFunction

Function ClearSAECombatant()
  SAECombatant_Global = None ; #DEBUG_LINE_NO:2392
  SAECombatant = -1.0 ; #DEBUG_LINE_NO:2393
EndFunction

Function SetSituationAwarenessBasedOnLocation(Location LocationToCheck, Bool SetSASData, Bool SetSAEClutterData, ScriptObject SettingObject)
  followersscript:setdefinition FoundSetDefinition = Self.GetSetDefinition(None, LocationToCheck) ; #DEBUG_LINE_NO:2412
  followersscript:encdefinition FoundEncDefinition = Self.GetEncDefinition(None, LocationToCheck, None, None) ; #DEBUG_LINE_NO:2413
  If SetSASData ; #DEBUG_LINE_NO:2415
    If FoundSetDefinition ; #DEBUG_LINE_NO:2416
      Keyword LocSet = FoundSetDefinition.LocSetKeyword ; #DEBUG_LINE_NO:2418
      Self.SetSAS(LocSet, LocationToCheck as ScriptObject) ; #DEBUG_LINE_NO:2419
    Else
      Self.SetSAS(None, LocationToCheck as ScriptObject) ; #DEBUG_LINE_NO:2422
    EndIf
  EndIf
  If SetSAEClutterData ; #DEBUG_LINE_NO:2427
    If FoundEncDefinition ; #DEBUG_LINE_NO:2428
      Keyword LocEnc = FoundEncDefinition.LocEncKeyword ; #DEBUG_LINE_NO:2429
      Self.SetSAE(LocEnc, True, False, SettingObject) ; #DEBUG_LINE_NO:2430
    Else
      Self.SetSAE(None, True, False, SettingObject) ; #DEBUG_LINE_NO:2433
    EndIf
  EndIf
EndFunction

Function SetSituationAwarenessBasedOnActor(Actor ActorToCheck, Bool shouldSetLastCombatTime, Bool shouldSetSAEClutter, Bool shouldSetSAECombatant, ScriptObject SettingObject)
  followersscript:encdefinition FoundEncDefinition = Self.GetEncDefinition(None, None, None, ActorToCheck) ; #DEBUG_LINE_NO:2449
  If FoundEncDefinition ; #DEBUG_LINE_NO:2451
    Faction LocEncFaction = FoundEncDefinition.Associated_Faction ; #DEBUG_LINE_NO:2452
    Self.SetSituationAwarenessBasedOnFaction(LocEncFaction, shouldSetSAEClutter, shouldSetSAECombatant, SettingObject) ; #DEBUG_LINE_NO:2453
  Else
    Self.SetSituationAwarenessBasedOnFaction(None, shouldSetSAEClutter, shouldSetSAECombatant, SettingObject) ; #DEBUG_LINE_NO:2456
  EndIf
  If shouldSetLastCombatTime ; #DEBUG_LINE_NO:2459
    SAC_LastCombat_Timestamp = Utility.GetCurrentGameTime() ; #DEBUG_LINE_NO:2460
    SAC_LastCombat_Global = LastCombatDefinitions[0].SAC_Global ; #DEBUG_LINE_NO:2461
    SAC_LastCombat = SAC_LastCombat_Global.value ; #DEBUG_LINE_NO:2462
    If DebugTrace_SA
      
    EndIf
    Self.startTimerGameTime(TimerInterval_SAC_LastCombat, iTimerID_GameTime_SAC_LastCombat) ; #DEBUG_LINE_NO:2470
  EndIf
EndFunction

Function SetSituationAwarenessBasedOnFaction(Faction FactionToUse, Bool shouldSetSAEClutter, Bool shouldSetSAECombatant, ScriptObject SettingObject)
  Keyword FoundKeyword = None ; #DEBUG_LINE_NO:2482
  followersscript:encdefinition definition = Self.GetEncDefinition(None, None, FactionToUse, None) ; #DEBUG_LINE_NO:2484
  If definition ; #DEBUG_LINE_NO:2486
    FoundKeyword = definition.LocEncKeyword ; #DEBUG_LINE_NO:2487
  EndIf
  If FoundKeyword as Bool == False ; #DEBUG_LINE_NO:2490
    Self.SetSAE(None, shouldSetSAEClutter, shouldSetSAECombatant, SettingObject) ; #DEBUG_LINE_NO:2492
  EndIf
  Self.SetSAE(FoundKeyword, shouldSetSAEClutter, shouldSetSAECombatant, SettingObject) ; #DEBUG_LINE_NO:2495
EndFunction

Function HandleTimer_GameTime_SAECombatantExpiry()
  Self.ClearSAECombatant() ; #DEBUG_LINE_NO:2504
EndFunction

Function HandleMessageFromSAEClutterTrigger(saecluttertriggerscript triggerbox, Bool AddMe)
  If AddMe ; #DEBUG_LINE_NO:2516
    SA_CurrentSAEClutterTriggersList.addForm(triggerbox as Form) ; #DEBUG_LINE_NO:2517
  Else
    SA_CurrentSAEClutterTriggersList.RemoveAddedForm(triggerbox as Form) ; #DEBUG_LINE_NO:2519
  EndIf
  Bool debugMe = True ; #DEBUG_LINE_NO:2523
  If debugMe ; #DEBUG_LINE_NO:2524
    If SA_CurrentSAEClutterTriggersList.getSize() <= 0 ; #DEBUG_LINE_NO:2525
      
    EndIf
    Int I = 0 ; #DEBUG_LINE_NO:2529
    While I < SA_CurrentSAEClutterTriggersList.getSize() ; #DEBUG_LINE_NO:2530
      I += 1 ; #DEBUG_LINE_NO:2533
    EndWhile
  EndIf
  If SA_CurrentSAEClutterTriggersList.getSize() > 0 ; #DEBUG_LINE_NO:2539
    saecluttertriggerscript FirstInList = SA_CurrentSAEClutterTriggersList.GetAt(0) as saecluttertriggerscript ; #DEBUG_LINE_NO:2540
    If FirstInList.LocEncKeyword ; #DEBUG_LINE_NO:2542
      Self.SetSAE(FirstInList.LocEncKeyword, True, False, triggerbox as ScriptObject) ; #DEBUG_LINE_NO:2543
    EndIf
  Else
    Self.ClearSAEClutter() ; #DEBUG_LINE_NO:2549
  EndIf
EndFunction

Function HandleMessageFromSASTrigger(sastriggerscript triggerbox, Bool AddMe)
  If AddMe ; #DEBUG_LINE_NO:2566
    SA_CurrentSASTriggersList.addForm(triggerbox as Form) ; #DEBUG_LINE_NO:2567
  Else
    SA_CurrentSASTriggersList.RemoveAddedForm(triggerbox as Form) ; #DEBUG_LINE_NO:2569
  EndIf
  Bool debugMe = True ; #DEBUG_LINE_NO:2573
  If debugMe ; #DEBUG_LINE_NO:2574
    If SA_CurrentSASTriggersList.getSize() <= 0 ; #DEBUG_LINE_NO:2575
      
    EndIf
    Int I = 0 ; #DEBUG_LINE_NO:2579
    While I < SA_CurrentSASTriggersList.getSize() ; #DEBUG_LINE_NO:2580
      I += 1 ; #DEBUG_LINE_NO:2583
    EndWhile
  EndIf
  If SA_CurrentSASTriggersList.getSize() > 0 ; #DEBUG_LINE_NO:2589
    sastriggerscript FirstInList = SA_CurrentSASTriggersList.GetAt(0) as sastriggerscript ; #DEBUG_LINE_NO:2590
    If FirstInList.LocSetKeyword ; #DEBUG_LINE_NO:2592
      Self.SetSAS(FirstInList.LocSetKeyword, triggerbox as ScriptObject) ; #DEBUG_LINE_NO:2593
    EndIf
  Else
    Self.SetSituationAwarenessBasedOnLocation(playerRef.GetCurrentLocation(), True, False, triggerbox as ScriptObject) ; #DEBUG_LINE_NO:2600
  EndIf
EndFunction

Function HandleCombatMessageToSituationAwareness(Actor Enemy)
  Self.SetSituationAwarenessBasedOnActor(Enemy, True, False, True, Enemy as ScriptObject) ; #DEBUG_LINE_NO:2613
EndFunction

Function Handletimer_GameTime_SAC_LastCombat()
  Int I = Self.GetIndexOfLastCombatDefinition(SAC_LastCombat_Global) ; #DEBUG_LINE_NO:2624
  If I < 0 ; #DEBUG_LINE_NO:2626
    Return  ; #DEBUG_LINE_NO:2630
  EndIf
  If I + 1 >= LastCombatDefinitions.Length ; #DEBUG_LINE_NO:2633
    Return  ; #DEBUG_LINE_NO:2637
  EndIf
  Float TimeForNextSetting = SAC_LastCombat_Timestamp + LastCombatDefinitions[I + 1].SAC_Time ; #DEBUG_LINE_NO:2641
  Bool isLastItemInArray = False ; #DEBUG_LINE_NO:2647
  If Utility.GetCurrentGameTime() >= TimeForNextSetting ; #DEBUG_LINE_NO:2649
    SAC_LastCombat_Global = LastCombatDefinitions[I + 1].SAC_Global ; #DEBUG_LINE_NO:2650
    SAC_LastCombat = SAC_LastCombat_Global.value ; #DEBUG_LINE_NO:2651
    isLastItemInArray = LastCombatDefinitions.Length - 1 <= I + 1 ; #DEBUG_LINE_NO:2653
    If DebugTrace_SA
      
    EndIf
  EndIf
  If isLastItemInArray == False ; #DEBUG_LINE_NO:2663
    Self.startTimerGameTime(TimerInterval_SAC_LastCombat, iTimerID_GameTime_SAC_LastCombat) ; #DEBUG_LINE_NO:2664
  EndIf
EndFunction

Function SetAutonomy(ScriptObject CallingObject, Bool AutonomousActivityAllowed) Global
  FollowersScript.GetScript().SetAutonomyPrivate(CallingObject, AutonomousActivityAllowed) ; #DEBUG_LINE_NO:2687
EndFunction

Function SetAutonomyPrivate(ScriptObject CallingObject, Bool AutonomousActivityAllowed)
  Int foundIndex = AutonomyDisallowedByObjects.find(CallingObject, 0) ; #DEBUG_LINE_NO:2693
  If AutonomousActivityAllowed && foundIndex >= 0 ; #DEBUG_LINE_NO:2695
    AutonomyDisallowedByObjects.remove(foundIndex, 1) ; #DEBUG_LINE_NO:2696
  ElseIf AutonomousActivityAllowed == False && foundIndex < 0 ; #DEBUG_LINE_NO:2698
    AutonomyDisallowedByObjects.add(CallingObject, 1) ; #DEBUG_LINE_NO:2699
  EndIf
  If AutonomyDisallowedByObjects.Length == 0 ; #DEBUG_LINE_NO:2704
    AutonomyAllowed = True ; #DEBUG_LINE_NO:2705
  Else
    AutonomyAllowed = False ; #DEBUG_LINE_NO:2707
    Var[] akArgs = new Var[3] ; #DEBUG_LINE_NO:2710
    akArgs[0] = CallingObject as Var ; #DEBUG_LINE_NO:2711
    akArgs[1] = Companion as Var ; #DEBUG_LINE_NO:2712
    akArgs[2] = DogmeatCompanion as Var ; #DEBUG_LINE_NO:2713
    Self.sendCustomEvent("followersscript_AutonomyDisallowed", akArgs) ; #DEBUG_LINE_NO:2715
  EndIf
EndFunction

Function AllowAutonomyOnTeleport()
  AutonomyDisallowedByObjects.clear() ; #DEBUG_LINE_NO:2722
  AutonomyAllowed = True ; #DEBUG_LINE_NO:2723
EndFunction

;-- State -------------------------------------------
State HandlingOnHit

  Event OnHit(ObjectReference RemoteSource, ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked, String asMaterialName)
    ; Empty function
  EndEvent
EndState
