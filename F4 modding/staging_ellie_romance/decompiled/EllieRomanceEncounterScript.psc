ScriptName EllieRomanceEncounterScript Extends Quest

;-- Variables ---------------------------------------
Bool IsEllieInDugoutInn = False
Actor ScarlettActorRef

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
ObjectReference Property DugoutTableMarker Auto
Potion Property BobrovMoonshine Auto
Potion Property WineBottleForm Auto
Potion Property CountryCrossingWineForm Auto
MiscObject Property FlowerVaseForm Auto
Idle Property HeadShakeIdle Auto
Idle Property InspectIdle Auto
Message Property EllieDugoutInnDialogueMessage Auto
ActorValue Property CA_IsRomantic Auto
Faction Property CurrentCompanionFaction Auto
Message Property EllieBarOrderMessage Auto Const
Message Property EllieWineToastMessage Auto Const
ObjectReference Property PlacedMoonshineRef Auto
ObjectReference Property PlacedWineRef Auto
ObjectReference Property PlacedVaseRef Auto
ObjectReference Property PlacedClothTableRef Auto
ObjectReference Property PlacedShotGlass1Ref Auto
ObjectReference Property PlacedShotGlass2Ref Auto
ObjectReference Property PlacedWineGlass1Ref Auto
ObjectReference Property PlacedWineGlass2Ref Auto
ObjectReference Property PlacedScarlettBouquetRef Auto
Bool Property IsWaitingAtDugoutBar = False Auto
Bool Property HasOrderedWine = False Auto
Bool Property IsScarlettAdmiring = False Auto
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

Actor Function GetEllie()
  If EllieREF == None ; #DEBUG_LINE_NO:111
    EllieREF = Game.GetForm(139940) as Actor ; #DEBUG_LINE_NO:112
  EndIf
  Return EllieREF ; #DEBUG_LINE_NO:114
EndFunction

ObjectReference Function GetBed()
  If DugoutInnPlayerBed == None ; #DEBUG_LINE_NO:118
    DugoutInnPlayerBed = Game.GetForm(1283526) as ObjectReference ; #DEBUG_LINE_NO:119
  EndIf
  Return DugoutInnPlayerBed ; #DEBUG_LINE_NO:121
EndFunction

ObjectReference Function GetDeskMarker()
  If EllieDeskMarker == None ; #DEBUG_LINE_NO:125
    EllieDeskMarker = Game.GetForm(417805) as ObjectReference ; #DEBUG_LINE_NO:126
  EndIf
  Return EllieDeskMarker ; #DEBUG_LINE_NO:128
EndFunction

ObjectReference Function GetWardrobeChest()
  If WardrobeChestRef == None ; #DEBUG_LINE_NO:132
    Actor ellie = Self.GetEllie() ; #DEBUG_LINE_NO:133
    If ellie != None && WardrobeChestBase != None ; #DEBUG_LINE_NO:134
      WardrobeChestRef = ellie.PlaceAtMe(WardrobeChestBase as Form, 1, False, False, False) ; #DEBUG_LINE_NO:136
      If WardrobeChestRef != None ; #DEBUG_LINE_NO:137
        WardrobeChestRef.SetPosition(ellie.GetPositionX() + 40.0, ellie.GetPositionY() + 40.0, ellie.GetPositionZ() - 150.0) ; #DEBUG_LINE_NO:138
      EndIf
    EndIf
  EndIf
  Return WardrobeChestRef ; #DEBUG_LINE_NO:142
EndFunction

ObjectReference Function GetBarberChair()
  If BarberChairRef == None ; #DEBUG_LINE_NO:146
    BarberChairRef = Game.GetForm(204719) as ObjectReference ; #DEBUG_LINE_NO:147
  EndIf
  Return BarberChairRef ; #DEBUG_LINE_NO:149
EndFunction

MiscObject Function GetCapsItem()
  If CapsItem == None ; #DEBUG_LINE_NO:153
    CapsItem = Game.GetForm(15) as MiscObject ; #DEBUG_LINE_NO:154
  EndIf
  Return CapsItem ; #DEBUG_LINE_NO:156
EndFunction

