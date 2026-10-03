#!/usr/bin/env python3
"""
F4 Modding Hybrid AI Pipeline & Lifecycle Router
=================================================
Routes code and refactoring tasks between:
1. Local Tier: Ollama (qwen2.5-coder) - fast, offline, unit code, regex
2. Deep Tier: GitHub Models (gpt-4o, llama-3.3) - deep refactoring, scenes, state machines
3. Mod Audit: Verifies Papyrus scripts, PEX compilation, and ESP integrity
4. Git Branch Manager: Manages isolated feature branches per development case
"""

import sys
import os
import json
import argparse
import subprocess
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path

# Paths
MODDING_DIR = Path(__file__).resolve().parent
FALLOUT_ROOT = MODDING_DIR.parent
CREDENTIALS_PATH = Path.home() / ".git-credentials"

DEFAULT_CODE_SYSTEM = (
    "You are an expert Fallout 4 Creation Kit, Papyrus, and Python automation engineer. "
    "Output ONLY syntactically valid code, structured schemas, or functional specifications. "
    "DO NOT include conversational greetings, lore discussions, or generic explanations."
)

def get_github_token() -> str:
    """Retrieve GitHub token from env or ~/.git-credentials."""
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        return token.strip()
    
    if CREDENTIALS_PATH.exists():
        try:
            with open(CREDENTIALS_PATH, "r", encoding="utf-8") as f:
                for line in f:
                    if "github.com" in line:
                        parsed = urllib.parse.urlparse(line.strip())
                        if parsed.password:
                            return parsed.password
        except Exception as e:
            sys.stderr.write(f"[WARN] Error reading {CREDENTIALS_PATH}: {e}\n")
    return ""

def query_ollama(prompt: str, model: str = "qwen2.5-coder:1.5b", system: str = "") -> str:
    """Query local Ollama instance (Strict Code-Only contract)."""
    url = "http://127.0.0.1:11434/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "system": system or DEFAULT_CODE_SYSTEM,
        "stream": False,
        "options": {
            "temperature": 0.2,
            "num_predict": 500
        }
    }
    req = urllib.request.Request(
        url,
        headers={"Content-Type": "application/json"},
        data=json.dumps(payload).encode("utf-8")
    )
    # Direct opener bypassing proxy for localhost
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with opener.open(req, timeout=60) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("response", "")
    except urllib.error.URLError as e:
        return f"[ERROR] Ollama connection failed: {e}"

