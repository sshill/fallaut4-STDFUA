#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Compiler script for MercyRecruitment Papyrus scripts using Caprica and Champollion.
"""

import os
import re
import subprocess
import sys

BASE_DIR = "/home/hills/Documents/fallaut"
WINE_PREFIX = os.path.join(BASE_DIR, "prefix")
CACHE_DIR = os.path.join(BASE_DIR, "cache", "base_scripts")
STAGING_DIR = os.path.join(BASE_DIR, "F4 modding", "staging_mercy_recruitment")
SRC_DIR = os.path.join(STAGING_DIR, "Source")
OUT_DIR = os.path.join(STAGING_DIR, "Scripts")

CAPRICA_EXE = os.path.join(BASE_DIR, "installer", "caprica", "Caprica.exe")
FLAGS_FLG = os.path.join(BASE_DIR, "installer", "caprica", "Institute_Papyrus_Flags.flg")
CHAMPOLLION_EXE = os.path.join(BASE_DIR, "installer", "champollion", "Champollion.exe")

env = os.environ.copy()
env["WINEPREFIX"] = WINE_PREFIX
env["WINEDEBUG"] = "-all"

pex_map = {}
for fname in os.listdir(CACHE_DIR):
    if fname.lower().endswith(".pex"):
        pex_map[fname.lower()[:-4]] = fname

def decompile_type(typename):
    key = typename.lower()
    if key not in pex_map:
        print(f"[-] Cannot find {typename}.pex in {CACHE_DIR}")
        return False
    actual_pex = pex_map[key]
    out_psc = os.path.join(CACHE_DIR, f"{actual_pex[:-4]}.psc")
    if os.path.exists(out_psc):
        return True
    
    cmd = ["wine", CHAMPOLLION_EXE, actual_pex, "-p", "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_mercy_recruitment\\Source"]
    res = subprocess.run(cmd, cwd=CACHE_DIR, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode == 0:
        print(f"[+] Decompiled {actual_pex} -> Source/")
        return True
    else:
        print(f"[-] Champollion failed on {actual_pex}: {res.stderr}")
        return False

win_flags = "Z:\\home\\hills\\Documents\\fallaut\\installer\\caprica\\Institute_Papyrus_Flags.flg"
win_cache = "Z:\\home\\hills\\Documents\\fallaut\\cache\\base_scripts"
win_src = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_mercy_recruitment\\Source"
win_out = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_mercy_recruitment\\Scripts"

scripts = ["ShellyTillerRecruitScript.psc", "MercyRecruitmentPerkScript.psc", "MercyRecruitmentQuestScript.psc"]

for script_name in scripts:
    print(f"\nCompiling: {script_name}...")
    attempts = 0
    while attempts < 30:
        attempts += 1
        cmd = [
            "wine", CAPRICA_EXE,
            script_name,
            "-g", "fallout4",
            "-f", win_flags,
            "-i", f"{win_src};{win_cache}",
            "-o", win_out,
            "--ignorecwd",
            "--async-read", "0",
            "--async-write", "0"
        ]
        res = subprocess.run(cmd, cwd=SRC_DIR, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        combined = res.stdout + "\n" + res.stderr
        if res.returncode == 0:
            print(f"[SUCCESS] Compiled {script_name} in {attempts} attempt(s)!")
            break
        
        missing = set()
        for m in re.finditer(r"Unable to resolve type '([^']+)'", combined):
            missing.add(m.group(1).split(':')[0])
        for m in re.finditer(r"Failed to find script '([^']+)'", combined):
            missing.add(m.group(1).split(':')[0])
        for m in re.finditer(r"Could not find type '([^']+)'", combined):
            missing.add(m.group(1).split(':')[0])
            
        if not missing:
            print(f"[ERROR] Compilation failed:")
            print(combined)
            sys.exit(1)
            
        for missing_type in missing:
            decompile_type(missing_type)

print("\nAll Mercy Recruitment scripts compiled successfully.")
