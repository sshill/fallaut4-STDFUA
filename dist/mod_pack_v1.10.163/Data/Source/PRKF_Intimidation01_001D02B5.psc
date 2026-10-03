ScriptName Fragments:Perks:PRKF_Intimidation01_001D02B5 Extends Perk Const hidden

;-- Variables ---------------------------------------

;-- Properties --------------------------------------
Spell Property pHoldUpSpell Auto Const
ActorValue Property pHoldupImmuneToExplosionAV Auto Const
MagicEffect Property PholdupPacifyEffect Auto Const mandatory
ActorValue Property pHoldupAV Auto Const mandatory

;-- Functions ---------------------------------------

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
  Actor victim = akTargetRef as Actor ; #DEBUG_LINE_NO:7
  victim.setValue(pHoldupImmuneToExplosionAV, 1.0) ; #DEBUG_LINE_NO:8
  If victim.HasMagicEffect(PholdupPacifyEffect) == False ; #DEBUG_LINE_NO:9
    pHoldUpSpell.Cast(victim as ObjectReference, None) ; #DEBUG_LINE_NO:10
    Utility.wait(1.0) ; #DEBUG_LINE_NO:11
    If victim.getValue(pHoldupAV) == 1.0 ; #DEBUG_LINE_NO:12
      Game.IncrementStat("Intimidations", 1) ; #DEBUG_LINE_NO:13
    EndIf
  EndIf
EndFunction
