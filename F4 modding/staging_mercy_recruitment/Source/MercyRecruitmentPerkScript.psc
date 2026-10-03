ScriptName MercyRecruitmentPerkScript Extends Perk Const
{ Script attached to MercyRecruitmentPerk for Add Activate Choice Entry Point }

MercyRecruitmentQuestScript Property MercyQuest Auto Const

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
    If MercyQuest != None && akTargetRef != None
        MercyQuest.RecruitPeacefulCivilian(akTargetRef as Actor)
    EndIf
EndFunction
