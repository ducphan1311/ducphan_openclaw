#!/usr/bin/env node

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const repoDir = path.resolve(__dirname, "..");
const outDir = path.join(repoDir, "openclaw_data", ".openclaw", "workspace", "email_scans");

const args = new Map();
for (let i = 2; i < process.argv.length; i += 1) {
  const arg = process.argv[i];
  if (!arg.startsWith("--")) continue;
  const key = arg.slice(2);
  const next = process.argv[i + 1];
  if (!next || next.startsWith("--")) {
    args.set(key, "true");
  } else {
    args.set(key, next);
    i += 1;
  }
}

const folder = args.get("folder") || "[Gmail]/All Mail";
const pageSize = Number(args.get("page-size") || "500");
const maxPages = Number(args.get("max-pages") || "0");
const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
const safeFolder = folder.replace(/[^a-zA-Z0-9._-]+/g, "_").replace(/^_+|_+$/g, "") || "mail";
const outPath = args.get("out") || path.join(outDir, `${safeFolder}-${timestamp}.json`);

if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 5000) {
  console.error("page-size must be an integer between 1 and 5000");
  process.exit(2);
}

fs.mkdirSync(path.dirname(outPath), { recursive: true });

const all = [];
const seen = new Set();
let page = 1;

for (;;) {
  if (maxPages > 0 && page > maxPages) break;

  const result = spawnSync(
    "himalaya",
    [
      "envelope",
      "list",
      "--folder",
      folder,
      "--page-size",
      String(pageSize),
      "--page",
      String(page),
      "--output",
      "json",
    ],
    { encoding: "utf8", maxBuffer: 1024 * 1024 * 64 }
  );

  if (result.status !== 0) {
    const stderr = result.stderr || "";
    const stdout = result.stdout || "";
    const combined = `${stderr}\n${stdout}`;
    if (/out of bound|out-of-bound|page number/i.test(combined)) {
      break;
    }
    console.error(`himalaya failed on page ${page}`);
    console.error(stderr.trim() || stdout.trim());
    process.exit(result.status || 1);
  }

  let batch;
  try {
    batch = JSON.parse(result.stdout || "[]");
  } catch (error) {
    console.error(`failed to parse JSON on page ${page}: ${error.message}`);
    process.exit(1);
  }

  if (!Array.isArray(batch) || batch.length === 0) break;

  for (const envelope of batch) {
    const key = String(envelope.id || "");
    if (!key || seen.has(key)) continue;
    seen.add(key);
    all.push(envelope);
  }

  process.stderr.write(`scanned page=${page} batch=${batch.length} total=${all.length}\n`);

  if (batch.length < pageSize) break;
  page += 1;
}

const payload = {
  folder,
  pageSize,
  scannedAt: new Date().toISOString(),
  count: all.length,
  envelopes: all,
};

fs.writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`, { mode: 0o600 });
console.log(JSON.stringify({ folder, count: all.length, pagesScanned: page, outPath }, null, 2));
