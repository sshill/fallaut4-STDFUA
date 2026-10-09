#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Binary Builder for DebCaravanRomance.esp
Creation Engine Plugin for Fallout 4
- Masters: Fallout4.esm
- CONT: DebCaravanArmoryChestCONT (0x01000801) - «Скриня арсеналу караванів»
- QUST: DebCaravanSupervisorQuest (0x01000800) - «Королева доріг»
"""

import os
import struct

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_ESP = os.path.join(SCRIPT_DIR, "DebCaravanRomance.esp")

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

def main():
    print("Building DebCaravanRomance.esp («Королева доріг»)...")

    # 1. TES4 Header
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 2, 0x00000802))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Deb Bunker Hill Caravan Romance & Armory - «Королева доріг»\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. CONT Record: DebCaravanArmoryChestCONT (0x01000801)
    cont_sub = b""
    cont_sub += make_subrecord("EDID", "DebCaravanArmoryChestCONT\x00")
    cont_sub += make_subrecord("FULL", "Скриня арсеналу караванів\x00")
    cont_sub += make_subrecord("OBND", b"\xef\xff\xe6\xff\x00\x00\x11\x00\x19\x00a\x00")
    cont_sub += make_subrecord("MODL", "SetDressing\\Toolbox\\ToolChest.nif\x00")
    cont_sub += make_subrecord("DATA", b"\x02\x00\x00\x00\x00")
    cont_sub += make_subrecord("SNAM", struct.pack("<I", 0x001B0652)) # Open Sound
    cont_sub += make_subrecord("QNAM", struct.pack("<I", 0x001B0653)) # Close Sound
    # VMAD for Chest
    chest_props = [
        ("SupervisorQuest", 1, 0x01000800)
    ]
    cont_sub += build_vmad([("CaravanArmoryChestScript", chest_props)])
    cont_rec = make_record("CONT", 0x01000801, 0, cont_sub)
    grup_cont = make_group("CONT", cont_rec)

    # 3. QUST Record: DebCaravanSupervisorQuest (0x01000800)
    quest_props = [
        ("DebREF",                 1, 0x0001997D), # Deb ACHR
        ("StocktonREF",            1, 0x00039FE8), # Old Man Stockton ACHR
        ("PlayerREF",              1, 0x00000014), # PlayerRef
        ("BunkerHillLocation",     1, 0x000456FA), # LCTN BunkerHillLocation
        ("LoversEmbracePerkSpell", 1, 0x000F3C1D), # SPEL Lovers Embrace
        ("FFBunkerHill02",         1, 0x00122221), # QUST Traffic Jam
        ("Caps001",                1, 0x0000000F), # MISC Caps
        ("ArmoryChestBase",        1, 0x01000801), # CONT Base Chest
        ("CaravanTier",            3, 1),          # Int: Current tier
        ("ThreatActive",           5, False),      # Bool: Alert flag
        ("StocktonContractStage",  3, 0),          # Int: Contract state
        ("StocktonRewardCaps",     3, 3500)        # Int: Payout reward
    ]

    qust_sub = b""
    qust_sub += make_subrecord("EDID", "DebCaravanSupervisorQuest\x00")
    qust_sub += make_subrecord("FULL", "Королева доріг\x00")
    qust_sub += build_vmad([("DebCaravanSupervisorScript", quest_props)])

    # DNAM: flags (0x0001 = Start Game Enabled), priority 55
    dnam_bytes = struct.pack("<HBBII", 0x0001, 55, 0, 0, 0)
    qust_sub += make_subrecord("DNAM", dnam_bytes)

    # Stages: INDX (uint16), QSDT (uint8), NAM2
    stages = [
        (10, 0, "Караванний бізнес Деб"),
        (20, 0, "Загроза на торгових шляхах Співдружності"),
        (30, 0, "Військовий підряд Старого Стоктона"),
        (100, 1, "Караванний синдикат під надійним захистом")
    ]
    for s_idx, s_type, s_log in stages:
        qust_sub += make_subrecord("INDX", struct.pack("<H", s_idx))
        qust_sub += make_subrecord("QSDT", struct.pack("<B", s_type))
        if s_log:
            qust_sub += make_subrecord("NAM2", s_log + "\x00")

    # Objectives: QOBJ, FNAM, NNAM
    objectives = [
        (10, 0, "Забезпечити безпеку каравану Деб у Банкер-Гілл"),
        (20, 0, "Завантажити комплект бойового захисту до Скрині арсеналу"),
        (30, 0, "Виконати контракт Стоктона на озброєння 3-х караванів")
    ]
    for o_idx, o_flags, o_text in objectives:
        qust_sub += make_subrecord("QOBJ", struct.pack("<H", o_idx))
        qust_sub += make_subrecord("FNAM", struct.pack("<I", o_flags))
        qust_sub += make_subrecord("NNAM", o_text + "\x00")

    quest_rec = make_record("QUST", 0x01000800, 0, qust_sub)
    grup_qust = make_group("QUST", quest_rec)

    total_plugin = tes4_rec + grup_cont + grup_qust
    with open(OUTPUT_ESP, "wb") as f:
        f.write(total_plugin)

    print(f"Successfully generated {OUTPUT_ESP} ({len(total_plugin)} bytes).")

if __name__ == "__main__":
    main()
