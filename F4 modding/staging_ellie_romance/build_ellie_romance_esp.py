#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Binary Builder for EllieRomance.esp
Generates standard Bethesda Plugin (TES4 / Creation Engine format)
Masters: Fallout4.esm (Index 0)
Features:
- CONT: EllieWardrobeChest (FormID 0x01000820)
- MESG: EllieDialogueMessage (FormID 0x01000830)
- SNDR: EllieGratitudeSound (FormID 0x01000840)
- SNDR: EllieFlirtSound (FormID 0x01000841)
- QUST: EllieRomanceQuest (FormID 0x01000810)
"""

import os
import struct
import zlib
import mmap

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STAGING_ESP = os.path.join(SCRIPT_DIR, "EllieRomance.esp")
ESM_PATH = "/home/hills/Documents/fallaut/game/Data/Fallout4.esm"

def make_subrecord(sig, data):
    assert len(sig) == 4
    if isinstance(data, str):
        data = data.encode("utf-8") + b"\x00"
    return sig.encode("ascii") + struct.pack("<H", len(data)) + data

def make_record(sig, form_id, flags, data):
    return struct.pack("<4sIIIIHH", sig.encode("ascii"), len(data), flags, form_id, 0, 131, 0) + data

def make_group(label, data, group_type=0):
    total_size = 24 + len(data)
    return struct.pack("<4sI4siHHHH", b"GRUP", total_size, label.encode("ascii"), group_type, 0, 0, 131, 0) + data

def get_npc_decomp(mm, fid):
    target = fid.to_bytes(4, "little")
    p = 0
    while True:
        p = mm.find(b"NPC_", p)
        if p == -1: return None
        if mm[p+12:p+16] == target:
            dsize = int.from_bytes(mm[p+4:p+8], "little")
            flags = int.from_bytes(mm[p+8:p+12], "little")
            raw = mm[p+24:p+24+dsize]
            return zlib.decompress(raw[4:]) if (flags & 0x00040000) else raw
        p += 4

def get_alch_decomp(mm, fid):
    target = fid.to_bytes(4, "little")
    p = 0
    while True:
        p = mm.find(b"ALCH", p)
        if p == -1: return None
        if mm[p+12:p+16] == target:
            dsize = int.from_bytes(mm[p+4:p+8], "little")
            flags = int.from_bytes(mm[p+8:p+12], "little")
            raw = mm[p+24:p+24+dsize]
            return zlib.decompress(raw[4:]) if (flags & 0x00040000) else raw
        p += 4

def build_country_crossing_wine(mm):
    wine_data = get_alch_decomp(mm, 0x000366C2)
    if not wine_data:
        raise RuntimeError("Failed to extract Wine base record from Fallout4.esm")
    subs = parse_subrecords(wine_data)
    wine_body = b""
    for st, slen, sdata in subs:
        if st == "EDID":
            wine_body += make_subrecord("EDID", "EllieRomanceCountryCrossingWine\x00")
        elif st == "FULL":
            wine_body += make_subrecord("FULL", "Кантрі Кроссінг Піно-Нуар (урожай 2075 року)\x00")
        else:
            wine_body += make_subrecord(st, sdata)
    alch_rec = make_record("ALCH", 0x01000860, 0, wine_body)
    return make_group("ALCH", alch_rec)

def parse_subrecords(data):
    pos = 0
    subs = []
    while pos < len(data):
        st = data[pos:pos+4].decode("latin1", "replace")
        slen = int.from_bytes(data[pos+4:pos+6], "little")
        sdata = data[pos+6:pos+6+slen]
        subs.append((st, slen, sdata))
        pos += 6 + slen
    return subs

def build_styled_ellie_npc(mm):
    ellie_data = get_npc_decomp(mm, 0x000222A2) # ElliePerkins
    irma_data = get_npc_decomp(mm, 0x000228A5)  # Irma

    if not ellie_data or not irma_data:
        raise RuntimeError("Failed to extract Ellie or Irma base records from Fallout4.esm")

    ellie_subs = parse_subrecords(ellie_data)
    irma_subs = parse_subrecords(irma_data)

    # Irma's 7 retro makeup tint layers
    irma_tints = [(st, sdata) for st, slen, sdata in irma_subs if st in ["TETI", "TEND"]]

    styled_body = b""
    styled_body += make_subrecord("EDID", "ElliePerkinsStyled\x00")

    for st, slen, sdata in ellie_subs:
        if st == "EDID":
            continue
        elif st in ["TETI", "TEND"]:
            continue
        elif st == "HCLF":
            # Blonde hair 0x0019EE63 like Irma
            styled_body += make_subrecord("HCLF", struct.pack("<I", 0x0019EE63))
        elif st == "MRSV":
            # Insert Irma's 7 tint layers right before MRSV
            for t_st, t_data in irma_tints:
                styled_body += make_subrecord(t_st, t_data)
            styled_body += make_subrecord(st, sdata)
        else:
            styled_body += make_subrecord(st, sdata)

    npc_rec = make_record("NPC_", 0x01000850, 0, styled_body)
    return make_group("NPC_", npc_rec)

def build_vmad(script_defs):
    data = struct.pack("<HHH", 6, 2, len(script_defs))
    for sname, props in script_defs:
        sname_bytes = sname.encode("latin1")
        data += struct.pack("<H", len(sname_bytes)) + sname_bytes
        data += struct.pack("<BH", 0, len(props))
        for pname, ptype, pval in props:
            pname_bytes = pname.encode("latin1")
            data += struct.pack("<H", len(pname_bytes)) + pname_bytes
            data += struct.pack("<BB", ptype, 1)
            if ptype == 1:   # Form (FormID)
                data += struct.pack("<HhI", 0, -1, pval)
            elif ptype == 2: # String
                sb = pval.encode("latin1")
                data += struct.pack("<H", len(sb)) + sb
            elif ptype == 3: # Int
                data += struct.pack("<i", pval)
            elif ptype == 4: # Float
                data += struct.pack("<f", pval)
            elif ptype == 5: # Bool
                data += struct.pack("<B", 1 if pval else 0)
    return make_subrecord("VMAD", data)

def main():
    print("Building EllieRomance.esp with CONT, MESG, SNDR, QUST...")

    # 1. TES4 Header
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 1, 0x00000801))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Ellie Perkins Romance Overhaul - «Мінітмен та джентльмен»\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. CONT Record: EllieWardrobeChest (0x01000820)
    cont_sub = b""
    cont_sub += make_subrecord("EDID", "EllieWardrobeChest\x00")
    cont_sub += make_subrecord("OBND", b"\xd4\xff\xc2\xff\x02\x00\x1c\x00>\x00Y\x00")
    cont_sub += make_subrecord("FULL", "Гардероб Еллі\x00")
    cont_sub += make_subrecord("MODL", "SetDressing\\WoodFurnitureFancy\\FancyDresser01.nif\x00")
    cont_sub += make_subrecord("DATA", b"\x00\x00\x00\x00\x00")
    cont_sub += make_subrecord("SNAM", struct.pack("<I", 0x0022BC3A))
    cont_sub += make_subrecord("QNAM", struct.pack("<I", 0x0022BC3B))
    cont_vmad_props = [("RomanceQuest", 1, 0x01000810)]
    cont_sub += build_vmad([("EllieWardrobeChestScript", cont_vmad_props)])
    cont_rec = make_record("CONT", 0x01000820, 0, cont_sub)
    grup_cont = make_group("CONT", cont_rec)

    # 3. MESG Records: EllieDialogueMessage (0x01000830), EllieWardrobeSelectMessage (0x01000831), EllieWardrobeSelectMessage2 (0x01000832)
    mesg_sub = b""
    mesg_sub += make_subrecord("EDID", "EllieDialogueMessage\x00")
    mesg_sub += make_subrecord("DESC", "Що ви хочете сказати Еллі?\x00")
    mesg_sub += make_subrecord("FULL", "Еллі Перкінс\x00")
    mesg_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg_sub += make_subrecord("DNAM", struct.pack("<I", 1)) # Modal message box
    mesg_sub += make_subrecord("ITXT", "Ходімо до перукарні Джона (Оновити зачіску)\x00")
    mesg_sub += make_subrecord("ITXT", "Поглянь, що я приніс (Гардероб)\x00")
    mesg_sub += make_subrecord("ITXT", "Приміряй сукню (Вибрати вбрання)\x00")
    mesg_sub += make_subrecord("ITXT", "Флірт\x00")
    mesg_sub += make_subrecord("ITXT", "Бувай\x00")
    mesg_rec = make_record("MESG", 0x01000830, 0, mesg_sub)

    # Wardrobe Select Menu 1
    mesg2_sub = b""
    mesg2_sub += make_subrecord("EDID", "EllieWardrobeSelectMessage\x00")
    mesg2_sub += make_subrecord("DESC", "Оберіть сукню для Еллі або налаштуйте гардероб:\x00")
    mesg2_sub += make_subrecord("FULL", "Гардероб Еллі: Вибір сукні\x00")
    mesg2_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg2_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg2_sub += make_subrecord("ITXT", "Автоматичний цикл (Щодня нова сукня)\x00")
    mesg2_sub += make_subrecord("ITXT", "Зелена довоєнна сукня\x00")
    mesg2_sub += make_subrecord("ITXT", "Синя домашня сукня\x00")
    mesg2_sub += make_subrecord("ITXT", "Рожева сукня\x00")
    mesg2_sub += make_subrecord("ITXT", "Вечірня з блискітками (Sequin)\x00")
    mesg2_sub += make_subrecord("ITXT", "Спокуслива вечірня (Slinky)\x00")
    mesg2_sub += make_subrecord("ITXT", "Інші сукні...\x00")
    mesg2_sub += make_subrecord("ITXT", "Забрати стару сукню собі в колекцію\x00")
    mesg2_sub += make_subrecord("ITXT", "Назад\x00")
    mesg2_rec = make_record("MESG", 0x01000831, 0, mesg2_sub)

    # Wardrobe Select Menu 2 (Submenu)
    mesg3_sub = b""
    mesg3_sub += make_subrecord("EDID", "EllieWardrobeSelectMessage2\x00")
    mesg3_sub += make_subrecord("DESC", "Оберіть додаткову сукню для Еллі:\x00")
    mesg3_sub += make_subrecord("FULL", "Гардероб Еллі: Додаткові сукні\x00")
    mesg3_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg3_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg3_sub += make_subrecord("ITXT", "Трояндова домашня сукня\x00")
    mesg3_sub += make_subrecord("ITXT", "Джинсова повсякденна сукня\x00")
    mesg3_sub += make_subrecord("ITXT", "Кремова довоєнна сукня\x00")
    mesg3_sub += make_subrecord("ITXT", "Назад до вибору суконь\x00")
    mesg3_rec = make_record("MESG", 0x01000832, 0, mesg3_sub)

    # 0x01000833: EllieBarbershopMessage
    mesg4_sub = b""
    mesg4_sub += make_subrecord("EDID", "EllieBarbershopMessage\x00")
    mesg4_sub += make_subrecord("DESC", "Еллі чекає у кріслі перукаря Джона. Оновити зачіску та макіяж у стилі Ірми?\x00")
    mesg4_sub += make_subrecord("FULL", "Перукарня Джона: Еллі Перкінс\x00")
    mesg4_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg4_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg4_sub += make_subrecord("ITXT", "Зробити макіяж та нову зачіску (50 кришок)\x00")
    mesg4_sub += make_subrecord("ITXT", "Приміряти іншу сукню (Вибрати вбрання)\x00")
    mesg4_sub += make_subrecord("ITXT", "Почекай хвилинку (Бувай)\x00")
    mesg4_rec = make_record("MESG", 0x01000833, 0, mesg4_sub)

    # 0x01000834: EllieBarOrderMessage
    mesg5_sub = b""
    mesg5_sub += make_subrecord("EDID", "EllieBarOrderMessage\x00")
    mesg5_sub += make_subrecord("DESC", "Вадим: «У «Даґаут Інн» зазвичай п'ють мій самогон, але зі старих довоєнних запасів для джентльмена знайдеться пляшка марочного вина за 50 кришок.»\x00")
    mesg5_sub += make_subrecord("FULL", "Даґаут Інн: Замовлення вишуканого вина\x00")
    mesg5_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg5_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg5_sub += make_subrecord("ITXT", "[50 кришок] Тримай кришки. Для Еллі — тільки найкраще!\x00")
    mesg5_sub += make_subrecord("ITXT", "[Харизма] Вадиме, ти ж мене знаєш — запиши на мій рахунок!\x00")
    mesg5_sub += make_subrecord("ITXT", "Зачекай хвилинку (Відійти)\x00")
    mesg5_rec = make_record("MESG", 0x01000834, 0, mesg5_sub)

    # 0x01000835: EllieWineToastMessage
    mesg6_sub = b""
    mesg6_sub += make_subrecord("EDID", "EllieWineToastMessage\x00")
    mesg6_sub += make_subrecord("DESC", "На столику стоїть пляшка марочного довоєнного вина та ваза зі свіжими квітами. Підняти романтичний келих разом з Еллі?\x00")
    mesg6_sub += make_subrecord("FULL", "Даґаут Інн: Романтичний тост\x00")
    mesg6_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg6_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg6_sub += make_subrecord("ITXT", "Підняти келих марочного вина разом з Еллі (Тост)\x00")
    mesg6_sub += make_subrecord("ITXT", "Залишитися за столиком (Бувай)\x00")
    mesg6_rec = make_record("MESG", 0x01000835, 0, mesg6_sub)

    # 0x01000836: EllieDugoutInnDialogueMessage (Compliments & Dugout Chat)
    mesg7_sub = b""
    mesg7_sub += make_subrecord("EDID", "EllieDugoutInnDialogueMessage\x00")
    mesg7_sub += make_subrecord("DESC", "Еллі виглядає чарівно у вечірній сукні та з новою зачіскою за столиком бару.\x00")
    mesg7_sub += make_subrecord("FULL", "Даґаут Інн: Розмова з Еллі\x00")
    mesg7_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg7_sub += make_subrecord("DNAM", struct.pack("<I", 1))
    mesg7_sub += make_subrecord("ITXT", "Ти виглядаєш просто приголомшливо у цій вечірній сукні!\x00")
    mesg7_sub += make_subrecord("ITXT", "Ця нова зачіска та макіяж підкреслюють твої прекрасні очі...\x00")
    mesg7_sub += make_subrecord("ITXT", "Поруч з тобою цей бар здається найзатишнішим місцем у Співдружності.\x00")
    mesg7_sub += make_subrecord("ITXT", "Як тобі напій на столі?\x00")
    mesg7_sub += make_subrecord("ITXT", "Зачекай хвилинку (Бувай)\x00")
    mesg7_rec = make_record("MESG", 0x01000836, 0, mesg7_sub)

    grup_mesg = make_group("MESG", mesg_rec + mesg2_rec + mesg3_rec + mesg4_rec + mesg5_rec + mesg6_rec + mesg7_rec)

    # 4. SNDR Records: EllieGratitudeSound (0x01000840), EllieFlirtSound (0x01000841)
    # Gratitude
    sndr1_sub = b""
    sndr1_sub += make_subrecord("EDID", "EllieGratitudeSound\x00")
    sndr1_sub += make_subrecord("CNAM", struct.pack("<I", 0x0001EEF5)) # AudioCategoryVoices
    sndr1_sub += make_subrecord("GNAM", struct.pack("<I", 0x000876BB)) # SOMDialogue3D
    sndr1_sub += make_subrecord("ANAM", "data\\Sound\\FX\\EllieRomance\\ellie_gratitude.wav\x00")
    sndr1_sub += make_subrecord("BNAM", b"\x00\x00\x80\x00\x00\x00")
    sndr1_rec = make_record("SNDR", 0x01000840, 0, sndr1_sub)

    # Flirt
    sndr2_sub = b""
    sndr2_sub += make_subrecord("EDID", "EllieFlirtSound\x00")
    sndr2_sub += make_subrecord("CNAM", struct.pack("<I", 0x0001EEF5)) # AudioCategoryVoices
    sndr2_sub += make_subrecord("GNAM", struct.pack("<I", 0x000876BB)) # SOMDialogue3D
    sndr2_sub += make_subrecord("ANAM", "data\\Sound\\FX\\EllieRomance\\ellie_flirt.wav\x00")
    sndr2_sub += make_subrecord("BNAM", b"\x00\x00\x80\x00\x00\x00")
    sndr2_rec = make_record("SNDR", 0x01000841, 0, sndr2_sub)

    grup_sndr = make_group("SNDR", sndr1_rec + sndr2_rec)

    # 5. NPC_ Group: ElliePerkinsStyled (0x01000850) & ALCH Group: CountryCrossingWine (0x01000860)
    with open(ESM_PATH, "rb") as f_esm:
        mm = mmap.mmap(f_esm.fileno(), 0, access=mmap.ACCESS_READ)
        grup_npc = build_styled_ellie_npc(mm)
        grup_alch = build_country_crossing_wine(mm)

    # 6. QUST Record: EllieRomanceQuest (0x01000810)
    PROPERTIES = [
        # Actor & World references
        ("EllieREF",                 1, 0),
        ("DugoutInnPlayerBed",        1, 0),
        ("EllieDeskMarker",          1, 0),
        ("LoversEmbracePerkSpell",   1, 0x000F3C1D),
        ("MQ104",                    1, 0x0001F25E),

        # Barbershop & Makeover References
        ("BarberChairRef",           1, 0x00031FAF), # Diamond City Barber Chair
        ("BarberCutSound",           1, 0x002484F8), # NPCHumanIdleBarberCut
        ("BarberBrushSound",         1, 0x002484F7), # NPCHumanIdleBarberBrush
        ("CapsItem",                 1, 0x0000000F), # Caps001
        ("EllieBarbershopMessage",   1, 0x01000833), # MESG
        ("ElliePerkinsStyledBase",   1, 0x01000850), # NPC_
        ("EllieStyledREF",           1, 0),          # Dynamic runtime ref
        ("IsWaitingAtBarbershop",    5, False),

        # Evening Dresses
        ("EveningSlinkyDress",       1, 0x000FD9A8), # ClothesSlinkyDress
        ("EveningSequinDress",       1, 0x0011A27B), # ClothesSequinDress

        # Day / Clean / Laundered Dresses
        ("CleanGreenDress",          1, 0x000EECF5), # ClothesPreWarDress
        ("CleanRedDress",            1, 0x002075C1), # ClothesPreWarDressPink
        ("CleanRoseDress",           1, 0x002075BF), # ClothesPrewarHouseDressB
        ("CleanBlueDress",           1, 0x0014D08F), # ClothesPrewarHouseDress
        ("CleanDenimDress",          1, 0x002075C0), # ClothesPreWarDressBlue
        ("CleanCreamDress",          1, 0x002075BE), # ClothesPrewarHouseDressA

        # Original / Wasteland Dress
        ("OldWastelandDress",        1, 0x001B828C), # ClothesWastelandDress

        # UI, Container & Audio
        ("EllieDialogueMessage",     1, 0x01000830), # MESG
        ("EllieWardrobeSelectMessage", 1, 0x01000831), # MESG
        ("EllieWardrobeSelectMessage2", 1, 0x01000832), # MESG
        ("EllieGratitudeSound",      1, 0x01000840), # SNDR
        ("EllieFlirtSound",          1, 0x01000841), # SNDR
        ("LaughingSittingIdle",      1, 0x00118015), # IDLE ActionCustomLaughingSittingA
        ("LaughingStandingIdle",     1, 0x00118013), # IDLE ActionCustomLaughingStandingA
        ("WardrobeChestBase",        1, 0x01000820), # CONT
        ("WardrobeChestRef",         1, 0),          # Dynamic runtime ref

        # State Properties
        ("RomanceStage",             3, 0),
        ("IsRomanced",               5, False),
        ("TotalDressesGiven",        3, 0),
        ("EveningDressesGiven",      3, 0),
        ("DayDressesGiven",          3, 0),
        ("ActiveDayDressIndex",      3, 0),
        ("ActiveEveningDressIndex",  3, 0),
        ("CurrentHairstyleIndex",    3, 0),
        ("CurrentManualDressIndex",  3, 0),
        ("EnableDynamicOutfits",     5, True),
        ("AutoReturnAfterDelay",     5, True),
        ("ReturnDelaySeconds",       4, 180.0),

        # Unique dress ownership booleans
        ("HasSlinky",                5, False),
        ("HasSequin",                5, False),
        ("HasCleanGreen",            5, False),
        ("HasCleanRed",              5, False),
        ("HasCleanRose",             5, False),
        ("HasCleanBlue",             5, False),
        ("HasCleanDenim",            5, False),
        ("HasCleanCream",            5, False),

        # Dugout Inn & Romance Finale Properties
        ("DugoutTableMarker",        1, 0x001C7F1A), # DmndDugoutTableMarker01
        ("BobrovMoonshine",          1, 0x000366BF), # BobrovsBestMoonshine
        ("WineBottleForm",           1, 0x000366C2), # Wine
        ("CountryCrossingWineForm",  1, 0x01000860), # ALCH Кантрі Кроссінг Піно-Нуар (урожай 2075 року)
        ("FlowerVaseForm",           1, 0x000AC8E6), # VaseVintageCleanFlowers01a
        ("HeadShakeIdle",            1, 0x00038C7A), # HeadShakeNo
        ("InspectIdle",              1, 0x00061D01), # IDLE Inspect
        ("EllieDugoutInnDialogueMessage", 1, 0x01000836), # MESG EllieDugoutInnDialogueMessage
        ("CA_IsRomantic",            1, 0x00148DF6), # AVIF CA_IsRomantic
        ("CurrentCompanionFaction",   1, 0x00023C01), # FACT CurrentCompanionFaction
        ("EllieBarOrderMessage",     1, 0x01000834), # MESG
        ("EllieWineToastMessage",    1, 0x01000835), # MESG
        ("PlacedMoonshineRef",       1, 0),
        ("PlacedWineRef",            1, 0),
        ("PlacedVaseRef",            1, 0),
        ("IsWaitingAtDugoutBar",     5, False),
        ("HasOrderedWine",           5, False)
    ]

    qust_sub = b""
    qust_sub += make_subrecord("EDID", "EllieRomanceQuest\x00")
    qust_sub += make_subrecord("FULL", "Мінітмен та джентльмен\x00")
    qust_sub += build_vmad([("EllieRomanceEncounterScript", PROPERTIES)])

    # DNAM: flags (0x0001 = Start Game Enabled), priority 55
    dnam_bytes = struct.pack("<HBBII", 0x0001, 55, 0, 0, 0)
    qust_sub += make_subrecord("DNAM", dnam_bytes)

    # Stages: INDX, QSDT, NAM2
    stages = [
        (10, 0, "Збір гардеробу Еллі Перкінс"),
        (20, 0, "Візит до перукарні Джона"),
        (30, 0, "Затишний вечір у «Даґаут Інн»"),
        (100, 1, "Романтичні стосунки активні")
    ]
    for s_idx, s_type, s_log in stages:
        qust_sub += make_subrecord("INDX", struct.pack("<H", s_idx))
        qust_sub += make_subrecord("QSDT", struct.pack("<B", s_type))
        if s_log:
            qust_sub += make_subrecord("NAM2", s_log + "\x00")

    # Objectives: QOBJ, FNAM, NNAM
    objectives = [
        (10, 0, "Оновити гардероб Еллі (принести 4 ошатні сукні, з них щонайменше 1 вечірню)"),
        (20, 0, "Завітати до перукарні Джона на ринку Даймонд-Сіті разом з Еллі"),
        (30, 0, "Провести затишний вечір з Еллі у «Даґаут Інн»")
    ]
    for o_idx, o_flags, o_text in objectives:
        qust_sub += make_subrecord("QOBJ", struct.pack("<H", o_idx))
        qust_sub += make_subrecord("FNAM", struct.pack("<I", o_flags))
        qust_sub += make_subrecord("NNAM", o_text + "\x00")

    quest_rec = make_record("QUST", 0x01000810, 0, qust_sub)
    grup_qust = make_group("QUST", quest_rec)

    total_plugin = tes4_rec + grup_npc + grup_cont + grup_alch + grup_mesg + grup_sndr + grup_qust
    with open(STAGING_ESP, "wb") as f:
        f.write(total_plugin)

    print(f"Successfully generated {STAGING_ESP} ({len(total_plugin)} bytes).")

if __name__ == "__main__":
    main()
