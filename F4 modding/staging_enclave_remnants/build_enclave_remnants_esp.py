#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Binary Builder for EnclaveRemnants.esp
Generates standard Bethesda Plugin (TES4 / Creation Engine format)
Masters: Fallout4.esm (Index 0)
Features:
- QUST: EnclaveRemnantsQuest (FormID 0x01000800)
  - Starts Game Enabled (DNAM 0x0001)
  - Attaches EnclaveRemnantsQuestScript.pex
  - Binds verified vanilla FormIDs from Fallout4.esm:
      * PlayerREF:                0x00000007 (ACHR)
      * AtlanticOfficesLocation:  0x000E0EC7 (LCTN)
      * GlowingSeaPOIDB05:        0x0001859D (CELL)
      * Caps001:                  0x0000000F (MISC)
"""

import os
import shutil
import struct
import sys

sys.dont_write_bytecode = True

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STAGING_ESP = os.path.join(SCRIPT_DIR, "EnclaveRemnants.esp")
GAME_ESP = "/home/hills/Documents/fallaut/game/Data/EnclaveRemnants.esp"

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
    # VMAD header: version=6, format=2, script_count=len(script_defs)
    data = struct.pack("<HHH", 6, 2, len(script_defs))
    for sname, props in script_defs:
        sname_bytes = sname.encode("latin1")
        data += struct.pack("<H", len(sname_bytes)) + sname_bytes
        data += struct.pack("<BH", 0, len(props))
        for pname, ptype, pval in props:
            pname_bytes = pname.encode("latin1")
            data += struct.pack("<H", len(pname_bytes)) + pname_bytes
            data += struct.pack("<BB", ptype, 1) # ptype, status=1
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
    print("Building EnclaveRemnants.esp (Stand Modding Pipeline)...")

    # 1. TES4 Header Record
    tes4_sub = b""
    tes4_sub += make_subrecord("HEDR", struct.pack("<fII", 0.95, 1, 0x01000801))
    tes4_sub += make_subrecord("CNAM", "Antigravity Stand\x00")
    tes4_sub += make_subrecord("SNAM", "Enclave Remnants (Echoes of the Past) - Glowing Sea Base & Homing Beacon\x00")
    tes4_sub += make_subrecord("MAST", "Fallout4.esm\x00")
    tes4_sub += make_subrecord("DATA", struct.pack("<Q", 0))
    tes4_rec = make_record("TES4", 0, 0, tes4_sub)

    # 2. QUST Record (FormID: 0x01000800)
    qust_form_id = 0x01000800
    qust_flags = 0x00000000

    qust_vmad_props = [
        ("PlayerREF", 1, 0x00000007),
        ("AtlanticOfficesLocation", 1, 0x000E0EC7),
        ("GlowingSeaPOIDB05", 1, 0x0001859D),
        ("Caps001", 1, 0x0000000F),
    ]
    qust_scripts = [
        ("EnclaveRemnantsQuestScript", qust_vmad_props)
    ]

    qust_sub = b""
    qust_sub += make_subrecord("EDID", "EnclaveRemnantsQuest\x00")
    qust_sub += make_subrecord("FULL", "Відлуння минулого (Анклав: Сяюче море)\x00")
    qust_sub += make_subrecord("DNAM", struct.pack("<H", 0x0001)) # Starts Game Enabled
    qust_sub += build_vmad(qust_scripts)

    qust_rec = make_record("QUST", qust_form_id, qust_flags, qust_sub)
    qust_grup = make_group("QUST", qust_rec, group_type=0)

    # Combine into binary ESP
    esp_content = tes4_rec + qust_grup

    # Save to staging
    with open(STAGING_ESP, "wb") as f:
        f.write(esp_content)
    print(f"[OK] Staging ESP generated: {STAGING_ESP} ({len(esp_content)} bytes)")

    # Deploy to game/Data/
    os.makedirs(os.path.dirname(GAME_ESP), exist_ok=True)
    shutil.copy2(STAGING_ESP, GAME_ESP)
    print(f"[OK] Deployed to game/Data/: {GAME_ESP}")

    print("\n[SUCCESS] EnclaveRemnants.esp built and deployed successfully.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
