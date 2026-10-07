ScriptName EllieWardrobeChestScript Extends ObjectReference

;-- Variables ---------------------------------------

;-- Properties --------------------------------------
ellieRomanceEncounterScript Property RomanceQuest Auto Const

;-- Functions ---------------------------------------

Event OnClose(ObjectReference akActionRef)
  If RomanceQuest != None ; #DEBUG_LINE_NO:6
    RomanceQuest.ProcessDonatedDresses(Self as ObjectReference) ; #DEBUG_LINE_NO:7
  EndIf
EndEvent
