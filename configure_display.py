#!/usr/bin/env python3
import re
import subprocess
import os

def configure_display():
    stand_dir = "/home/hills/Documents/fallaut"
    prefix_docs = os.path.join(stand_dir, "prefix/drive_c/users/hills/Documents/My Games/Fallout4")
    prefs_ini = os.path.join(prefix_docs, "Fallout4Prefs.ini")
    custom_ini = os.path.join(prefix_docs, "Fallout4Custom.ini")

    # 1. Query xrandr for connected monitors
    try:
        out = subprocess.check_output(["xrandr", "--query"]).decode("utf-8")
    except Exception as e:
        print(f"[Display Config] Error running xrandr: {e}")
        return

    # Find external monitor (any connected output other than eDP-*)
    ext_match = re.search(r"^((?!eDP)[\w-]+) connected (?:primary )?(\d+)x(\d+)\+(\d+)\+(\d+)", out, re.MULTILINE)

    if ext_match:
        port, w, h, x, y = ext_match.groups()
        print(f"[Display Config] External monitor connected: {port} ({w}x{h} at +{x}+{y})")
        
        # Ensure external monitor (HDMI-1) is primary so Wine/Fallout4 targets it directly
        if f"{port} connected primary" not in out:
            subprocess.run(["xrandr", "--output", port, "--primary"], check=False)
            print(f"[Display Config] Set {port} as Primary display for game window.")
        else:
            print(f"[Display Config] {port} is already primary. Skipping xrandr to prevent screen blinking.")
        
        # Ensure XFCE panels remain pinned to laptop display (eDP-1)
        try:
            subprocess.run(["xfconf-query", "-c", "xfce4-panel", "-p", "/panels/panel-1/output-name", "-s", "eDP-1"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["xfconf-query", "-c", "xfce4-panel", "-p", "/panels/panel-2/output-name", "-s", "eDP-1"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

        # Borderless windowed fullscreen covering the external monitor at its exact coordinates
        display_settings = {
            "bFull Screen": "0",
            "bBorderless": "1",
            "iSize W": str(w),
            "iSize H": str(h),
            "iLocation X": str(x),
            "iLocation Y": str(y),
        }
        print(f"[Display Config] Mode: Borderless Fullscreen on {port} ({w}x{h} at +{x}+{y}), Panels on Laptop eDP-1")
    else:
        print("[Display Config] External monitor not detected. Laptop display only.")
        
        # Ensure laptop display is primary in X11 if not already
        if "eDP-1 connected primary" not in out:
            subprocess.run(["xrandr", "--output", "eDP-1", "--primary"], check=False)
        
        # Framed window (bFull Screen=0, bBorderless=0)
        display_settings = {
            "bFull Screen": "0",
            "bBorderless": "0",
            "iSize W": "1280",
            "iSize H": "720",
            "iLocation X": "0",
            "iLocation Y": "0",
        }
        print("[Display Config] Mode: Framed window on laptop display (1280x720)")

    def update_ini_section(file_path, section_name, settings):
        import shutil
        bak_path = file_path + ".bak"
        template_path = os.path.join(stand_dir, "game/Fallout4/Fallout4Prefs.ini")

        # Self-healing: if file is missing or 0 bytes, recover from backup or template
        if not os.path.exists(file_path) or os.path.getsize(file_path) < 20:
            if os.path.exists(bak_path) and os.path.getsize(bak_path) >= 20:
                shutil.copyfile(bak_path, file_path)
                print(f"[Display Config] Відновлено {os.path.basename(file_path)} з резервної копії .bak")
            elif "Fallout4Prefs.ini" in file_path and os.path.exists(template_path):
                shutil.copyfile(template_path, file_path)
                print(f"[Display Config] Відновлено {os.path.basename(file_path)} з еталонного шаблону гри")

        if not os.path.exists(file_path):
            return

        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        if not lines and os.path.exists(bak_path):
            with open(bak_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()

        new_lines = []
        in_section = False
        found_keys = set()

        for line in lines:
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                if in_section:
                    for k, v in settings.items():
                        if k not in found_keys:
                            new_lines.append(f"{k}={v}\n")
                in_section = (stripped.lower() == f"[{section_name.lower()}]")
                new_lines.append(line)
                continue

            if in_section:
                key = stripped.split("=")[0].strip() if "=" in stripped else ""
                if key in settings:
                    new_lines.append(f"{key}={settings[key]}\n")
                    found_keys.add(key)
                    continue
            new_lines.append(line)

        if in_section:
            for k, v in settings.items():
                if k not in found_keys:
                    new_lines.append(f"{k}={v}\n")

        # Atomic replacement via temporary file
        if new_lines:
            tmp_file = file_path + ".tmp"
            with open(tmp_file, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
            os.replace(tmp_file, file_path)
            shutil.copyfile(file_path, bak_path)
            print(f"[Display Config] Безпечно оновлено {os.path.basename(file_path)} ({len(new_lines)} рядків)")

    update_ini_section(prefs_ini, "Display", display_settings)
    update_ini_section(custom_ini, "Display", display_settings)

if __name__ == "__main__":
    configure_display()
