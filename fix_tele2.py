import json
import os

config_path = "/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/openclaw.json"

try:
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            data = json.load(f)
    else:
        data = {}
    
    if "channels" in data and "telegram" in data["channels"]:
        if "token" in data["channels"]["telegram"]:
            del data["channels"]["telegram"]["token"]
            print("Removed token from openclaw.json")

    with open(config_path, 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f"Error: {e}")
