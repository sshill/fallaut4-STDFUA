ScriptName MercyRecruitmentPerkScript Extends Perk Const
{ Script attached to MercyRecruitmentPerk for Add Activate Choice Entry Point }

MercyRecruitmentQuestScript Property MercyQuest Auto Const
Faction Property WorkshopNPCFaction Auto Const

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
    If MercyQuest != None && akTargetRef != None
        If WorkshopNPCFaction != None && (akTargetRef as Actor).IsInFaction(WorkshopNPCFaction)
            (akTargetRef as Actor).OpenInventory(True)
            Return
        EndIf
        MercyQuest.RecruitPeacefulCivilian(akTargetRef as Actor)
    EndIf
EndFunction
