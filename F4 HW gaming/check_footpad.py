#!/usr/bin/env python3
import subprocess
import re
import sys
import os
import time
import select

OUTPUT_FILE = os.path.expanduser("~/Documents/footpad_result.txt")

def get_keymap():
    out = subprocess.check_output(['xmodmap', '-pke']).decode()
    km = {}
    for line in out.splitlines():
        m = re.match(r'keycode\s+(\d+)\s*=\s*(.*)', line)
        if m:
            kc = int(m.group(1))
            syms = [s for s in m.group(2).split() if s != 'NoSymbol']
            km[kc] = syms[0] if syms else f'Key_{kc}'
    return km

def find_devices():
    out = subprocess.check_output(['xinput', 'list']).decode()
    kbd_ids = []
    mouse_ids = []
    for line in out.splitlines():
        if 'PCsensor FootSwitch' in line:
            m = re.search(r'id=(\d+)', line)
            if m:
                dev_id = m.group(1)
                if 'keyboard' in line.lower() or 'slave  keyboard' in line.lower():
                    kbd_ids.append(dev_id)
                elif 'mouse' in line.lower() or 'slave  pointer' in line.lower():
                    mouse_ids.append(dev_id)
    return kbd_ids, mouse_ids

def log_event(text):
    timestamp = time.strftime('%H:%M:%S')
    msg = f"[{timestamp}] {text}"
    print(msg, flush=True)
    with open(OUTPUT_FILE, "a") as f:
        f.write(msg + "\n")

def main():
    with open(OUTPUT_FILE, "w") as f:
        f.write(f"=== Діагностика FootSwitch розпочата о {time.strftime('%H:%M:%S')} ===\n")

    keymap = get_keymap()
    kbd_ids, mouse_ids = find_devices()

    log_event(f"Знайдено пристрої: Keyboard IDs={kbd_ids}, Mouse IDs={mouse_ids}")

    if not kbd_ids and not mouse_ids:
        log_event("ПОМИЛКА: PCsensor FootSwitch не знайдено в xinput list!")
        sys.exit(1)

    procs = []
    for kid in kbd_ids:
        p = subprocess.Popen(['xinput', 'test', kid], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        procs.append(('kbd', p))
    for mid in mouse_ids:
        p = subprocess.Popen(['xinput', 'test', mid], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        procs.append(('mouse', p))

    log_event("Очікую натискання педалі (натисніть педаль ногою)...")

    held_keys = set()

    try:
        while True:
            readable = [p.stdout for _, p in procs]
            r, _, _ = select.select(readable, [], [], 0.5)
            for stream in r:
                line = stream.readline()
                if not line:
                    continue
                line = line.strip()
                
                # Check keyboard
                m_press = re.match(r'key press\s+(\d+)', line)
                if m_press:
                    kc = int(m_press.group(1))
                    sym = keymap.get(kc, f'Key_{kc}')
                    held_keys.add(sym)
                    combo = " + ".join(sorted(held_keys))
                    log_event(f"НАТИСНУТО: '{sym}' (код: {kc}) | Поточна комбінація: [{combo}]")

                m_rel = re.match(r'key release\s+(\d+)', line)
                if m_rel:
                    kc = int(m_rel.group(1))
                    sym = keymap.get(kc, f'Key_{kc}')
                    log_event(f"ВІДПУЩЕНО: '{sym}' (код: {kc})")
                    if sym in held_keys:
                        held_keys.remove(sym)

                # Check mouse
                m_btn_press = re.match(r'button press\s+(\d+)', line)
                if m_btn_press:
                    btn = m_btn_press.group(1)
                    btn_map = {'1': 'Ліва кнопка миші (LMB)', '2': 'Коліщатко (MMB)', '3': 'Права кнопка миші (RMB)', '4': 'Scroll Up', '5': 'Scroll Down'}
                    log_event(f"НАТИСНУТО КНОПКУ МИШІ: {btn_map.get(btn, f'Кнопка {btn}')}")

                m_btn_rel = re.match(r'button release\s+(\d+)', line)
                if m_btn_rel:
                    btn = m_btn_rel.group(1)
                    log_event(f"ВІДПУЩЕНО КНОПКУ МИШІ: {btn}")

    except KeyboardInterrupt:
        pass
    finally:
        for _, p in procs:
            p.terminate()

if __name__ == '__main__':
    main()
