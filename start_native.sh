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
export OPENCLAW_CONFIG_PATH="$OPENCLAW_DATA_DIR/openclaw.json"
export OPENCLAW_AGENT_WORKSPACE="$OPENCLAW_DATA_DIR/.openclaw/workspace"

if [ -f "$REPO_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$REPO_DIR/.env"
    set +a
fi

# Provide fallback for local Vault (or rely on existing dockerized vault)
export VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
# Uncomment and set your Vault Token here, or pass it in environment
# export VAULT_TOKEN="your_vault_token"

if command -v curl >/dev/null 2>&1; then
    VAULT_TOKEN_FOR_FETCH="${VAULT_TOKEN:-}"
    if [ -z "$VAULT_TOKEN_FOR_FETCH" ] && [ -f "$HOME/.vault-token" ]; then
        VAULT_TOKEN_FOR_FETCH="$(cat "$HOME/.vault-token" 2>/dev/null || true)"
    fi

    if [ -z "$VAULT_TOKEN_FOR_FETCH" ]; then
        echo "VAULT_TOKEN is not set and ~/.vault-token was not found; using existing environment/.env values."
    elif curl -s -f "${VAULT_ADDR}/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204" >/dev/null 2>&1; then
        echo "Fetching secrets from Vault..."
        SECRETS_JSON="$(curl -sS -L -H "X-Vault-Token: $VAULT_TOKEN_FOR_FETCH" "${VAULT_ADDR}/v1/openclaw_secrets/data/api_keys")"
        if EXPORTS="$(SECRETS_JSON="$SECRETS_JSON" node -e "
          try {
            const raw = process.env.SECRETS_JSON;
            if (!raw) throw new Error('SECRETS_JSON is empty');
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed.errors) && parsed.errors.length > 0) {
              throw new Error(parsed.errors.join('; '));
            }
            const secrets = parsed.data?.data ?? parsed.data;
            if (!secrets || typeof secrets !== 'object') throw new Error('unexpected Vault response shape');
            const emit = (key, value) => {
              if (value === null || value === undefined || value === '') return;
              const aliases = {
                '9ROUTER_API_KEY': 'NINE_ROUTER_API_KEY',
                '9ROUTER_BASE_URL': 'NINE_ROUTER_BASE_URL',
                '9ROUTER_MODEL': 'NINE_ROUTER_MODEL',
              };
              key = aliases[key] || key;
              if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) return;
              const safeValue = String(value).replace(/'/g, \"'\\\\''\");
              console.log('export ' + key + '=\\'' + safeValue + '\\'');
            };
            for (const [key, value] of Object.entries(secrets)) {
              emit(key, value);
              if (key === 'GOOGLE_GENERATIVE_AI_API_KEY') {
                emit('GOOGLE_API_KEY', value);
                emit('GEMINI_API_KEY', value);
              }
            }
          } catch (err) {
            console.error('Failed to parse Vault secrets: ' + err.message);
            process.exit(1);
          }
        ")"; then
            source <(printf "%s\n" "$EXPORTS")
            echo "Secrets successfully loaded into runtime environment."
        else
            echo "Vault secret fetch failed; using existing environment/.env values."
        fi
        unset SECRETS_JSON
        unset EXPORTS
        unset VAULT_TOKEN_FOR_FETCH
    else
        echo "Vault is not reachable at ${VAULT_ADDR}; using existing environment/.env values."
    fi
fi

if [ -n "${GOOGLE_GENERATIVE_AI_API_KEY:-}" ]; then
    export GOOGLE_API_KEY="${GOOGLE_API_KEY:-$GOOGLE_GENERATIVE_AI_API_KEY}"
    export GEMINI_API_KEY="${GEMINI_API_KEY:-$GOOGLE_GENERATIVE_AI_API_KEY}"
fi

if [ -z "${GOOGLE_API_KEY:-}" ] && [ -z "${GEMINI_API_KEY:-}" ]; then
    echo "Warning: Gemini API key is not loaded. Set VAULT_TOKEN or GOOGLE_GENERATIVE_AI_API_KEY before starting."
fi

export OPENCLAW_ENV=production
export OPENCLAW_HOST=127.0.0.1
export OPENCLAW_CONFIG="$OPENCLAW_CONFIG_DIR/policies.yaml"
export OPENCLAW_AUTO_RATE_LIMIT_RETRY="${OPENCLAW_AUTO_RATE_LIMIT_RETRY:-1}"
export OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_WAIT_MS="${OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_WAIT_MS:-86400000}"
export OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_ATTEMPTS="${OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_ATTEMPTS:-48}"

