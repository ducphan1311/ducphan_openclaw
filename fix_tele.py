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
            if "data" in data and "data" in data["data"]:
                return data["data"]["data"].get(key)
            elif "data" in data:
                return data["data"].get(key)
            return None
    except Exception as e:
        print(f"Error fetching from vault: {e}")
        return None

tele_key = None
if len(sys.argv) > 1:
    tele_key = sys.argv[1]

if not tele_key:
    tele_key = get_vault_secret("openclaw_secrets/data/api_keys", "TELEGRAM_BOT_TOKEN")

allowed_users = []
env_path = '/Users/ducphan/Documents/trae_projects/openclaw_manager/.env'

if not tele_key:
    # try .env file
    with open(env_path, 'r') as f:
        for line in f:
            if line.startswith('TELEGRAM_BOT_TOKEN='):
                tele_key = line.strip().split('=')[1]
            elif line.startswith('TELEGRAM_ALLOWED_USERS='):
                allowed_users = [
                    item.strip()
                    for item in line.strip().split('=', 1)[1].split(',')
                    if item.strip()
                ]

if not tele_key:
    print("Could not retrieve key, skipping update.")
    exit(1)

config_paths = [
    "/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/openclaw.json",
    "/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/openclaw.json",
]

try:
    for config_path in config_paths:
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                data = json.load(f)
        else:
            data = {}

        if "channels" not in data:
            data["channels"] = {}
        if "telegram" not in data["channels"]:
            data["channels"]["telegram"] = {}

        data["channels"]["telegram"]["botToken"] = tele_key
        data["channels"]["telegram"]["enabled"] = True
        if allowed_users:
            data["channels"]["telegram"]["dmPolicy"] = "allowlist"
            data["channels"]["telegram"]["allowFrom"] = allowed_users
            if "commands" not in data:
                data["commands"] = {}
            existing = data["commands"].get("ownerAllowFrom", [])
            data["commands"]["ownerAllowFrom"] = sorted(set(
                existing + [f"telegram:{user_id}" for user_id in allowed_users]
            ))

        with open(config_path, 'w') as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print(f"Updated {config_path} with Telegram botToken.")
except Exception as e:
    print(f"Error: {e}")
