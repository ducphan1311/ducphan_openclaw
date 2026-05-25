#!/usr/bin/env node
"use strict";

try {
  const raw = process.env.SECRETS_JSON;
  if (!raw) throw new Error("SECRETS_JSON is empty");
  const parsed = JSON.parse(raw);
  if (Array.isArray(parsed.errors) && parsed.errors.length > 0) {
    throw new Error(parsed.errors.join("; "));
  }
  const secrets = parsed.data?.data ?? parsed.data;
  if (!secrets || typeof secrets !== "object") {
    throw new Error("unexpected Vault response shape");
  }
  const aliases = {
    "9ROUTER_API_KEY": "NINE_ROUTER_API_KEY",
    "9ROUTER_BASE_URL": "NINE_ROUTER_BASE_URL",
    "9ROUTER_MODEL": "NINE_ROUTER_MODEL"
  };
  const emit = (key, value) => {
    if (value === null || value === undefined || value === "") return;
    key = aliases[key] || key;
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) return;
    const safeValue = String(value).replace(/'/g, "'\\''");
    console.log(`export ${key}='${safeValue}'`);
  };
  for (const [key, value] of Object.entries(secrets)) {
    emit(key, value);
    if (key === "GOOGLE_GENERATIVE_AI_API_KEY") {
      emit("GOOGLE_API_KEY", value);
      emit("GEMINI_API_KEY", value);
    }
  }
} catch (error) {
  console.error(`Failed to parse Vault secrets: ${error.message}`);
  process.exit(1);
}