# Add global npm bin to PATH
export PATH="$(npm get prefix)/bin:$PATH"

# 2. Check dependencies
if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js is not installed. Please install Node.js 22+ (e.g., via Homebrew: brew install node)"
    exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw is not installed globally. Installing..."
    npm install -g openclaw@latest playwright pnpm
fi

node "$REPO_DIR/patch_openclaw_rate_limit_retry.js"

# 3. Create required directories if they don't exist
mkdir -p "$OPENCLAW_WORKSPACE" "$OPENCLAW_SKILLS_DIR" "$OPENCLAW_CONFIG_DIR" "$OPENCLAW_DATA_DIR" "$OPENCLAW_AGENT_WORKSPACE"

# OpenClaw loads workspace skills from the active agent workspace:
#   <agent-workspace>/skills/<skill>/SKILL.md
# Keep that path pointed at this repo's curated skills directory.
if [ -e "$OPENCLAW_AGENT_WORKSPACE/skills" ] && [ ! -L "$OPENCLAW_AGENT_WORKSPACE/skills" ]; then
    echo "Warning: $OPENCLAW_AGENT_WORKSPACE/skills exists and is not a symlink; leaving it unchanged."
else
    ln -sfn "$OPENCLAW_SKILLS_DIR" "$OPENCLAW_AGENT_WORKSPACE/skills"
fi

# Ensure we use the local openclaw_data folder for config instead of the user's home ~/.openclaw
export OPENCLAW_DATA_DIR="$REPO_DIR/openclaw_data"
# Force OpenClaw to use local directory by modifying env variable if supported
export OPENCLAW_HOME="$OPENCLAW_DATA_DIR"

node <<'NODE'
const fs = require("fs");
const path = process.env.OPENCLAW_CONFIG_PATH;
const token = (process.env.TELEGRAM_BOT_TOKEN || "").trim();
const googleKey = (
  process.env.GOOGLE_GENERATIVE_AI_API_KEY ||
  process.env.GOOGLE_API_KEY ||
  process.env.GEMINI_API_KEY ||
  ""
).trim();
const nineRouterKey = (
  process.env.NINE_ROUTER_API_KEY ||
  process.env.ROUTER9_API_KEY ||
  ""
).trim();
const nineRouterBaseUrl = (
  process.env.NINE_ROUTER_BASE_URL ||
  "http://127.0.0.1:20128/v1"
).trim();
const nineRouterModel = (
  process.env.NINE_ROUTER_MODEL ||
  "cx/gpt-5.5"
).trim();
const allowedUsers = (process.env.TELEGRAM_ALLOWED_USERS || "")
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

if (!path) {
  process.exit(0);
}

let data = {};
if (fs.existsSync(path)) {
  data = JSON.parse(fs.readFileSync(path, "utf8"));
}

data.channels ??= {};
data.channels.telegram ??= {};
data.channels.telegram.enabled = true;
data.gateway ??= {};
data.gateway.mode = "local";
data.gateway.bind = "loopback";
delete data.gateway.customBindHost;
data.models ??= {};
data.models.providers ??= {};
if (data.models.providers.google && Object.keys(data.models.providers.google).length === 0) {
  delete data.models.providers.google;
}
const existingNineRouterProvider = data.models.providers["9router"] || {};
const resolvedNineRouterKey = nineRouterKey || String(existingNineRouterProvider.apiKey || "").trim();
const resolvedNineRouterBaseUrl =
  nineRouterBaseUrl || String(existingNineRouterProvider.baseUrl || "").trim();
const resolvedNineRouterModel =
  nineRouterModel ||
  String(existingNineRouterProvider.models?.[0]?.id || "").trim() ||
  "cx/gpt-5.5";

