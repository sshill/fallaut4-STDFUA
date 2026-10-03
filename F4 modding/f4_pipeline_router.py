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

    endpoints = [
        "https://models.github.ai/inference/chat/completions",
        "https://models.inference.ai.azure.com/chat/completions"
    ]
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
        "Authorization": f"Bearer {token}",
        "User-Agent": "f4_pipeline_router/1.0"
    }

    last_error = ""
    for url in endpoints:
        req = urllib.request.Request(
            url,
            headers=headers,
            data=json.dumps(payload).encode("utf-8")
        )
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        try:
            with opener.open(req, timeout=30) as resp:
                raw_body = resp.read().decode("utf-8")
                try:
                    data = json.loads(raw_body)
                    choices = data.get("choices", [])
                    if choices and "message" in choices[0]:
                        return choices[0]["message"].get("content", "")
                    return "[WARN] Empty response from GitHub Models"
                except json.JSONDecodeError:
                    return f"[INFO] Endpoint response: {raw_body.strip()}"
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8", errors="replace")
            last_error = f"[ERROR] GitHub Models HTTP {e.code}: {e.reason}\nDetails: {error_body}"
        except urllib.error.URLError as e:
            last_error = f"[ERROR] Network error connecting to {url}: {e}"

    return last_error


def audit_staging_directory(target_path: Path) -> dict:
    """Audit mod staging folder for Papyrus sources, compiled PEX, and ESP files."""
    if not target_path.exists():
        print(f"[FAIL] Target directory does not exist: {target_path}")
        return {"exists": False, "passed": False}

    print(f"\n==========================================")
    print(f"🔍 Functional Mod Audit: {target_path.name}")
    print(f"==========================================")

    # 1. ESP Check
    esps = list(target_path.glob("*.esp"))
    esp_name = "None"
    esp_size_kb = 0.0
    if esps:
        for esp in esps:
            esp_size_kb = esp.stat().st_size / 1024
            esp_name = esp.name
            print(f"  [PASS] ESP Plugin: {esp.name} ({esp_size_kb:.1f} KiB)")
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

    passed = (len(recompile_needed) == 0) and bool(esps)
    print("==========================================\n")
    return {
        "name": target_path.name,
        "exists": True,
        "esp": esp_name,
        "esp_size_kb": esp_size_kb,
        "psc_count": len(psc_files),
        "pex_count": len(pex_files),
        "recompile_needed": recompile_needed,
        "build_scripts": [bs.name for bs in build_scripts],
        "passed": passed
    }

def audit_all_staging_directories():
    """Scan and audit all staging directories in F4 modding."""
    staging_dirs = sorted([d for d in MODDING_DIR.iterdir() if d.is_dir() and d.name.startswith("staging_")])
    if not staging_dirs:
        print("[WARN] No staging_* directories found in F4 modding.")
        return

    print(f"\n=======================================================")
    print(f"📦 Batch Systemic Functional Audit: {len(staging_dirs)} Mod Modules")
    print(f"=======================================================")

    results = []
    for sdir in staging_dirs:
        res = audit_staging_directory(sdir)
        results.append(res)

    print("\n" + "=" * 70)
    print(f"{'Mod Module':<26} | {'ESP':<18} | {'.psc/.pex':<10} | {'Status'}")
    print("-" * 70)
    for r in results:
        status_str = "🟢 PASS" if r["passed"] else ("🟡 WARN (Recompile)" if r["recompile_needed"] else "🔴 FAIL")
        psc_pex = f"{r['psc_count']}/{r['pex_count']}"
        esp_str = f"{r['esp']} ({r['esp_size_kb']:.1f}k)" if r['esp'] != "None" else "None"
        print(f"{r['name']:<26} | {esp_str:<18} | {psc_pex:<10} | {status_str}")
    print("=" * 70 + "\n")

