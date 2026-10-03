ScriptName ShellyTillerRecruitScript Extends Actor
{ Auxiliary script for direct Shelly Tiller activation }

MercyRecruitmentQuestScript Property MercyQuest Auto Const

Event OnActivate(ObjectReference akActionRef)
    If akActionRef == Game.GetPlayer()
        If MercyQuest != None
            MercyQuest.ShowShellyDialogue()
        EndIf
    EndIf
EndEvent
