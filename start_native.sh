#!/bin/bash
# start_native.sh - Run OpenClaw natively on macOS
# This script sets up the local environment to match the docker configuration
# and starts the OpenClaw gateway.

set -e

# 1. Define paths based on current repository
export REPO_DIR="$(pwd)"
export OPENCLAW_WORKSPACE="$REPO_DIR/workspace"
export OPENCLAW_SKILLS_DIR="$REPO_DIR/skills"
export OPENCLAW_CONFIG_DIR="$REPO_DIR/config"
export OPENCLAW_DATA_DIR="$REPO_DIR/openclaw_data"

# Provide fallback for local Vault (or rely on existing dockerized vault)
export VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
# Uncomment and set your Vault Token here, or pass it in environment
# export VAULT_TOKEN="your_vault_token"

export OPENCLAW_ENV=production
export OPENCLAW_HOST=127.0.0.1
export OPENCLAW_CONFIG="$OPENCLAW_CONFIG_DIR/policies.yaml"

# 2. Check dependencies
if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js is not installed. Please install Node.js 22+ (e.g., via Homebrew: brew install node)"
    exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw is not installed globally. Installing..."
    npm install -g openclaw@latest playwright pnpm
fi

# 3. Create required directories if they don't exist
mkdir -p "$OPENCLAW_WORKSPACE" "$OPENCLAW_SKILLS_DIR" "$OPENCLAW_CONFIG_DIR" "$OPENCLAW_DATA_DIR"

# Ensure we use the local openclaw_data folder for config instead of the user's home ~/.openclaw
# OpenClaw reads from ~/.openclaw by default, so we can symlink it if needed, or rely on OPENCLAW_DATA_DIR if supported.
# To be safe, if OpenClaw doesn't support OPENCLAW_DATA_DIR, we can temporarily link ~/.openclaw:
if [ ! -L "$HOME/.openclaw" ] && [ ! -d "$HOME/.openclaw" ]; then
    ln -s "$OPENCLAW_DATA_DIR" "$HOME/.openclaw"
elif [ -d "$HOME/.openclaw" ] && [ ! -L "$HOME/.openclaw" ]; then
    echo "Warning: $HOME/.openclaw is a real directory. Native OpenClaw will use it instead of $OPENCLAW_DATA_DIR."
fi

# 4. Start the gateway
echo "Starting OpenClaw Native Gateway..."
echo "Workspace: $OPENCLAW_WORKSPACE"
echo "Policies: $OPENCLAW_CONFIG"

openclaw gateway --allow-unconfigured --port 3000
