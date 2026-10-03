ScriptName Fragments:Scenes:SF_WorkshopRecruitSheffield_0005E1EE Extends Scene Const hidden

;-- Variables ---------------------------------------

;-- Properties --------------------------------------
ReferenceAlias Property WorkshopRecruitSheffield Auto Const

;-- Functions ---------------------------------------

Function Fragment_End()
  workshopparentscript kmyQuest = Self.GetOwningQuest() as workshopparentscript ; #DEBUG_LINE_NO:7
  kmyQuest.AddToWorkshopRecruitAlias(None) ; #DEBUG_LINE_NO:11
EndFunction

Function Fragment_Phase_02_End()
  workshopparentscript kmyQuest = Self.GetOwningQuest() as workshopparentscript ; #DEBUG_LINE_NO:19
  kmyQuest.AddPermanentActorToWorkshopPlayerChoice(WorkshopRecruitSheffield.GetActorRef(), True) ; #DEBUG_LINE_NO:22
EndFunction
