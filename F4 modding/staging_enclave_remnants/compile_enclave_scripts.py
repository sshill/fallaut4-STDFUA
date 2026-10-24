#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import subprocess
import sys

sys.dont_write_bytecode = True

BASE_DIR = "/home/hills/Documents/fallaut"
WINE_PREFIX = os.path.join(BASE_DIR, "F4 modding", ".wine")
CACHE_DIR = os.path.join(BASE_DIR, "cache", "base_scripts")
CACHE_SRC = os.path.join(BASE_DIR, "cache", "base_sources")
STAGING_DIR = os.path.join(BASE_DIR, "F4 modding", "staging_enclave_remnants")
SRC_DIR = os.path.join(STAGING_DIR, "Source")
OUT_DIR = os.path.join(STAGING_DIR, "Scripts")

os.makedirs(OUT_DIR, exist_ok=True)

CAPRICA_EXE = os.path.join(BASE_DIR, "installer", "caprica", "Caprica.exe")
FLAGS_FLG = os.path.join(BASE_DIR, "installer", "caprica", "Institute_Papyrus_Flags.flg")

env = os.environ.copy()
env["WINEPREFIX"] = WINE_PREFIX
env["WINEDEBUG"] = "-all"
env["WINEDLLOVERRIDES"] = "winedbg.exe=d;winemenubuilder.exe=d"

win_flags = "Z:\\home\\hills\\Documents\\fallaut\\installer\\caprica\\Institute_Papyrus_Flags.flg"
win_cache = "Z:\\home\\hills\\Documents\\fallaut\\cache\\base_scripts"
win_sources = "Z:\\home\\hills\\Documents\\fallaut\\cache\\base_sources"
win_src = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_enclave_remnants\\Source"
win_out = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_enclave_remnants\\Scripts"

scripts = ["EnclaveRemnantsQuestScript.psc"]

for script_name in scripts:
    print(f"\nCompiling: {script_name} via Caprica...")
    cmd = [
        "wine", CAPRICA_EXE,
        script_name,
        "-g", "fallout4",
        "-f", win_flags,
        "-i", f"{win_src};{win_sources};{win_cache}",
        "-o", win_out,
        "--ignorecwd",
        "--async-read", "0",
        "--async-write", "0"
    ]
    res = subprocess.run(cmd, cwd=SRC_DIR, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    combined = res.stdout + "\n" + res.stderr
    print("Compiler output:\n", combined)
    if res.returncode == 0:
        print(f"[SUCCESS] Compiled {script_name} successfully!")
    else:
        print(f"[ERROR] Compilation failed with code {res.returncode}")
        sys.exit(1)

# Deploy to game/Data/Scripts
game_scripts = os.path.join(BASE_DIR, "game", "Data", "Scripts")
os.makedirs(game_scripts, exist_ok=True)
for pex in os.listdir(OUT_DIR):
    if pex.endswith(".pex"):
        src_pex = os.path.join(OUT_DIR, pex)
        dst_pex = os.path.join(game_scripts, pex)
        with open(src_pex, "rb") as sf, open(dst_pex, "wb") as df:
            df.write(sf.read())
        print(f"[DEPLOY] Deployed {pex} -> {dst_pex}")

print("\nEnclave Remnants scripts compiled and deployed successfully.")