Sound Function GetBarberCutSound()
  If BarberCutSound == None ; #DEBUG_LINE_NO:160
    BarberCutSound = Game.GetForm(2393336) as Sound ; #DEBUG_LINE_NO:161
  EndIf
  Return BarberCutSound ; #DEBUG_LINE_NO:163
EndFunction

Sound Function GetBarberBrushSound()
  If BarberBrushSound == None ; #DEBUG_LINE_NO:167
    BarberBrushSound = Game.GetForm(2393335) as Sound ; #DEBUG_LINE_NO:168
  EndIf
  Return BarberBrushSound ; #DEBUG_LINE_NO:170
EndFunction

ObjectReference Function GetDugoutTableMarker()
  If DugoutTableMarker == None ; #DEBUG_LINE_NO:174
    DugoutTableMarker = Game.GetForm(1867546) as ObjectReference ; #DEBUG_LINE_NO:175
  EndIf
  Return DugoutTableMarker ; #DEBUG_LINE_NO:177
EndFunction

Potion Function GetBobrovMoonshine()
  If BobrovMoonshine == None ; #DEBUG_LINE_NO:181
    BobrovMoonshine = Game.GetForm(222911) as Potion ; #DEBUG_LINE_NO:182
  EndIf
  Return BobrovMoonshine ; #DEBUG_LINE_NO:184
EndFunction

Potion Function GetWineBottle()
  If WineBottleForm == None ; #DEBUG_LINE_NO:188
    WineBottleForm = Game.GetForm(222914) as Potion ; #DEBUG_LINE_NO:189
  EndIf
  Return WineBottleForm ; #DEBUG_LINE_NO:191
EndFunction

MiscObject Function GetFlowerVase()
  If FlowerVaseForm == None ; #DEBUG_LINE_NO:195
    FlowerVaseForm = Game.GetForm(706790) as MiscObject ; #DEBUG_LINE_NO:196
  EndIf
  Return FlowerVaseForm ; #DEBUG_LINE_NO:198
EndFunction

Idle Function GetHeadShakeIdle()
  If HeadShakeIdle == None ; #DEBUG_LINE_NO:202
    HeadShakeIdle = Game.GetForm(232570) as Idle ; #DEBUG_LINE_NO:203
  EndIf
  Return HeadShakeIdle ; #DEBUG_LINE_NO:205
EndFunction

ActorValue Function GetCA_IsRomantic()
  If CA_IsRomantic == None ; #DEBUG_LINE_NO:209
    CA_IsRomantic = Game.GetForm(1347062) as ActorValue ; #DEBUG_LINE_NO:210
  EndIf
  Return CA_IsRomantic ; #DEBUG_LINE_NO:212
EndFunction

Faction Function GetCurrentCompanionFaction()
  If CurrentCompanionFaction == None ; #DEBUG_LINE_NO:216
    CurrentCompanionFaction = Game.GetForm(146433) as Faction ; #DEBUG_LINE_NO:217
  EndIf
  Return CurrentCompanionFaction ; #DEBUG_LINE_NO:219
EndFunction

Potion Function GetCountryCrossingWine()
  If CountryCrossingWineForm == None ; #DEBUG_LINE_NO:223
    CountryCrossingWineForm = Game.GetFormFromFile(2144, "EllieRomance.esp") as Potion ; #DEBUG_LINE_NO:224
  EndIf
  If CountryCrossingWineForm == None ; #DEBUG_LINE_NO:226
    CountryCrossingWineForm = Game.GetForm(16779360) as Potion ; #DEBUG_LINE_NO:227
  EndIf
  If CountryCrossingWineForm == None ; #DEBUG_LINE_NO:229
    CountryCrossingWineForm = Self.GetWineBottle() ; #DEBUG_LINE_NO:230
  EndIf
  Return CountryCrossingWineForm ; #DEBUG_LINE_NO:232
EndFunction

Message Function GetEllieDugoutInnDialogueMessage()
  If EllieDugoutInnDialogueMessage != None ; #DEBUG_LINE_NO:236
    Return EllieDugoutInnDialogueMessage ; #DEBUG_LINE_NO:237
  EndIf
  Return Game.GetFormFromFi