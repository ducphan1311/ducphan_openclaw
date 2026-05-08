import json
import os
import urllib.request
import sys

# Vault Configuration
VAULT_ADDR = "http://127.0.0.1:8200"
VAULT_TOKEN = os.environ.get("VAULT_TOKEN", "root")

def get_vault_secret(path, key):
    url = f"{VAULT_ADDR}/v1/{path}"
    req = urllib.request.Request(url)
    req.add_header("X-Vault-Token", VAULT_TOKEN)
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            # Try KV v2 format first (data.data.key), then KV v1 (data.key)
            if "data" in data and "data" in data["data"]:
                return data["data"]["data"].get(key)
            elif "data" in data:
                return data["data"].get(key)
            return None
    except Exception as e:
        print(f"Error fetching from vault: {e}")
        return None

# Try direct API key injection from argument if provided
gemini_key = None
if len(sys.argv) > 1:
    gemini_key = sys.argv[1]

# Fallback to Vault
if not gemini_key:
    gemini_key = get_vault_secret("openclaw_secrets/data/api_keys", "GOOGLE_GENERATIVE_AI_API_KEY")

if not gemini_key:
    print("Could not retrieve key from vault or arguments, skipping update.")
    exit(1)

config_path = "/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/agents/main/agent/auth-profiles.json"

try:
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            data = json.load(f)
    else:
        data = {}

    data["google"] = {
        "apiKey": gemini_key
    }

    with open(config_path, 'w') as f:
        json.dump(data, f, indent=2)
    print("Updated auth-profiles.json successfully with Key.")
except Exception as e:
    print(f"Error: {e}")
