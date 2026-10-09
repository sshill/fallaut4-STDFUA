ScriptName CaravanArmoryChestScript Extends ObjectReference

; References & Quest
DebCaravanSupervisorScript Property SupervisorQuest Auto Const

; Equipment Categories (Auto initialized if empty)
Form[] Property ChestArmors Auto
Form[] Property ArmArmors Auto
Form[] Property LegArmors Auto
Form[] Property HelmetArmors Auto
Form[] Property WeaponItems Auto

Bool Property Initialized = False Auto

Function InitializeItemLists()
    If Initialized
        Return
    EndIf
    Initialized = True

    ; Chests
    ChestArmors = new Form[4]
    ChestArmors[0] = Game.GetForm(0x0011D3C3) ; Combat Torso
    ChestArmors[1] = Game.GetForm(0x0007B9C6) ; Leather Torso
    ChestArmors[2] = Game.GetForm(0x000536C4) ; Metal Torso
    ChestArmors[3] = Game.GetForm(0x0022DA5A) ; Sturdy Leather Torso

    ; Arms
    ArmArmors = new Form[6]
    ArmArmors[0] = Game.GetForm(0x0011D3C7) ; Combat Arm Left
    ArmArmors[1] = Game.GetForm(0x0011D3C6) ; Combat Arm Right
    ArmArmors[2] = Game.GetForm(0x0007B9C7) ; Leather Arm Left
    ArmArmors[3] = Game.GetForm(0x0007B9C3) ; Leather Arm Right
    ArmArmors[4] = Game.GetForm(0x0004B933) ; Metal Arm Left
    ArmArmors[5] = Game.GetForm(0x000536C1) ; Metal Arm Right

    ; Legs
    LegArmors = new Form[6]
    LegArmors[0] = Game.GetForm(0x0011D3C5) ; Combat Leg Left
    LegArmors[1] = Game.GetForm(0x0011D3C4) ; Combat Leg Right
    LegArmors[2] = Game.GetForm(0x0007B9C4) ; Leather Leg Left
    LegArmors[3] = Game.GetForm(0x0007B9C5) ; Leather Leg Right
    LegArmors[4] = Game.GetForm(0x000536C2) ; Metal Leg Left
    LegArmors[5] = Game.GetForm(0x000536C3) ; Metal Leg Right

    ; Helmets
    HelmetArmors = new Form[4]
    HelmetArmors[0] = Game.GetForm(0x0011E2C8) ; Combat Helmet
    HelmetArmors[1] = Game.GetForm(0x000787D3) ; Metal Helmet
    HelmetArmors[2] = Game.GetForm(0x00023432) ; Army Helmet
    HelmetArmors[3] = Game.GetForm(0x00140C3D) ; Mining Helmet

    ; Weapons
    WeaponItems = new Form[6]
    WeaponItems[0] = Game.GetForm(0x000DF42E) ; Combat Rifle
    WeaponItems[1] = Game.GetForm(0x0000463F) ; Assault Rifle
    WeaponItems[2] = Game.GetForm(0x0004F46A) ; Hunting Rifle
    WeaponItems[3] = Game.GetForm(0x0009983B) ; Laser Gun
    WeaponItems[4] = Game.GetForm(0x00100AE9) ; Plasma Gun
    WeaponItems[5] = Game.GetForm(0x00087BA5) ; Combat Shotgun
EndFunction

Int Function GetTotalCountInContainer(Form[] akForms)
    If akForms == None
        Return 0
    EndIf
    Int i = 0
    Int total = 0
    While (i < akForms.Length)
        If (akForms[i] != None)
            total += Self.GetItemCount(akForms[i])
        EndIf
        i += 1
    EndWhile
    Return total
EndFunction

Int Function CalculateCompleteSets()
    InitializeItemLists()
    Int countChests = GetTotalCountInContainer(ChestArmors)
    Int countArms = GetTotalCountInContainer(ArmArmors) / 2
    Int countLegs = GetTotalCountInContainer(LegArmors) / 2
    Int countHelmets = GetTotalCountInContainer(HelmetArmors)
    Int countWeapons = GetTotalCountInContainer(WeaponItems)

    Int completeSets = countChests
    If countArms < completeSets
        completeSets = countArms
    EndIf
    If countLegs < completeSets
        completeSets = countLegs
    EndIf
    If countHelmets < completeSets
        completeSets = countHelmets
    EndIf
    If countWeapons < completeSets
        completeSets = countWeapons
    EndIf

    Return completeSets
EndFunction

Function RemoveItemsFromCategory(Form[] akForms, Int aiCountNeeded)
    If akForms == None || aiCountNeeded <= 0
        Return
    EndIf
    Int remaining = aiCountNeeded
    Int i = 0
    While (i < akForms.Length && remaining > 0)
        Form currentForm = akForms[i]
        If currentForm != None
            Int available = Self.GetItemCount(currentForm)
            If available > 0
                Int toRemove = available
                If toRemove > remaining
                    toRemove = remaining
                EndIf
                Self.RemoveItem(currentForm, toRemove, True, None)
                remaining -= toRemove
            EndIf
        EndIf
        i += 1
    EndWhile
EndFunction

Function ConsumeSets(Int aiSets)
    If aiSets <= 0
        Return
    EndIf
    InitializeItemLists()
    RemoveItemsFromCategory(ChestArmors, aiSets)
    RemoveItemsFromCategory(ArmArmors, aiSets * 2)
    RemoveItemsFromCategory(LegArmors, aiSets * 2)
    RemoveItemsFromCategory(HelmetArmors, aiSets)
    RemoveItemsFromCategory(WeaponItems, aiSets)
EndFunction

Event OnClose(ObjectReference akActionRef)
    Int sets = CalculateCompleteSets()
    Debug.Notification("Скриня арсеналу: знайдено " + sets + " повних комплектів.")
    If SupervisorQuest != None
        SupervisorQuest.OnChestInventoryChecked(Self, sets)
    EndIf
EndEvent
