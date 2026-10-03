#!/usr/bin/env python3
"""
GentlemanOutfitReskin ESP Builder
---------------------------------
Overrides:
1. ARMO 0x000F15D0 (MS10ClothesRewardM / Reginald's Suit) -> Clean Striped Suit (+3 Charisma)
2. ARMO 0x0105159B (DLC03_V118Hat_DONOTPLACE / Dapper Gent) -> White Trilby Hat with Black Band (+2 Charisma)
"""

import struct
import zlib
import os
import sys

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

def get_clean_subrecords(esm_path: str, target_id: int):
    with open(esm_path, 'rb') as f:
        hdr = f.read(24)
        tes4_size = int.from_bytes(hdr[4:8], 'little')
        f.seek(24 + tes4_size)
        while True:
            g = f.read(24)
            if not g: break
            g_size = int.from_bytes(g[4:8], 'little')
            g_label = g[8:12].decode('latin1', errors='ignore')
            if g_label == 'ARMO':
                end = f.tell() - 24 + g_size
                while f.tell() < end:
                    r_hdr = f.read(24)
                    if len(r_hdr) < 24: break
                    r_size = int.from_bytes(r_hdr[4:8], 'little')
                    r_flags = int.from_bytes(r_hdr[8:12], 'little')
                    r_id = int.from_bytes(r_hdr[12:16], 'little')
                    raw = f.read(r_size)
                    if r_id == target_id:
                        if r_flags & 0x00040000:
                            raw = zlib.decompress(raw[4:])
                        subs = []
                        off = 0
                        while off + 6 <= len(raw):
                            stype = raw[off:off+4].decode('latin1')
                            ssize = int.from_bytes(raw[off+4:off+6], 'little')
                            sdata = raw[off+6:off+6+ssize]
                            off += 6 + ssize
                            subs.append((stype, sdata))
                        return r_flags, subs
            f.seek(g_size - 24, 1)
    return None, None

def build_gentleman_esp(output_path: str):
    f4_esm = "/home/hills/Documents/fallaut/game/Data/Fallout4.esm"
    dlc_esm = "/home/hills/Documents/fallaut/game/Data/DLCCoast.esm"

    print("Reading vanilla records from ESMs...")
    reg_flags, reg_subs = get_clean_subrecords(f4_esm, 0x000F15D0)
    dap_flags, dap_subs = get_clean_subrecords(dlc_esm, 0x0105159B)

    if not reg_subs or not dap_subs:
        print("[ERROR] Could not find vanilla records!")
        sys.exit(1)

    # 1. TES4 Header
    # HEDR: float version (0.95), uint32 num_records (2), uint32 next_id (0x00000800)
    hedr = struct.pack('<fII', 0.95, 2, 0x00000800)
    tes4_subs = b""
    tes4_subs += make_subrecord("HEDR", hedr)
    tes4_subs += make_subrecord("CNAM", "Antigravity & Ollama\x00".encode('latin1'))
    tes4_subs += make_subrecord("SNAM", "Reginald Suit & Dapper Gent Hat Reskin\x00".encode('latin1'))
    tes4_subs += make_subrecord("MAST", "Fallout4.esm\x00".encode('latin1'))
    tes4_subs += make_subrecord("DATA", b"\x00" * 8)
    tes4_subs += make_subrecord("MAST", "DLCCoast.esm\x00".encode('latin1'))
    tes4_subs += make_subrecord("DATA", b"\x00" * 8)
    tes4_rec = make_record("TES4", 0, 0, tes4_subs)

    # 2. Modify Reginald's Suit (0x000F15D0)
    # MOD2: 'Clothes\Suit\OutfitGO.nif\x00'
    # MO2S: 0x001BDDF7
    # MODL: 0x001BDDFF (AAClothesSuitClean_Striped)
    reg_new_subs = b""
    for stype, sdata in reg_subs:
        if stype == "MOD2":
            reg_new_subs += make_subrecord("MOD2", b"Clothes\\Suit\\OutfitGO.nif\x00")
            reg_new_subs += make_subrecord("MO2S", struct.pack('<I', 0x001BDDF7))
        elif stype in ["MO2T", "MO2S"]:
            continue # replaced above
        elif stype == "MODL":
            reg_new_subs += make_subrecord("MODL", struct.pack('<I', 0x001BDDFF))
        else:
            reg_new_subs += make_subrecord(stype, sdata)
    reg_rec = make_record("ARMO", 0x000F15D0, 0, reg_new_subs)

    # 3. Modify Dapper Gent Hat (0x0105159B)
    # MOD2: 'Clothes\Residents\4HatGO.nif\x00'
    # MODL: 0x000A36BF (AAClothesResident4Hat - white felt hat with black band)
    dap_new_subs = b""
    for stype, sdata in dap_subs:
        if stype == "MOD2":
            dap_new_subs += make_subrecord("MOD2", b"Clothes\\Residents\\4HatGO.nif\x00")
        elif stype in ["MO2T", "MO2S"]:
            continue
        elif stype == "MODL":
            dap_new_subs += make_subrecord("MODL", struct.pack('<I', 0x000A36BF))
        else:
            dap_new_subs += make_subrecord(stype, sdata)
    dap_rec = make_record("ARMO", 0x0105159B, 0, dap_new_subs)

    # 4. Group ARMO
    grup_armo = make_group("ARMO", reg_rec + dap_rec)

    # 5. Write ESP
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(tes4_rec)
        f.write(grup_armo)

    print(f"[SUCCESS] Built plugin {output_path} ({len(tes4_rec) + len(grup_armo)} bytes).")

if __name__ == "__main__":
    out = "/home/hills/Documents/fallaut/F4 modding/staging_gentleman_outfit/GentlemanOutfitReskin.esp"
    if len(sys.argv) > 1:
        out = sys.argv[1]
    build_gentleman_esp(out)
