#!/usr/bin/env node

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const repoDir = path.resolve(__dirname, "..");
const configPaths = [
  path.join(repoDir, "openclaw_data", "openclaw.json"),
  path.join(repoDir, "openclaw_data", ".openclaw", "openclaw.json"),
];
const cronJobsPath = path.join(repoDir, "openclaw_data", "cron", "jobs.json");
const reportPath = path.join(
  repoDir,
  "openclaw_data",
  ".openclaw",
  "workspace",
  "openclaw-self-heal-report.json"
);

const report = {
  checkedAt: new Date().toISOString(),
  fixes: [],
  warnings: [],
  status: {},
};

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJson(filePath, data) {
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 8,
    ...options,
  });
  return {
    ok: result.status === 0,
    status: result.status,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
  };
}

function normalizeConfig(configPath) {
  if (!fs.existsSync(configPath)) {
    report.warnings.push(`${path.relative(repoDir, configPath)} missing`);
    return;
  }

  const data = readJson(configPath);
  const before = JSON.stringify(data);

  data.env ??= {};
  data.env.shellEnv ??= {};
  data.env.shellEnv.enabled = true;
  data.env.vars ??= {};
  data.env.vars.OPENCLAW_HEARTBEAT_INTERVAL = String(
    data.env.vars.OPENCLAW_HEARTBEAT_INTERVAL || "60"
  );

  data.browser ??= {};
  data.browser.enabled = true;
  data.browser.headless = false;
  data.browser.defaultProfile = "facebook-travel";
  data.browser.profiles ??= {};
  const profileName = "facebook-travel";
  const usedCdpPorts = new Set(
    Object.entries(data.browser.profiles)
      .filter(([name]) => name !== profileName)
      .map(([, profile]) => Number(profile?.cdpPort))
      .filter((port) => Number.isInteger(port) && port > 0)
  );
  const currentProfile = data.browser.profiles[profileName] || {};
  let cdpPort =
    Number.isInteger(Number(currentProfile.cdpPort)) &&
    Number(currentProfile.cdpPort) > 0
      ? Number(currentProfile.cdpPort)
      : 18821;
  while (usedCdpPorts.has(cdpPort)) {
    cdpPort += 1;
  }
  data.browser.profiles[profileName] = {
    ...currentProfile,
    driver: "openclaw",
    cdpPort,
    color: currentProfile.color || "#3B82F6",
    headless: false,
  };
  data.browser.snapshotDefaults = {
    ...(data.browser.snapshotDefaults || {}),
    mode: "efficient",
  };
  data.browser.tabCleanup = {
    ...(data.browser.tabCleanup || {}),
    enabled: true,
    idleMinutes: 30,
    maxTabsPerSession: 6,
    sweepMinutes: 5,
  };

  data.tools ??= {};
  data.tools.profile ||= "coding";
  const alsoAllow = new Set(Array.isArray(data.tools.alsoAllow) ? data.tools.alsoAllow : []);
  alsoAllow.add("browser");
  data.tools.alsoAllow = [...alsoAllow];

  data.agents ??= {};
  data.agents.defaults ??= {};
  data.agents.defaults.heartbeat ??= {};
  if (configPath.endsWith(path.join("openclaw_data", "openclaw.json"))) {
    data.agents.defaults.heartbeat.every = "60m";
  }
  data.agents.defaults.maxConcurrent = Math.min(
    Number(data.agents.defaults.maxConcurrent) || 1,
    1
  );
  data.agents.defaults.subagents ??= {};
  data.agents.defaults.subagents.maxConcurrent = Math.min(
    Number(data.agents.defaults.subagents.maxConcurrent) || 2,
    2
  );
  data.agents.defaults.bootstrapMaxChars = Math.min(
    Number(data.agents.defaults.bootstrapMaxChars) || 8000,
    8000
  );
  data.agents.defaults.bootstrapTotalMaxChars = Math.min(
    Number(data.agents.defaults.bootstrapTotalMaxChars) || 30000,
    30000
  );
  data.agents.defaults.contextLimits ??= {};
  data.agents.defaults.contextLimits.toolResultMaxChars = Math.min(
    Number(data.agents.defaults.contextLimits.toolResultMaxChars) || 12000,
    12000
  );
  data.agents.defaults.contextLimits.memoryGetMaxChars = Math.min(
    Number(data.agents.defaults.contextLimits.memoryGetMaxChars) || 12000,
    12000
  );
  data.agents.defaults.contextLimits.postCompactionMaxChars = Math.min(
    Number(data.agents.defaults.contextLimits.postCompactionMaxChars) || 6000,
    6000
  );
  data.agents.defaults.compaction ??= {};
  data.agents.defaults.compaction.mode = "safeguard";
  data.agents.defaults.compaction.reserveTokens = Math.max(
    Number(data.agents.defaults.compaction.reserveTokens) || 0,
    24000
  );
  data.agents.defaults.compaction.keepRecentTokens = Math.min(
    Number(data.agents.defaults.compaction.keepRecentTokens) || 12000,
    12000
  );
  data.agents.defaults.compaction.maxHistoryShare = Math.min(
    Number(data.agents.defaults.compaction.maxHistoryShare) || 0.45,
    0.45
  );
  data.agents.defaults.compaction.recentTurnsPreserve = Math.min(
    Number(data.agents.defaults.compaction.recentTurnsPreserve) || 2,
    2
  );
  data.agents.defaults.compaction.midTurnPrecheck ??= {};
  data.agents.defaults.compaction.midTurnPrecheck.enabled = true;

  const nineRouter = data.models?.providers?.["9router"];
  const modelId = nineRouter?.models?.[0]?.id || data.env.vars.NINE_ROUTER_MODEL || "oc1";
  if (nineRouter?.apiKey) {
    nineRouter.baseUrl ||= data.env.vars.NINE_ROUTER_BASE_URL || "http://127.0.0.1:20128/v1";
    nineRouter.api = "openai-completions";
    nineRouter.models = [{ id: modelId, name: modelId }];
    data.env.vars.NINE_ROUTER_BASE_URL = nineRouter.baseUrl;
    data.env.vars.NINE_ROUTER_MODEL = modelId;
    data.env.vars.NINE_ROUTER_API_KEY ||= nineRouter.apiKey;
    // 9router combo (e.g. "oc1") owns routing/fallback. Do not inject
    // hardcoded fallback models from the orchestration layer.
    data.agents.defaults.model = {
      primary: `9router/${modelId}`,
      fallbacks: [],
    };
    data.agents.defaults.models ??= {};
    data.agents.defaults.models[`9router/${modelId}`] ??= {};
    // Drop legacy hardcoded fallback if present.
    delete data.agents.defaults.models["google/gemini-3.1-flash-lite-preview"];
  }

  if (JSON.stringify(data) !== before) {
    writeJson(configPath, data);
    report.fixes.push(`normalized ${path.relative(repoDir, configPath)}`);
  }

  report.status[path.relative(repoDir, configPath)] = {
    primary: data.agents?.defaults?.model?.primary || null,
    has9router: Boolean(data.models?.providers?.["9router"]?.apiKey),
    heartbeat: data.agents?.defaults?.heartbeat?.every || data.env?.vars?.OPENCLAW_HEARTBEAT_INTERVAL || null,
    browserDefaultProfile: data.browser?.defaultProfile || null,
  };
}

