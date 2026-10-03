#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Binary Builder for MercyRecruitment.esp
Generates standard Bethesda Plugin (TES4 / Creation Engine format)
Masters: Fallout4.esm (Index 0)
Features:
- NPC_ override: MS04ShellyTiller (FormID 0x000E1D27) with workshopnpcscript & WorkshopNPCFaction
- MESG: ShellyRecruitDialogueMessage (FormID 0x01000801)
- MESG: CivilianRecruitDialogueMessage (FormID 0x01000803)
- PERK: MercyRecruitmentPerk (FormID 0x01000802) with Add Activate Choice (Fragment_Entry_00)
- QUST: MercyRecruitmentQuest (FormID 0x01000800) with MercyRecruitmentQuestScript
"""

import os
import struct
import zlib

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FALLOUT4_ESM = "/home/hills/Documents/fallaut/game/Data/Fallout4.esm"
TARGET_ESP = os.path.join(SCRIPT_DIR, "MercyRecruitment.esp")

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

def build_perk_fragment_vmad(script_name, props, fragments):
    """Encodes Perk script fragment VMAD (ver=6, fmt=2, scount=0, frag_flags=3)."""
    data = struct.pack("<HHHB", 6, 2, 0, 3)
    sname_bytes = script_name.encode("latin1")
    data += struct.pack("<H", len(sname_bytes)) + sname_bytes
    data += struct.pack("<BH", 0, len(props))
    for pname, ptype, pval in props:
        pname_bytes = pname.encode("latin1")
        data += struct.pack("<H", len(pname_bytes)) + pname_bytes
        data += struct.pack("<BB", ptype, 1)
        if ptype == 1: # Form
            data += struct.pack("<HhI", 0, -1, pval)
        elif ptype == 5: # Bool
            data += struct.pack("<B", 1 if pval else 0)
    # Fragments list
    data += struct.pack("<H", len(fragments))
    for entry_idx, fn_script, fn_name in fragments:
        data += struct.pack("<IB", entry_idx, 1)
        sb = fn_script.encode("latin1")
        data += struct.pack("<H", len(sb)) + sb
        fb = fn_name.encode("latin1")
        data += struct.pack("<H", len(fb)) + fb
    return make_subrecord("VMAD", data)

def extract_and_modify_npc(form_id, offset, make_essential=False, make_protected=True):
    """Extracts base NPC_ from Fallout4.esm and adds workshop capabilities."""
    with open(FALLOUT4_ESM, "rb") as f:
        f.seek(offset)
        rec_head = f.read(24)
        sig, rlen, rflags, rformid = struct.unpack("<4sIII", rec_head[:16])
        rec_data = f.read(rlen)
        if rflags & 0x00040000:
            rec_data = zlib.decompress(rec_data[4:])
            
    vmad_props = [
        ("bAllowCaravan", 5, True),
        ("WorkshopParent", 1, 0x0002058E),
        ("bAllowMove", 5, True),
        ("bCommandable", 5, True),
        ("bCountsForPopulation", 5, True),
    ]
    vmad_sub = build_vmad([("workshopnpcscript", vmad_props)])
    
    pos = 0
    new_data = b""
    snam_added = False
    while pos < len(rec_data):
        ssig, slen = struct.unpack("<4sH", rec_data[pos:pos+6])
        sbody = rec_data[pos+6:pos+6+slen]
        
        if ssig == b"EDID":
            new_data += rec_data[pos:pos+6+slen]
            new_data += vmad_sub
        elif ssig == b"ACBS":
            flags, mag, hp, ap = struct.unpack("<IIHH", sbody[:12])
            if make_essential:
                flags |= 0x02 # Set Essential flag
            if make_protected:
                flags |= 0x800 # Set Protected flag
            new_acbs = struct.pack("<IIHH", flags, mag, hp, ap) + sbody[12:]
            new_data += make_subrecord("ACBS", new_acbs)
        elif ssig == b"SNAM" and not snam_added:
            new_data += make_subrecord("SNAM", struct.pack("<IB", 0x000337F3, 0xFF)) # WorkshopNPCFaction
            new_data += rec_data[pos:pos+6+slen]
            snam_added = True
        else:
            new_data += rec_data[pos:pos+6+slen]
        pos += 6 + slen
        
    return make_record("NPC_", form_id, 0, new_data)

NPC_OVERRIDES = [
    (0x000BBF84, 19245698, False, True, "LvlPrewarCultist"),
    (0x000BBF86, 19244318, False, True, "EncPrewarCultist01"),
    (0x000BEBA2, 19231829, False, True, "LvlPrewarCultistGuard"),
    (0x000E1D27, 19129327, True, False, "MS04ShellyTiller"),
    (0x0019EFB9, 18544165, False, True, "EncPrewarCultist02"),
    (0x0019EFBA, 18543041, False, True, "EncPrewarCultist03"),
    (0x0019EFBB, 18541926, False, True, "EncPrewarCultist04"),
    (0x0019EFBC, 18540819, False, True, "EncPrewarCultist05"),
    (0x0019EFBD, 18539732, False, True, "EncPrewarCultist06"),
]

def make_civilian_recruit_mesg():
    mesg_sub = b""
    mesg_sub += make_subrecord("EDID", "CivilianRecruitDialogueMessage\x00")
    mesg_sub += make_subrecord("DESC", "Ви зустріли мирного жителя Пустки. Що ви запропонуєте йому?\x00")
    mesg_sub += make_subrecord("FULL", "Вербування до поселення\x00")
    mesg_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg_sub += make_subrecord("DNAM", struct.pack("<I", 1)) # Modal message box
    mesg_sub += make_subrecord("ITXT", "«У мене є захищене поселення. Приєднуйся до нас (Харизма 6+)»\x00")
    mesg_sub += make_subrecord("ITXT", "«Ось 50 кришок та припаси на дорогу — вирушай до нас»\x00")
    mesg_sub += make_subrecord("ITXT", "«Бувай (Скасувати)»\x00")
    return make_record("MESG", 0x01000803, 0, mesg_sub)

def make_mercy_recruitment_perk():
    perk_sub = b""
    perk_sub += make_subrecord("EDID", "MercyRecruitmentPerk\x00")
    perk_sub += make_subrecord("FULL", "Авторитет Мінітмена\x00")
    perk_sub += make_subrecord("DESC", "Дозволяє запрошувати нейтральних мирних жителів Співдружності до своїх поселень.\x00")
    
    # VMAD on PERK with Fragment_Entry_00
    props = [("MercyQuest", 1, 0x01000800)]
    frags = [(0, "MercyRecruitmentPerkScript", "Fragment_Entry_00")]
    perk_sub += build_perk_fragment_vmad("MercyRecruitmentPerkScript", props, frags)
    
    # DATA: num ranks 1, playable false
    perk_sub += make_subrecord("DATA", struct.pack("<BBBBB", 0, 0, 1, 0, 0))
    
    # PRKE: Entry Point 2 (Add Activate Choice)
    perk_sub += make_subrecord("PRKE", struct.pack("<BBB", 2, 0, 0))
    # Entry DATA: priority 14, flags 9, num args 2
    perk_sub += make_subrecord("DATA", struct.pack("<BBB", 14, 9, 2))
    
    # Conditions: Target has ActorTypeNPC (0x00013794) == 1.0, Target GetDead == 0.0, Target not in WorkshopNPCFaction == 0.0
    # PRKC: 1 = run on target
    perk_sub += make_subrecord("PRKC", b"\x01")
    
    # CTDA 1: HasKeyword(ActorTypeNPC 0x00013794) == 1.0
    ctda_kw = bytearray.fromhex("009b1b000000803f3002000094370100000000000000000000000000ffffffff")
    perk_sub += make_subrecord("CTDA", bytes(ctda_kw))
    
    # CTDA 2: GetDead == 0.0
    ctda_dead = bytearray.fromhex("009b1b00000000002e00000000000000000000000000000000000000ffffffff")
    perk_sub += make_subrecord("CTDA", bytes(ctda_dead))
    
    # CTDA 3: IsInFaction(WorkshopNPCFaction 0x000337F3) == 0.0
    ctda_fac = bytearray.fromhex("009b1b000000000047000000f3370300000000000000000000000000ffffffff")
    perk_sub += make_subrecord("CTDA", bytes(ctda_fac))
    
    # EPFT: 4 (String ID)
    perk_sub += make_subrecord("EPFT", b"\x04")
    perk_sub += make_subrecord("EPFB", b"\x00\x00")
    perk_sub += make_subrecord("EPF2", struct.pack("<I", 0x00031DE1)) # "ВІДПРАВИТИ ДОДОМУ"
    perk_sub += make_subrecord("EPF3", b"\x00\x00")
    perk_sub += make_subrecord("PRKF", b"")
    
    return make_record("PERK", 0x01000802, 0, perk_sub)

def main():
    print("Building MercyRecruitment.esp...")

    # 1. TES4 Header
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 1, 0x00000801))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Mercy & Settler Recruitment - Шеллі Тіллер та мирні поселенці\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. NPC_ Override Records (Shelly Tiller + 8 Cultist base records)
    npc_recs = b""
    for fid, offset, ess, prot, edid in NPC_OVERRIDES:
        rec = extract_and_modify_npc(fid, offset, make_essential=ess, make_protected=prot)
        npc_recs += rec
        print(f"  Added NPC_ override: {edid} (0x{fid:08X})")
    grup_npc = make_group("NPC_", npc_recs)

    # 3. MESG Records: ShellyRecruitDialogueMessage (0x01000801), CivilianRecruitDialogueMessage (0x01000803)
    mesg1_sub = b""
    mesg1_sub += make_subrecord("EDID", "ShellyRecruitDialogueMessage\x00")
    mesg1_sub += make_subrecord("DESC", "Шеллі тремтить від страху, очікуючи розправи найманців Кендри.\x00")
    mesg1_sub += make_subrecord("FULL", "Шеллі Тіллер\x00")
    mesg1_sub += make_subrecord("INAM", struct.pack("<I", 0))
    mesg1_sub += make_subrecord("DNAM", struct.pack("<I", 1)) # Modal message box
    mesg1_sub += make_subrecord("ITXT", "«Тобі більше не треба ховатися серед гулів. У мене є безпечне поселення — вирушай туди.»\x00")
    mesg1_sub += make_subrecord("ITXT", "«Кендра надіслала мене вбити тебе, але я не вбиваю беззахисних. Тікай звідси.»\x00")
    mesg1_sub += make_subrecord("ITXT", "«Залишайся тут, я скоро повернуся.»\x00")
    mesg1_rec = make_record("MESG", 0x01000801, 0, mesg1_sub)

    mesg2_rec = make_civilian_recruit_mesg()
    grup_mesg = make_group("MESG", mesg1_rec + mesg2_rec)

    # 4. PERK Record: MercyRecruitmentPerk (0x01000802)
    perk_rec = make_mercy_recruitment_perk()
    grup_perk = make_group("PERK", perk_rec)

    # 5. QUST Record: MercyRecruitmentQuest (0x01000800)
    PROPERTIES = [
        ("ShellyRef",                         1, 0x000E1D28),
        ("PiperRef",                          1, 0x00002F1F),
        ("WorkshopParent",                    1, 0x0002058E),
        ("MS04",                              1, 0x00027556),
        ("CA_Affinity",                       1, 0x000A1B80),
        ("CurrentCompanionFaction",           1, 0x00023C01),
        ("WorkshopNPCFaction",                1, 0x000337F3),
        ("REIgnoreForCleanup",                1, 0x0005DDA8),
        ("PlayerFaction",                     1, 0x0001C21C),
        ("REDialogueRescued",                 1, 0x0002F126),
        ("WorkshopAssignHomePermanentActor",  1, 0x0014FC3B),
        ("ShellyRecruitDialogueMessage",      1, 0x01000801),
        ("CharismaAV",                        1, 0x000002C5),
        ("CapsItem",                          1, 0x0000000F),
        ("MercyRecruitmentPerk",              1, 0x01000802),
        ("CivilianRecruitDialogueMessage",    1, 0x01000803),
        ("IsShellyRecruited",                 5, False),
        ("IsShellySpared",                    5, False)
    ]

    qust_sub = b""
    qust_sub += make_subrecord("EDID", "MercyRecruitmentQuest\x00")
    qust_sub += make_subrecord("FULL", "Милосердя та вербування\x00")
    qust_sub += build_vmad([("MercyRecruitmentQuestScript", PROPERTIES)])

    # DNAM: flags (0x0001 = Start Game Enabled), priority 50
    dnam_bytes = struct.pack("<HBBII", 0x0001, 50, 0, 0, 0)
    qust_sub += make_subrecord("DNAM", dnam_bytes)

    quest_rec = make_record("QUST", 0x01000800, 0, qust_sub)
    grup_qust = make_group("QUST", quest_rec)

    total_plugin = tes4_rec + grup_npc + grup_mesg + grup_perk + grup_qust
    with open(TARGET_ESP, "wb") as f:
        f.write(total_plugin)

    print(f"Successfully generated {TARGET_ESP} ({len(total_plugin)} bytes).")

if __name__ == "__main__":
    main()
