#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generates binary VintageMannequins.esp plugin for Fallout 4.
Masters: Fallout4.esm, DLCworkshop02.esm
Records:
  - MISC (6 parts: Base, Torso, Head, ArmL, ArmR, Legs)
  - CONT (MannequinAssemblyContainer)
  - MSTT Overrides (MannequinMale01, MannequinFemale01, MannequinRedcoat01, etc.)
"""

import struct
import zlib
import os
import sys

STAND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(STAND_DIR, "game", "Data")
ESP_PATH = os.path.join(DATA_DIR, "VintageMannequins.esp")
FALLOUT4_ESM = os.path.join(DATA_DIR, "Fallout4.esm")

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
            if ptype == 1: # Form
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
    print("Building VintageMannequins.esp...")
    # 1. TES4 Header
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 12, 0x00000808))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Authentic 1950s Store Mannequins Interactive Overhaul\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_sub += make_subrecord("MAST", "DLCworkshop02.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. MISC Items
    misc_items = [
        (0x00000800, "Mannequin_Base", "Монтажна підставка манекена", r"SetDressing\Mannequin\MaleMannequin1.nif", 35, 8.0, [
            ("MannequinBaseDropScript", [("AssemblyContainerBase", 1, 0x02000806)])
        ]),
        (0x00000801, "Mannequin_Torso", "Вінтажний торс манекена", r"SetDressing\Mannequin\MaleMannequin1.nif", 25, 6.0, []),
        (0x00000802, "Mannequin_Head", "Голова вінтажного манекена", r"Actors\DLC05\Mannequin\CharacterAssets\ArmorRack_Female_Head.nif", 15, 2.0, []),
        (0x00000803, "Mannequin_ArmL", "Ліва рука вінтажного манекена", r"Actors\DLC05\Mannequin\CharacterAssets\ArmorRack_Female_Hands.nif", 10, 1.5, []),
        (0x00000804, "Mannequin_ArmR", "Права рука вінтажного манекена", r"Actors\DLC05\Mannequin\CharacterAssets\ArmorRack_Female_Hands.nif", 10, 1.5, []),
        (0x00000805, "Mannequin_Legs", "Пара ніг вінтажного манекена", r"SetDressing\Mannequin\MaleMannequin1.nif", 20, 5.0, [])
    ]

    misc_recs = b""
    for fid, edid, full, modl, val, wt, scripts in misc_items:
        sub = b""
        sub += make_subrecord("EDID", edid + "\x00")
        sub += make_subrecord("OBND", struct.pack("<hhhhhh", -5, -10, 0, 5, 10, 30))
        sub += make_subrecord("FULL", full + "\x00")
        sub += make_subrecord("MODL", modl + "\x00")
        sub += make_subrecord("DATA", struct.pack("<If", val, wt))
        if scripts:
            sub += build_vmad(scripts)
        misc_recs += make_record("MISC", fid, 0, sub)

    grup_misc = make_group("MISC", misc_recs)

    # 3. CONT Item
    cont_sub = b""
    cont_sub += make_subrecord("EDID", "MannequinAssemblyContainer\x00")
    cont_sub += make_subrecord("OBND", struct.pack("<hhhhhh", -15, -15, 0, 15, 15, 80))
    cont_sub += make_subrecord("FULL", "Монтажна підставка манекена\x00")
    cont_sub += make_subrecord("MODL", r"SetDressing\Mannequin\MaleMannequin1.nif" + "\x00")
    cont_sub += make_subrecord("DATA", struct.pack("<Bf", 0, 500.0))
    assembly_scripts = [
        ("MannequinAssemblyScript", [
            ("Mannequin_Torso", 1, 0x02000801),
            ("Mannequin_Head", 1, 0x02000802),
            ("Mannequin_ArmL", 1, 0x02000803),
            ("Mannequin_ArmR", 1, 0x02000804),
            ("Mannequin_Legs", 1, 0x02000805),
            ("VintageMannequinNPC", 1, 0x010008B3) # DLC05WorkshopArmorRackFemale01
        ])
    ]
    cont_sub += build_vmad(assembly_scripts)
    cont_rec = make_record("CONT", 0x00000806, 0, cont_sub)
    grup_cont = make_group("CONT", cont_rec)

    # 4. MSTT Overrides
    harvest_vmad = build_vmad([
        ("MannequinHarvestScript", [
            ("Mannequin_Base", 1, 0x02000800),
            ("Mannequin_Torso", 1, 0x02000801),
            ("Mannequin_Head", 1, 0x02000802),
            ("Mannequin_ArmL", 1, 0x02000803),
            ("Mannequin_ArmR", 1, 0x02000804),
            ("Mannequin_Legs", 1, 0x02000805),
            ("WeaponTypeExplosive", 1, 0x0004C922)
        ])
    ])

    mstt_recs = b""
    target_formids = [0x00036CD5, 0x0003B163, 0x0003FBC3, 0x0014F697, 0x0014F698]
    with open(FALLOUT4_ESM, "rb") as f:
        hdr = f.read(24)
        data_size = int.from_bytes(hdr[4:8], "little")
        f.seek(24 + data_size)
        while True:
            ghdr = f.read(24)
            if len(ghdr) < 24:
                break
            gsize, label = struct.unpack("<I", ghdr[4:8])[0], ghdr[8:12]
            if label == b"MSTT":
                remaining = gsize - 24
                while remaining > 0:
                    rhdr = f.read(24)
                    rsize, rflags, form_id = struct.unpack("<III", rhdr[4:16])
                    rdata = f.read(rsize)
                    remaining -= (24 + rsize)
                    if form_id in target_formids:
                        if rflags & 0x00040000:
                            rdata = zlib.decompress(rdata[4:])
                        new_subrecords = rdata + harvest_vmad
                        clean_flags = rflags & ~0x00040000
                        mstt_recs += make_record("MSTT", form_id, clean_flags, new_subrecords)
                break
            else:
                f.seek(gsize - 24, 1)

    grup_mstt = make_group("MSTT", mstt_recs)

    total_plugin = tes4_rec + grup_misc + grup_cont + grup_mstt
    with open(ESP_PATH, "wb") as f:
        f.write(total_plugin)
    print(f"Successfully generated {ESP_PATH} ({len(total_plugin)} bytes).")

if __name__ == "__main__":
    main()