function disableNoisyCronJobs() {
  if (!fs.existsSync(cronJobsPath)) return;
  const data = readJson(cronJobsPath);
  const before = JSON.stringify(data);
  for (const job of data.jobs || []) {
    const text = `${job.name || ""} ${job.description || ""} ${job.payload?.message || ""}`.toLowerCase();
    const everyMs = Number(job.schedule?.everyMs || 0);
    const isNoisyStatusJob =
      everyMs > 0 &&
      everyMs < 30 * 60 * 1000 &&
      /(status|progress|update|cleanup|report)/.test(text);
    if (job.enabled && isNoisyStatusJob) {
      job.enabled = false;
      report.fixes.push(`disabled noisy cron job ${job.id || job.name || "unknown"}`);
    }
  }
  if (JSON.stringify(data) !== before) {
    writeJson(cronJobsPath, data);
  }
}

function check9RouterEndpoint() {
  const config = fs.existsSync(configPaths[0]) ? readJson(configPaths[0]) : {};
  const baseUrl = config.models?.providers?.["9router"]?.baseUrl || "";
  if (!baseUrl) return;
  if (!/^http:\/\/(127\.0\.0\.1|localhost|\[::1\])(:|\/)/.test(baseUrl)) {
    report.warnings.push("9router baseUrl is not loopback; verify exposure and auth policy");
    return;
  }
  const url = `${baseUrl.replace(/\/+$/, "")}/models`;
  const portMatch = baseUrl.match(/:(\d+)(?:\/|$)/);
  const listener =
    portMatch &&
    run("lsof", ["-nP", `-iTCP:${portMatch[1]}`, "-sTCP:LISTEN"]).ok;
  const result = run("curl", ["-sS", "--max-time", "2", url]);
  report.status["9routerEndpoint"] = {
    url,
    reachable: result.ok,
    listener: Boolean(listener),
  };
  if (!result.ok && !listener) {
    report.warnings.push("9router endpoint is not reachable; start 9router before using 9router models");
  }
}

function validateConfig() {
  const openclaw = "/opt/homebrew/Cellar/node@22/22.22.2_2/bin/openclaw";
  if (!fs.existsSync(openclaw)) return;
  const result = run(openclaw, ["config", "validate"], {
    env: {
      ...process.env,
      OPENCLAW_CONFIG_PATH: configPaths[0],
      OPENCLAW_HOME: path.join(repoDir, "openclaw_data", ".openclaw"),
    },
  });
  report.status.configValidate = result.ok;
  if (!result.ok) {
    report.warnings.push(`openclaw config validate failed: ${(result.stderr || result.stdout).trim()}`);
  }
}

for (const configPath of configPaths) {
  normalizeConfig(configPath);
}
disableNoisyCronJobs();
check9RouterEndpoint();
validateConfig();

fs.mkdirSync(path.dirname(reportPath), { recursive: true });
writeJson(reportPath, report);

console.log(
  JSON.stringify(
    {
      ok: report.warnings.length === 0,
      fixes: report.fixes,
      warnings: report.warnings,
      reportPath,
    },
    null,
    2
  )
);
