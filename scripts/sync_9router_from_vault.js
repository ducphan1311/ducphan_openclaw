#!/usr/bin/env node

const fs = require("fs");
const { execFileSync } = require("child_process");
const path = require("path");

const repoDir = path.resolve(__dirname, "..");
const vaultAddr = process.env.VAULT_ADDR || "http://127.0.0.1:8200";
const secretPath = process.env.OPENCLAW_VAULT_SECRET_PATH || "openclaw_secrets/data/api_keys";
const configPaths = [
  path.join(repoDir, "openclaw_data", "openclaw.json"),
  path.join(repoDir, "openclaw_data", ".openclaw", "openclaw.json"),
];

function readVaultToken() {
  if (process.env.VAULT_TOKEN && process.env.VAULT_TOKEN.trim()) {
    return process.env.VAULT_TOKEN.trim();
  }
  try {
    return fs.readFileSync(path.join(process.env.HOME || "", ".vault-token"), "utf8").trim();
  } catch {
    return "";
  }
}

function fetchSecrets(token) {
  const raw = execFileSync(
    "curl",
    ["-sS", "-L", "-H", `X-Vault-Token: ${token}`, `${vaultAddr}/v1/${secretPath}`],
    { encoding: "utf8", maxBuffer: 1024 * 1024 }
  );
  const parsed = JSON.parse(raw);
  if (Array.isArray(parsed.errors) && parsed.errors.length > 0) {
    throw new Error(parsed.errors.join("; "));
  }
  const secrets = parsed.data?.data ?? parsed.data;
  if (!secrets || typeof secrets !== "object") {
    throw new Error("unexpected Vault response shape");
  }
  return secrets;
}

function firstString(secrets, keys, fallback = "") {
  for (const key of keys) {
    const value = secrets[key];
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return fallback;
}

function updateConfig(configPath, values) {
  if (!fs.existsSync(configPath)) return false;
  const data = JSON.parse(fs.readFileSync(configPath, "utf8"));

  data.env ??= {};
  data.env.shellEnv ??= {};
  data.env.shellEnv.enabled = true;
  data.env.vars ??= {};
  data.env.vars.NINE_ROUTER_API_KEY = values.apiKey;
  data.env.vars.NINE_ROUTER_BASE_URL = values.baseUrl;
  data.env.vars.NINE_ROUTER_MODEL = values.model;

  data.models ??= {};
  data.models.providers ??= {};
  data.models.providers["9router"] = {
    ...(data.models.providers["9router"] || {}),
    baseUrl: values.baseUrl,
    apiKey: values.apiKey,
    api: "openai-completions",
    models: [{ id: values.model, name: values.model }],
  };

  data.agents ??= {};
  data.agents.defaults ??= {};
  data.agents.defaults.model = {
    primary: `9router/${values.model}`,
    fallbacks: ["google/gemini-3.1-flash-lite-preview"],
  };
  data.agents.defaults.models ??= {};
  data.agents.defaults.models[`9router/${values.model}`] ??= {};
  data.agents.defaults.models["google/gemini-3.1-flash-lite-preview"] ??= {};

  fs.writeFileSync(configPath, `${JSON.stringify(data, null, 2)}\n`);
  return true;
}

try {
  const token = readVaultToken();
  if (!token) {
    console.error("vault_token_present=false");
    process.exit(2);
  }

  const secrets = fetchSecrets(token);
  const apiKey = firstString(secrets, [
    "NINE_ROUTER_API_KEY",
    "9ROUTER_API_KEY",
    "ROUTER9_API_KEY",
  ]);
  const baseUrl = firstString(
    secrets,
    ["NINE_ROUTER_BASE_URL", "9ROUTER_BASE_URL", "ROUTER9_BASE_URL"],
    "http://127.0.0.1:20128/v1"
  );
  const model = firstString(
    secrets,
    ["NINE_ROUTER_MODEL", "9ROUTER_MODEL", "ROUTER9_MODEL"],
    "cx/gpt-5.5"
  );

  console.log(`nine_router_api_key_present_in_vault=${Boolean(apiKey)}`);
  console.log(`nine_router_base_url=${baseUrl}`);
  console.log(`nine_router_model=${model}`);

  if (!apiKey) {
    console.error("nine_router_secret_sync=false");
    process.exit(3);
  }

  for (const configPath of configPaths) {
    console.log(`${path.relative(repoDir, configPath)}_updated=${updateConfig(configPath, { apiKey, baseUrl, model })}`);
  }

  console.log("nine_router_secret_sync=true");
} catch (error) {
  console.error(`nine_router_secret_sync_error=${error.message}`);
  process.exit(1);
}
