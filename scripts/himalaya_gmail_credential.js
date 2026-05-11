#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const repoDir = path.resolve(__dirname, "..");
const configPaths = [
  process.env.OPENCLAW_CONFIG_PATH,
  path.join(repoDir, "openclaw_data", "openclaw.json"),
  path.join(repoDir, "openclaw_data", ".openclaw", "openclaw.json"),
].filter(Boolean);

const field = process.argv[2] || "password";
const keyByField = {
  account: "GMAIL_ACCOUNT",
  password: "GMAIL_APP_PASSWORD",
  user: "GMAIL_USER",
};

const key = keyByField[field];
if (!key) {
  console.error("usage: himalaya_gmail_credential.js user|account|password");
  process.exit(64);
}

function readFromConfig(configPath) {
  try {
    const data = JSON.parse(fs.readFileSync(configPath, "utf8"));
    const vars = data.env?.vars || {};
    if (vars[key]) return String(vars[key]);
    if (field === "account" && vars.GMAIL_USER) return String(vars.GMAIL_USER);
  } catch {
    return "";
  }
  return "";
}

const value =
  process.env[key] ||
  (field === "account" ? process.env.GMAIL_USER : "") ||
  configPaths.map(readFromConfig).find(Boolean) ||
  "";

const output = field === "password" ? value.replace(/\s+/g, "") : value.trim();

if (!output) {
  console.error(`${key}_missing=true`);
  process.exit(78);
}

process.stdout.write(output);
