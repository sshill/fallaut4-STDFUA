ScriptName MercyRecruitmentPerkScript Extends Perk Const
{ Script attached to MercyRecruitmentPerk for Add Activate Choice Entry Point }

MercyRecruitmentQuestScript Property MercyQuest Auto Const
Faction Property WorkshopNPCFaction Auto Const

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
    If MercyQuest == None || akTargetRef == None
        Return
    EndIf
    
    Actor targetActor = akTargetRef as Actor
    If targetActor == None
        Return
    EndIf
    
    MercyQuest.HandleActivation(targetActor)
EndFunction