def query_github_models(prompt: str, model: str = "gpt-4o-mini", system: str = "") -> str:
    """Query GitHub Models inference endpoint using GitHub Personal Access Token."""
    token = get_github_token()
    if not token:
        return "[ERROR] No GitHub token found in GITHUB_TOKEN or ~/.git-credentials"

    url = "https://models.inference.ai.azure.com/chat/completions"
    payload = {
        "messages": [
            {"role": "system", "content": system or DEFAULT_CODE_SYSTEM},
            {"role": "user", "content": prompt}
        ],
        "model": model,
        "temperature": 0.2,
        "max_tokens": 1500
    }
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    req = urllib.request.Request(
        url,
        headers=headers,
        data=json.dumps(payload).encode("utf-8")
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            choices = data.get("choices", [])
            if choices and "message" in choices[0]:
                return choices[0]["message"].get("content", "")
            return "[WARN] Empty response from GitHub Models"
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")
        return f"[ERROR] GitHub Models HTTP {e.code}: {e.reason}\nDetails: {error_body}"
    except urllib.error.URLError as e:
        return f"[ERROR] Network error connecting to GitHub Models: {e}"

def audit_staging_directory(target_path: Path):
    """Audit mod staging folder for Papyrus sources, compiled PEX, and ESP files."""
    if not target_path.exists():
        print(f"[FAIL] Target directory does not exist: {target_path}")
        return False

    print(f"\n==========================================")
    print(f"🔍 Functional Mod Audit: {target_path.name}")
    print(f"==========================================")

    # 1. ESP Check
    esps = list(target_path.glob("*.esp"))
    if esps:
        for esp in esps:
            size_kb = esp.stat().st_size / 1024
            print(f"  [PASS] ESP Plugin: {esp.name} ({size_kb:.1f} KiB)")
    else:
        print("  [WARN] No .esp file found in root of staging directory.")

    # 2. Source & Scripts Check
    src_dir = target_path / "Source"
    scripts_dir = target_path / "Scripts"
    
    psc_files = list(src_dir.glob("*.psc")) if src_dir.exists() else []
    pex_files = list(scripts_dir.glob("*.pex")) if scripts_dir.exists() else []

    print(f"  [INFO] Papyrus Sources (.psc): {len(psc_files)}")
    print(f"  [INFO] Compiled Binaries (.pex): {len(pex_files)}")

    recompile_needed = []
    for psc in psc_files:
        pex = scripts_dir / f"{psc.stem}.pex"
        if not pex.exists():
            recompile_needed.append(f"{psc.name} (Missing .pex)")
        elif psc.stat().st_mtime > pex.stat().st_mtime:
            recompile_needed.append(f"{psc.name} (Source is newer than .pex)")

    if recompile_needed:
        print("  [WARN] Recompilation required for:")
        for item in recompile_needed:
            print(f"    - {item}")
    else:
        print("  [PASS] All Papyrus scripts are synchronized with compiled .pex files.")

    # 3. Build scripts check
    build_scripts = list(target_path.glob("build_*.py")) + list(target_path.glob("compile_*.py"))
    print(f"  [INFO] Automation Build Scripts: {len(build_scripts)}")
    for bs in build_scripts:
        print(f"    - {bs.name}")

    print("==========================================\n")
    return len(recompile_needed) == 0

def git_branch_manager(action: str, branch_name: str = "", message: str = ""):
    """Manage isolated feature branches for mod development cases."""
    repo_dir = FALLOUT_ROOT
    if action == "create":
        if not branch_name:
            print("[ERROR] Branch name required for create action")
            return
        branch = f"feature/{branch_name}" if not branch_name.startswith("feature/") else branch_name
        res = subprocess.run(["git", "checkout", "-b", branch], cwd=repo_dir, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"[PASS] Switched to new branch: {branch}")
        else:
            print(f"[INFO] Checkout message: {res.stderr.strip() or res.stdout.strip()}")
    elif action == "commit":
        if not message:
            print("[ERROR] Commit message required")
            return
        subprocess.run(["git", "add", "."], cwd=repo_dir)
        res = subprocess.run(["git", "commit", "-m", message], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip() or res.stderr.strip())
    elif action == "status":
        res = subprocess.run(["git", "status", "--short", "--branch"], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip())
    elif action == "main":
        res = subprocess.run(["git", "checkout", "main"], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip() or res.stderr.strip())

def check_system_status():
    """Check connectivity to Ollama and presence of GitHub Token."""
    print("\n--- Diagnostic Pipeline Status ---")
    
    # 1. Ollama Check
    ollama_resp = query_ollama("Respond with 'PONG'", model="qwen2.5-coder:1.5b")
    if "ERROR" in ollama_resp:
        print(f"  🔴 Ollama Status: {ollama_resp}")
    else:
        print(f"  🟢 Ollama Status: Online (qwen2.5-coder:1.5b operational)")

    # 2. GitHub Token Check
    token = get_github_token()
    if token:
        masked = token[:4] + "*" * (len(token) - 8) + token[-4:]
        print(f"  🟢 GitHub Token: Detected ({masked})")
    else:
        print(f"  🔴 GitHub Token: Not found in GITHUB_TOKEN or ~/.git-credentials")

    # 3. Git Status
    res = subprocess.run(["git", "branch", "--show-current"], cwd=FALLOUT_ROOT, capture_output=True, text=True)
    current_branch = res.stdout.strip() or "unknown"
    print(f"  🟢 Active Git Branch: {current_branch}")
    print("----------------------------------\n")

def main():
    parser = argparse.ArgumentParser(description="F4 Modding Hybrid AI Pipeline & Lifecycle Router")
    parser.add_argument("--tier", choices=["local", "deep"], help="Select AI tier: local (Ollama) or deep (GitHub Models)")
    parser.add_argument("--model", type=str, help="Model name (e.g. qwen2.5-coder:1.5b, gpt-4o-mini, gpt-4o, Meta-Llama-3.3-70B-Instruct)")
    parser.add_argument("--eval", type=str, help="Prompt string to evaluate directly")
    parser.add_argument("--file", type=str, help="Path to file containing prompt/code")
    parser.add_argument("--system", type=str, help="Optional custom system prompt")
    parser.add_argument("--audit", type=str, help="Path or name of staging directory to audit (e.g. staging_rexford_romance)")
    parser.add_argument("--branch", type=str, help="Create and switch to feature/<branch> in git")
    parser.add_argument("--commit", type=str, help="Stage and commit changes on current branch")
    parser.add_argument("--status", action="store_true", help="Display diagnostic pipeline and git status")
    parser.add_argument("--to-main", action="store_true", help="Switch back to main git branch")

    args = parser.parse_args()

    if args.status:
        check_system_status()
        return

    if args.to_main:
        git_branch_manager("main")
        return

    if args.branch:
        git_branch_manager("create", branch_name=args.branch)

    if args.audit:
        staging_path = MODDING_DIR / args.audit if not Path(args.audit).is_absolute() else Path(args.audit)
        audit_staging_directory(staging_path)

    if args.eval or args.file:
        prompt = args.eval
        if args.file:
            with open(args.file, "r", encoding="utf-8") as f:
                prompt = f.read()

        if args.tier == "local":
            model = args.model or "qwen2.5-coder:1.5b"
            res = query_ollama(prompt, model=model, system=args.system)
            print(res)
        elif args.tier == "deep":
            model = args.model or "gpt-4o-mini"
            res = query_github_models(prompt, model=model, system=args.system)
            print(res)
        else:
            print("[ERROR] Please specify --tier [local|deep] when running code generation.")

    if args.commit:
        git_branch_manager("commit", message=args.commit)

if __name__ == "__main__":
    main()
