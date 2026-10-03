ScriptName Fragments:Perks:PRKF_Cannibal_0004B259 Extends Perk Const hidden

;-- Variables ---------------------------------------

;-- Properties --------------------------------------
Spell Property PerkCannibalHeal Auto Const
Keyword Property CA_Event_EatCorpse Auto Const
EffectShader Property pBloodSplatterHeavy Auto Const mandatory
EffectShader Property pBloodHeavyParticles Auto Const mandatory
ImpactDataSet Property pBloodBugPopImpactSet Auto Const mandatory

;-- Functions ---------------------------------------

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
  Game.GetPlayer().StartCannibal(akTargetRef as Actor) ; #DEBUG_LINE_NO:8
  Utility.wait(0.600000024) ; #DEBUG_LINE_NO:11
  pBloodHeavyParticles.Play((akTargetRef as Actor) as ObjectReference, 1.200000048) ; #DEBUG_LINE_NO:12
  pBloodSplatterHeavy.Play((akTargetRef as Actor) as ObjectReference, -1.0) ; #DEBUG_LINE_NO:13
  Game.GetPlayer().PlayImpactEffect(pBloodBugPopImpactSet, "Head", 0.0, 0.0, -1.0, 256.0, False, False) ; #DEBUG_LINE_NO:15
  PerkCannibalHeal.Cast(Game.GetPlayer() as ObjectReference, Game.GetPlayer() as ObjectReference) ; #DEBUG_LINE_NO:18
  followersscript.SendAffinityEvent(Self as ScriptObject, CA_Event_EatCorpse, akTargetRef, None, True, False, False, 1.0) ; #DEBUG_LINE_NO:20
EndFunction