def git_branch_manager(action: str, branch_name: str = "", message: str = ""):
    """Manage isolated feature branches and remote push for mod development cases."""
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
        
        # Check current branch for standardized commit prefix
        res_branch = subprocess.run(["git", "branch", "--show-current"], cwd=repo_dir, capture_output=True, text=True)
        current_branch = res_branch.stdout.strip()
        final_message = message
        if current_branch.startswith("feature/"):
            case_name = current_branch.replace("feature/", "")
            prefixes = ("feat(", "fix(", "docs(", "refactor(", "test(", "chore(")
            if not any(message.startswith(p) for p in prefixes):
                final_message = f"feat(f4-{case_name}): {message}"

        subprocess.run(["git", "add", "."], cwd=repo_dir)
        res = subprocess.run(["git", "commit", "-m", final_message], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip() or res.stderr.strip())

    elif action == "push":
        res_branch = subprocess.run(["git", "branch", "--show-current"], cwd=repo_dir, capture_output=True, text=True)
        current_branch = res_branch.stdout.strip()
        if not current_branch:
            print("[ERROR] Could not determine active branch for git push")
            return
        print(f"[INFO] Pushing branch '{current_branch}' to origin...")
        res = subprocess.run(["git", "push", "-u", "origin", current_branch], cwd=repo_dir, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"[PASS] Successfully pushed '{current_branch}' to remote GitHub repository.")
            if res.stdout.strip():
                print(res.stdout.strip())
        else:
            print(f"[ERROR] Failed to push to remote:\n{res.stderr.strip() or res.stdout.strip()}")

    elif action == "status":
        res = subprocess.run(["git", "status", "--short", "--branch"], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip())

    elif action == "main":
        res = subprocess.run(["git", "checkout", "main"], cwd=repo_dir, capture_output=True, text=True)
        print(res.stdout.strip() or res.stderr.strip())

def check_system_status():
    """Check connectivity to Ollama, presence of GitHub Token, and Git repository state."""
    print("\n--- Diagnostic Pipeline Status ---")
    
    # 1. Ollama Check
    ollama_resp = query_ollama("Respond with 'PONG'", model="qwen2.5-coder:1.5b")
    if "Connection refused" in ollama_resp or "[Errno 111]" in ollama_resp:
        print("  🟡 Ollama Status: Offline or isolated in IDE sandbox ([Errno 111] Connection refused)")
        print("     💡 Note: Sandbox isolates network namespace. Run directly in host terminal to reach 'ollama serve'.")
    elif "ERROR" in ollama_resp:
        print(f"  🔴 Ollama Status: {ollama_resp}")
    else:
        print(f"  🟢 Ollama Status: Online (qwen2.5-coder:1.5b operational)")

    # 2. GitHub Token Check
    token = get_github_token()
    if token:
        masked = token[:4] + "*" * (len(token) - 8) + token[-4:]
        print(f"  🟢 GitHub Token: Detected ({masked})")
        print("     💡 GitHub Models: models.inference.ai.azure.com (accessible via host terminal)")
    else:
        print(f"  🔴 GitHub Token: Not found in GITHUB_TOKEN or ~/.git-credentials")

    # 3. Git Status & Remote
    res_branch = subprocess.run(["git", "branch", "--show-current"], cwd=FALLOUT_ROOT, capture_output=True, text=True)
    current_branch = res_branch.stdout.strip() or "unknown"
    
    res_remote = subprocess.run(["git", "remote", "get-url", "origin"], cwd=FALLOUT_ROOT, capture_output=True, text=True)
    remote_url = res_remote.stdout.strip() or "none"

    res_stat = subprocess.run(["git", "status", "-sb"], cwd=FALLOUT_ROOT, capture_output=True, text=True)
    stat_summary = res_stat.stdout.strip().split("\n")[0] if res_stat.stdout.strip() else ""

    print(f"  🟢 Active Git Branch: {current_branch}")
    print(f"  🌐 Remote Origin: {remote_url}")
    print(f"  📊 Branch Status: {stat_summary}")
    print("----------------------------------\n")

def main():
    parser = argparse.ArgumentParser(description="F4 Modding Hybrid AI Pipeline & Lifecycle Router")
    parser.add_argument("--tier", choices=["local", "deep"], help="Select AI tier: local (Ollama) or deep (GitHub Models)")
    parser.add_argument("--model", type=str, help="Model name (e.g. qwen2.5-coder:1.5b, gpt-4o-mini, gpt-4o, Meta-Llama-3.3-70B-Instruct)")
    parser.add_argument("--eval", type=str, help="Prompt string to evaluate directly")
    parser.add_argument("--file", type=str, help="Path to file containing prompt/code")
    parser.add_argument("--system", type=str, help="Optional custom system prompt")
    parser.add_argument("--audit", type=str, help="Path or name of staging directory to audit (e.g. staging_rexford_romance)")
    parser.add_argument("--audit-all", action="store_true", help="Audit all staging_* directories in F4 modding")
    parser.add_argument("--branch", type=str, help="Create and switch to feature/<branch> in git")
    parser.add_argument("--commit", type=str, help="Stage and commit changes on current branch (with auto-prefix)")
    parser.add_argument("--push", action="store_true", help="Push active branch to remote GitHub repository (origin)")
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

    if args.audit_all:
        audit_all_staging_directories()
        return

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

    if args.push:
        git_branch_manager("push")

if __name__ == "__main__":
    main()
