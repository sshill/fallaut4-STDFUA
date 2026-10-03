#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.error

def query_ollama(prompt: str, model: str = "qwen2.5-coder:1.5b", system: str = ""):
    url = "http://127.0.0.1:11434/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.2,
            "num_predict": 400
        }
    }
    if system:
        payload["system"] = system
        
    req = urllib.request.Request(
        url,
        headers={"Content-Type": "application/json"},
        data=json.dumps(payload).encode("utf-8")
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("response", "")
    except urllib.error.URLError as e:
        return f"Ollama connection error: {e}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ollama_tool.py <prompt> [model]")
        sys.exit(1)
    prompt = sys.argv[1]
    model = sys.argv[2] if len(sys.argv) > 2 else "qwen2.5-coder:1.5b"
    response = query_ollama(prompt, model=model)
    print(response)
