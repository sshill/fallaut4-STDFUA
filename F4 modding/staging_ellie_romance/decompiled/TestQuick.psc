ScriptName TestQuick Extends Quest

;-- Variables ---------------------------------------
Bool IsEllieInDugoutInn = False

;-- Properties --------------------------------------
Actor Property EllieREF Auto
ObjectReference Property DugoutInnPlayerBed Auto
ObjectReference Property EllieDeskMarker Auto
Spell Property LoversEmbracePerkSpell Auto Const
Quest Property MQ104 Auto Const
Armor Property EveningSlinkyDress Auto Const
Armor Property EveningSequinDress Auto Const
Armor Property CleanGreenDress Auto Const
Armor Property CleanRedDress Auto Const
Armor Property CleanRoseDress Auto Const
Armor Property CleanBlueDress Auto Const
Armor Property CleanDenimDress Auto Const
Armor Property CleanCreamDress Auto Const
Armor Property OldWastelandDress Auto
Message Property EllieDialogueMessage Auto Const
Message Property EllieWardrobeSelectMessage Auto Const
Message Property EllieWardrobeSelectMessage2 Auto Const
Sound Property EllieGratitudeSound Auto Const
Sound Property EllieFlirtSound Auto Const
Idle Property LaughingSittingIdle Auto Const
Idle Property LaughingStandingIdle Auto Const
Container Property WardrobeChestBase Auto Const
ObjectReference Property WardrobeChestRef Auto
ObjectReference Property BarberChairRef Auto
Sound Property BarberCutSound Auto
Sound Property BarberBrushSound Auto
MiscObject Property CapsItem Auto
Message Property EllieBarbershopMessage Auto
ActorBase Property ElliePerkinsStyledBase Auto
Actor Property EllieStyledREF Auto
Bool Property IsWaitingAtBarbershop = False Auto
Int Property RomanceStage = 0 Auto
Bool Property IsRomanced = False Auto
Int Property TotalDressesGiven = 0 Auto
Int Property EveningDressesGiven = 0 Auto
Int Property DayDressesGiven = 0 Auto
Int Property ActiveDayDressIndex = 0 Auto
Int Property ActiveEveningDressIndex = 0 Auto
Int Property CurrentHairstyleIndex = 0 Auto
Int Property CurrentManualDressIndex = 0 Auto
Armor Property CurrentEquippedDress Auto
Bool Property EnableDynamicOutfits = True Auto
Bool Property AutoReturnAfterDelay = True Auto
Float Property ReturnDelaySeconds = 180.0 Auto
Bool Property HasSlinky = False Auto
Bool Property HasSequin = False Auto
Bool Property HasCleanGreen = False Auto
Bool Property HasCleanRed = False Auto
Bool Property HasCleanRose = False Auto
Bool Property HasCleanBlue = False Auto
Bool Property HasCleanDenim = False Auto
Bool Property HasCleanCream = False Auto

;-- Functions ---------------------------------------

Event OnInit()
  ; Empty function
EndEvent

Actor Function GetEllie()
  If EllieREF == None ; #DEBUG_LINE_NO:84
    EllieREF = Game.GetForm(139940) as Actor ; #DEBUG_LINE_NO:85
  EndIf
  Return EllieREF ; #DEBUG_LINE_NO:87
EndFunction

ObjectReference Function GetBed()
  If DugoutInnPlayerBed == None ; #DEBUG_LINE_NO:91
    DugoutInnPlayerBed = Game.GetForm(1283526) as ObjectReference ; #DEBUG_LINE_NO:92
  EndIf
  Return DugoutInnPlayerBed ; #DEBUG_LINE_NO:94
EndFunction

ObjectReference Function GetDeskMarker()
  If EllieDeskMarker == None ; #DEBUG_LINE_NO:98
    EllieDeskMarker = Game.GetForm(417805) as ObjectReference ; #DEBUG_LINE_NO:99
  EndIf
  Return EllieDeskMarker ; #DEBUG_LINE_NO:101
EndFunction

ObjectReference Function GetWardrobeChest()
  If WardrobeChestRef == None ; #DEBUG_LINE_NO:105
    Actor ellie = Self.GetEllie() ; #DEBUG_LINE_NO:106
    If ellie != None && WardrobeChestBase != None ; #DEBUG_LINE_NO:107
      WardrobeChestRef = ellie.PlaceAtMe(WardrobeChestBase as Form, 1, False, False, False) ; #DEBUG_LINE_NO:109
      If WardrobeChestRef != None ; #DEBUG_LINE_NO:110
        WardrobeChestRef.SetPosition(ellie.GetPositionX() + 40.0, ellie.GetPositionY() + 40.0, ellie.GetPositionZ() - 150.0) ; #DEBUG_LINE_NO:111
      EndIf
    EndIf
  EndIf
  Return WardrobeChestRef ; #DEBUG_LINE_NO:115
EndFunction

ObjectReference Function GetBarberChair()
  If BarberChairRef == None ; #DEBUG_LINE_NO:119
    BarberChairRef = Game.GetForm(204719) as ObjectReference ; #DEBUG_LINE_NO:120
  EndIf
  Return BarberChairRef ; #DEBUG_LINE_NO:122
EndFunction

MiscObject Function GetCapsItem()
  If CapsItem == None ; #DEBUG_LINE_NO:126
    CapsItem = Game.GetForm(15) as MiscObject ; #DEBUG_LINE_NO:127
  EndIf
  Return CapsItem ; #DEBUG_LINE_NO:129
EndFunction

Sound Function GetBarberCutSound()
  If BarberCutSound == None ; #DEBUG_LINE_NO:133
    BarberCutSound = Game.GetForm(2393336) as Sound ; #DEBUG_LINE_NO:134
  EndIf
  Return BarberCutSound ; #DEBUG_LINE_NO:136
EndFunction

Sound Function GetBarberBrushSound()
  If BarberBrushSound == None ; #DEBUG_LINE_NO:140
    BarberBrushSound = Game.GetForm(2393335) as Sound ; #DEBUG_LINE_NO:141
  EndIf
  Return BarberBrushSound ; #DEBUG_LINE_NO:143
EndFunction
