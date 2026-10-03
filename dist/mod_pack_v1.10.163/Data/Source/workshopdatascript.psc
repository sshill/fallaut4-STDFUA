ScriptName WorkshopDataScript Extends ScriptObject Const hidden
{ holds struct definitions to allow the compiler to work }

;-- Structs -----------------------------------------
Struct FarmDiscountVendor
  Location VendorLocation
  { vendor's location }
  ActorBase VendorBaseActor
  { vendor's base actor }
EndStruct

Struct WorkshopActorValue
  ActorValue resourceValue
  { the actor value }
  Int workshopRatingIndex
  { index to WorkshopRatings array that matches this actor value }
EndStruct

Struct WorkshopFoodType
  LeveledItem foodObject
  { leveled item to use to create this food type }
  ActorValue resourceValue
  { what resource value matches this food type }
EndStruct

Struct WorkshopRatingKeyword
  Int maxProductionPerNPC = 0
  { if non-zero, indicates a type of resource where a single NPC can work on multiple resource object (e.g. food) }
  ActorValue resourceValue
  { the actor value for this rating }
  Bool clearOnReset
  { true = clear this value when the workshop resets
		false = persistent value (e.g. hope, radio, damage) }
EndStruct

Struct WorkshopVendorType
  GlobalVariable topVendorFlag
  { global tracks count of valid top-level vendor objects }
  Keyword keywordToAdd01
  { keyword to add to the vendor NPC }
  Faction VendorFaction
  { what faction to assign to an NPC who is assigned to work on this object }
  Int minPopulationForTopVendor
  { min population at settlement to qualify for top vendor }
EndStruct

