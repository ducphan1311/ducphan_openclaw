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

function updateConfig(configPath, secrets) {
  if (!fs.existsSync(configPath)) return false;
  const data = JSON.parse(fs.readFileSync(configPath, "utf8"));
  data.env ??= {};
  data.env.shellEnv ??= {};
  data.env.shellEnv.enabled = true;
  data.env.vars ??= {};
  data.env.vars.GMAIL_USER = secrets.GMAIL_USER;
  data.env.vars.GMAIL_APP_PASSWORD = secrets.GMAIL_APP_PASSWORD;
  data.env.vars.GMAIL_ACCOUNT = secrets.GMAIL_ACCOUNT || secrets.GMAIL_USER;
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
  const hasUser = typeof secrets.GMAIL_USER === "string" && secrets.GMAIL_USER.length > 0;
  const hasPassword =
    typeof secrets.GMAIL_APP_PASSWORD === "string" && secrets.GMAIL_APP_PASSWORD.length > 0;

  console.log(`gmail_user_present_in_vault=${hasUser}`);
  console.log(`gmail_app_password_present_in_vault=${hasPassword}`);

  if (!hasUser || !hasPassword) {
    console.error("gmail_secret_sync=false");
    process.exit(3);
  }

  for (const configPath of configPaths) {
    console.log(`${path.relative(repoDir, configPath)}_updated=${updateConfig(configPath, secrets)}`);
  }

  console.log("gmail_secret_sync=true");
} catch (error) {
  console.error(`gmail_secret_sync_error=${error.message}`);
  process.exit(1);
}
