#!/usr/bin/env python3
import json
import subprocess
import sys

def main():
    try:
        sys.stdin.read()
    except Exception:
        pass

    try:
        subprocess.Popen(
            ["aplay", "-D", "default", "/home/hills/Documents/fallaut/scratch/chime_ready.wav"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

    print(json.dumps({"allowStop": True}))

if __name__ == "__main__":
    main()
