#!/usr/bin/env node
const fs = require("fs");
const os = require("os");
const path = require("path");

const repoDir = path.resolve(__dirname, "..");
const openclawConfigPaths = [
  path.join(repoDir, "openclaw_data", "openclaw.json"),
  path.join(repoDir, "openclaw_data", ".openclaw", "openclaw.json"),
];
const himalayaConfigDir = path.join(os.homedir(), ".config", "himalaya");
const himalayaConfigPath = path.join(himalayaConfigDir, "config.toml");
const credentialHelper = path.join(repoDir, "scripts", "himalaya_gmail_credential.js");

function readConfig(configPath) {
  if (!fs.existsSync(configPath)) return {};
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function writeConfig(configPath, data) {
  fs.writeFileSync(configPath, `${JSON.stringify(data, null, 2)}\n`);
}

function readGmailUser() {
  for (const configPath of openclawConfigPaths) {
    const data = readConfig(configPath);
    const vars = data.env?.vars || {};
    const user = vars.GMAIL_USER || vars.GMAIL_ACCOUNT;
    if (typeof user === "string" && user.trim()) return user.trim();
  }
  if (process.env.GMAIL_USER) return process.env.GMAIL_USER.trim();
  if (process.env.GMAIL_ACCOUNT) return process.env.GMAIL_ACCOUNT.trim();
  throw new Error("GMAIL_USER is missing from OpenClaw config/env");
}

function ensureHimalayaSkillEnabled(configPath) {
  const data = readConfig(configPath);
  data.skills ??= {};
  data.skills.entries ??= {};
  data.skills.entries.himalaya ??= {};
  data.skills.entries.himalaya.enabled = true;
  writeConfig(configPath, data);
  return fs.existsSync(configPath);
}

function tomlString(value) {
  return JSON.stringify(value);
}

function buildHimalayaConfig(email) {
  const nodeBin = process.execPath;
  const passwordCmd = `${nodeBin} ${credentialHelper} password`;

  return `# Managed by openclaw_manager/scripts/setup_himalaya_gmail.js
# Password is not stored here. Himalaya reads it from OpenClaw env/config via auth.cmd.

[accounts.gmail]
email = ${tomlString(email)}
display-name = ${tomlString(email)}
default = true

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = ${tomlString(email)}
backend.auth.type = "password"
backend.auth.cmd = ${tomlString(passwordCmd)}

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = ${tomlString(email)}
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = ${tomlString(passwordCmd)}

folder.aliases.inbox = "INBOX"
folder.aliases.sent = "[Gmail]/Sent Mail"
folder.aliases.drafts = "[Gmail]/Drafts"
folder.aliases.trash = "[Gmail]/Bin"
`;
}

function writeHimalayaConfig(email) {
  fs.mkdirSync(himalayaConfigDir, { recursive: true, mode: 0o700 });
  if (fs.existsSync(himalayaConfigPath)) {
    const existing = fs.readFileSync(himalayaConfigPath, "utf8");
    if (!existing.includes("Managed by openclaw_manager/scripts/setup_himalaya_gmail.js")) {
      const backup = `${himalayaConfigPath}.bak-${Date.now()}`;
      fs.copyFileSync(himalayaConfigPath, backup);
      console.log(`existing_himalaya_config_backup=${backup}`);
    }
  }
  fs.writeFileSync(himalayaConfigPath, buildHimalayaConfig(email), { mode: 0o600 });
}

try {
  const email = readGmailUser();
  for (const configPath of openclawConfigPaths) {
    console.log(`${path.relative(repoDir, configPath)}_himalaya_enabled=${ensureHimalayaSkillEnabled(configPath)}`);
  }
  writeHimalayaConfig(email);
  console.log(`himalaya_config=${himalayaConfigPath}`);
  console.log("himalaya_gmail_setup=true");
} catch (error) {
  console.error(`himalaya_gmail_setup_error=${error.message}`);
  process.exit(1);
}
