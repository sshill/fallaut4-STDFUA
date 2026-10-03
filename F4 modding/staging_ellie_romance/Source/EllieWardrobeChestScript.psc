ScriptName EllieWardrobeChestScript Extends ObjectReference

EllieRomanceEncounterScript Property RomanceQuest Auto Const

Event OnClose(ObjectReference akActionRef)
    If RomanceQuest != None
        RomanceQuest.ProcessDonatedDresses(Self)
    EndIf
EndEvent