if (resolvedNineRouterKey) {
  data.models.providers["9router"] = {
    ...existingNineRouterProvider,
    baseUrl: resolvedNineRouterBaseUrl,
    apiKey: resolvedNineRouterKey,
    api: "openai-completions",
    models: [
      {
        id: resolvedNineRouterModel,
        name: resolvedNineRouterModel,
      },
    ],
  };
}
data.agents ??= {};
data.agents.defaults ??= {};
data.agents.defaults.workspace = process.env.OPENCLAW_AGENT_WORKSPACE;
data.agents.defaults.model = {
  primary: resolvedNineRouterKey ? `9router/${resolvedNineRouterModel}` : "google/gemini-3.1-flash-lite-preview",
  fallbacks: resolvedNineRouterKey ? ["google/gemini-3.1-flash-lite-preview"] : [],
};
data.agents.defaults.models ??= {};
data.agents.defaults.models["google/gemini-3.1-flash-lite-preview"] ??= {};
if (resolvedNineRouterKey) {
  data.agents.defaults.models[`9router/${resolvedNineRouterModel}`] ??= {};
}
data.agents.defaults.timeoutSeconds = Math.max(
  Number(data.agents.defaults.timeoutSeconds) || 0,
  86400
);
data.agents.defaults.maxConcurrent = Math.min(
  Number(data.agents.defaults.maxConcurrent) || 1,
  1
);
data.agents.defaults.subagents ??= {};
data.agents.defaults.subagents.maxConcurrent = Math.min(
  Number(data.agents.defaults.subagents.maxConcurrent) || 2,
  2
);
data.auth ??= {};
data.auth.cooldowns ??= {};
data.auth.cooldowns.rateLimitedProfileRotations = 1;
data.auth.cooldowns.overloadedProfileRotations = 1;
data.env ??= {};
data.env.shellEnv ??= {};
data.env.shellEnv.enabled = true;
data.env.vars ??= {};

for (const key of [
  "JIRA_BASE_URL",
  "JIRA_USER_EMAIL",
  "JIRA_API_TOKEN",
  "FIGMA_API_TOKEN",
  "FIGMA_FILE_KEY",
  "FIGMA_TEAM_ID",
  "FIGMA_ORG_ID",
  "NINE_ROUTER_API_KEY",
  "NINE_ROUTER_BASE_URL",
  "NINE_ROUTER_MODEL",
  "GMAIL_ACCOUNT",
  "GMAIL_USER",
  "GMAIL_APP_PASSWORD",
  "BROWSERACT_API_KEY",
  "APIFY_TOKEN",
  "AMADEUS_API_KEY",
  "AMADEUS_API_SECRET",
  "AMADEUS_BASE_URL",
  "AGENT_BRAIN_SUPERMEMORY_SYNC",
  "AGENT_BRAIN_PII_MODE",
  "AGENT_BRAIN_REMOTE_EMBEDDINGS",
  "AUTONOMY_START_HOUR",
  "AUTONOMY_END_HOUR",
  "TIMEZONE",
  "HITL_FILE_DELETION",
  "HITL_SYSTEM_COMMANDS",
  "HITL_EXTERNAL_API",
  "OPENCLAW_HEARTBEAT_INTERVAL",
  "OPENCLAW_LOCAL_ONLY",
]) {
  const value = (process.env[key] || "").trim();
  if (value) data.env.vars[key] = value;
}

if (googleKey) {
  process.env.GOOGLE_API_KEY = googleKey;
  process.env.GEMINI_API_KEY = googleKey;
}

if (token) {
  data.channels.telegram.botToken = token;
}

if (allowedUsers.length > 0) {
  data.channels.telegram.dmPolicy = "allowlist";
  data.channels.telegram.allowFrom = allowedUsers;
  data.commands ??= {};
  data.commands.ownerAllowFrom = [
    ...new Set([
      ...(Array.isArray(data.commands.ownerAllowFrom) ? data.commands.ownerAllowFrom : []),
      ...allowedUsers.map((userId) => `telegram:${userId}`),
    ]),
  ];
}

fs.writeFileSync(path, `${JSON.stringify(data, null, 2)}\n`);
console.log(`nine_router_provider_configured=${Boolean(resolvedNineRouterKey)}`);
console.log(`openclaw_default_model=${data.agents?.defaults?.model?.primary || ""}`);
NODE

# 4. Start the gateway
echo "Starting OpenClaw Native Gateway..."
echo "Workspace: $OPENCLAW_WORKSPACE"
echo "Policies: $OPENCLAW_CONFIG"
echo "State: $OPENCLAW_DATA_DIR"

if command -v lsof >/dev/null 2>&1; then
    LISTENER_PIDS="$(lsof -tiTCP:18789 -sTCP:LISTEN 2>/dev/null || true)"
    if [ -n "$LISTENER_PIDS" ]; then
        echo "Port 18789 is already in use by PID(s): $LISTENER_PIDS"
        echo "If this is an existing OpenClaw gateway, leave this terminal closed and keep using Telegram."
        echo "To restart cleanly, run: kill $LISTENER_PIDS && sleep 3 && ./start_native.sh"
        exit 0
    fi
fi

openclaw gateway --allow-unconfigured --port 18789
