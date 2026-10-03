import os
import re
import subprocess
import sys

BASE_DIR = "/home/hills/Documents/fallaut"
WINE_PREFIX = os.path.join(BASE_DIR, "F4 modding", ".wine")
CACHE_DIR = os.path.join(BASE_DIR, "cache", "base_scripts")
CACHE_SRC = os.path.join(BASE_DIR, "cache", "base_sources")
STAGING_DIR = os.path.join(BASE_DIR, "F4 modding", "staging_rexford_romance")
SRC_DIR = os.path.join(STAGING_DIR, "Source")
OUT_DIR = os.path.join(STAGING_DIR, "Scripts")

CAPRICA_EXE = os.path.join(BASE_DIR, "installer", "caprica", "Caprica.exe")
FLAGS_FLG = os.path.join(BASE_DIR, "installer", "caprica", "Institute_Papyrus_Flags.flg")

env = os.environ.copy()
env["WINEPREFIX"] = WINE_PREFIX
env["WINEDEBUG"] = "-all"
env["WINEDLLOVERRIDES"] = "winedbg.exe=d;winemenubuilder.exe=d"

win_flags = "Z:\\home\\hills\\Documents\\fallaut\\installer\\caprica\\Institute_Papyrus_Flags.flg"
win_cache = "Z:\\home\\hills\\Documents\\fallaut\\cache\\base_scripts"
win_sources = "Z:\\home\\hills\\Documents\\fallaut\\cache\\base_sources"
win_src = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_rexford_romance\\Source"
win_out = "Z:\\home\\hills\\Documents\\fallaut\\F4 modding\\staging_rexford_romance\\Scripts"

scripts = ["RexfordRomanceEncounterScript.psc"]

for script_name in scripts:
    print(f"\nCompiling: {script_name}...")
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

print("\nRexford scripts compiled successfully.")
