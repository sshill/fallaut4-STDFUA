#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Builder for RexfordRomance.esp (Workspace Staging)

Masters:
  - Fallout4.esm (Index 0)

Records:
  - QUST: RexfordRomanceQuest (FormID: 0x01000800)
    - Starts Game Enabled
    - Attaches RexfordRomanceEncounterScript.pex
    - Binds verified vanilla FormIDs from Fallout4.esm:
        * DialogueGoodneighbor:          0x00033582 (QUST)
        * MagnoliaREF:                   0x0002268B (ACHR)
        * HotelRexfordPlayerBed:         0x0010C651 (REFR)
        * HotelMagnoliaMarkerREF:        0x001AD903 (REFR)
        * GoodneighborHotelRexford:      0x00022683 (CELL)
        * GoodneighborTheThirdRail:      0x0002263E (CELL)
        * GoodneighborMagnoliaSingMarker:0x00075EBA (REFR)
        * LoversEmbracePerkSpell:        0x000F3C1D (SPEL)
        * MagnoliaGreetScene03:          0x001AC13B (SCEN)
"""

import os
import struct

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STAGING_ESP = os.path.join(SCRIPT_DIR, "RexfordRomance.esp")

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
    print("Building RexfordRomance.esp (Workspace Staging)...")

    # 1. TES4 Header
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 1, 0x00000801))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Rexford Hotel Romance & Companion Night Encounter Overhaul\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. QUST Record
    # Verified FormIDs in Fallout4.esm:
    PROPERTIES = [
        ("DialogueGoodneighbor",          1, 0x00033582), # QUST
        ("MagnoliaREF",                   1, 0x0002268B), # ACHR
        ("HotelRexfordPlayerBed",         1, 0x0010C651), # REFR
        ("HotelMagnoliaMarkerREF",        1, 0x001AD903), # REFR
        ("GoodneighborHotelRexford",      1, 0x00022683), # CELL
        ("GoodneighborTheThirdRail",      1, 0x0002263E), # CELL
        ("GoodneighborMagnoliaSingMarker",1, 0x00075EBA), # REFR
        ("LoversEmbracePerkSpell",        1, 0x000F3C1D), # SPEL
        ("MagnoliaGreetScene03",          1, 0x001AC13B), # SCEN
        ("EnableMagnolia",                5, True),       # Bool
        ("AutoReturnAfterDelay",          5, True),       # Bool
        ("ReturnDelaySeconds",            4, 180.0)       # Float
    ]

    qust_sub = b""
    qust_sub += make_subrecord("EDID", "RexfordRomanceQuest\x00")
    qust_sub += build_vmad([("RexfordRomanceEncounterScript", PROPERTIES)])
    
    # DNAM: flags (0x0001 = Start Game Enabled), priority 50, type None
    dnam_bytes = struct.pack("<HBBII", 0x0001, 50, 0, 0, 0)
    qust_sub += make_subrecord("DNAM", dnam_bytes)

    quest_rec = make_record("QUST", 0x01000800, 0, qust_sub)
    grup_qust = make_group("QUST", quest_rec)

    total_plugin = tes4_rec + grup_qust
    with open(STAGING_ESP, "wb") as f:
        f.write(total_plugin)

    print(f"Successfully generated {STAGING_ESP} ({len(total_plugin)} bytes).")

if __name__ == "__main__":
    main()
