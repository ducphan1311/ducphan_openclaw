#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const PATCH_MARKER = "OPENCLAW_NATIVE_AUTO_RATE_LIMIT_RETRY_PATCH";
const DEFAULT_MAX_WAIT_MS = 24 * 60 * 60 * 1000;
const DEFAULT_BUFFER_MS = 5000;
const DEFAULT_MAX_ATTEMPTS = 48;

function findOpenClawDistDir() {
  const knownBins = [
    "/opt/homebrew/bin/openclaw",
    "/usr/local/bin/openclaw",
  ];
  let bin = "";
  try {
    bin = execFileSync("which", ["openclaw"], { encoding: "utf8" }).trim();
  } catch {
    bin = "";
  }

  for (const candidateBin of [bin, ...knownBins].filter(Boolean)) {
    if (!fs.existsSync(candidateBin)) continue;
    let real = fs.realpathSync(candidateBin);
    let dir = path.dirname(real);

    for (let i = 0; i < 8; i += 1) {
      const candidate = path.join(dir, "dist", "agent-runner.runtime-DwojO3MD.js");
      if (fs.existsSync(candidate)) return path.dirname(candidate);
      dir = path.dirname(dir);
    }
  }

  const homebrewCandidate =
    "/opt/homebrew/Cellar/node@22/22.22.2_2/lib/node_modules/openclaw/dist/agent-runner.runtime-DwojO3MD.js";
  if (fs.existsSync(homebrewCandidate)) return path.dirname(homebrewCandidate);

  throw new Error(`Cannot locate OpenClaw runtime dist from ${bin}`);
}

function patchAgentRunner(file) {
  const original = fs.readFileSync(file, "utf8");
  if (original.includes(PATCH_MARKER) && original.includes("Google Generative AI API error")) {
    console.log("OpenClaw rate-limit auto-retry patch already applied.");
    return false;
  }
  if (original.includes(PATCH_MARKER) && !original.includes("Google Generative AI API error")) {
    const patched = original
      .replace(
        `function resolveNativeAutoRateLimitRetryDelayMs(err) {
\tif (!isFallbackSummaryError(err) || !isPureTransientRateLimitSummary(err)) return null;
\tconst cfg = resolveNativeAutoRateLimitRetryConfig();
\tif (!cfg.enabled) return null;
\tconst expiry = err.soonestCooldownExpiry;
\tconst now = Date.now();
\tconst waitMs = typeof expiry === "number" && Number.isFinite(expiry) && expiry > now ? expiry - now + cfg.bufferMs : 60 * 1000;
\treturn Math.min(Math.max(waitMs, cfg.bufferMs), cfg.maxWaitMs);
}
`,
        `function resolveNativeAutoRateLimitRetryDelayMs(err) {
\tif (!isFallbackSummaryError(err) || !isPureTransientRateLimitSummary(err)) return null;
\tconst cfg = resolveNativeAutoRateLimitRetryConfig();
\tif (!cfg.enabled) return null;
\tconst expiry = err.soonestCooldownExpiry;
\tconst now = Date.now();
\tconst waitMs = typeof expiry === "number" && Number.isFinite(expiry) && expiry > now ? expiry - now + cfg.bufferMs : 60 * 1000;
\treturn Math.min(Math.max(waitMs, cfg.bufferMs), cfg.maxWaitMs);
}
function resolveNativeGoogle503RetryDelayMs(err) {
\tconst message = err instanceof Error ? err.message : typeof err === "string" ? err : "";
\tif (!/\\bGoogle Generative AI API error\\s*\\(503\\)\\b/i.test(message)) return null;
\tconst cfg = resolveNativeAutoRateLimitRetryConfig();
\tif (!cfg.enabled) return null;
\treturn Math.min(Math.max(60 * 1000, cfg.bufferMs), cfg.maxWaitMs);
}
`
      )
      .replace(
        `const nativeAutoRateLimitRetryDelayMs = resolveNativeAutoRateLimitRetryDelayMs(err);`,
        `const nativeAutoRateLimitRetryDelayMs = resolveNativeAutoRateLimitRetryDelayMs(err) ?? resolveNativeGoogle503RetryDelayMs(err);`
      );
    if (patched === original || !patched.includes("resolveNativeGoogle503RetryDelayMs")) {
      throw new Error("Cannot upgrade existing OpenClaw rate-limit patch for Google 503.");
    }
    fs.copyFileSync(file, `${file}.pre-google-503-retry.bak`);
    fs.writeFileSync(file, patched);
    console.log(`Upgraded OpenClaw rate-limit auto-retry patch for Google 503 in ${file}`);
    return true;
  }

  const helperAnchor = `function isPureBillingSummary(err) {
\treturn isFallbackSummaryError(err) && err.attempts.length > 0 && err.attempts.every((attempt) => attempt.reason === "billing");
}
`;
  const helper = `${helperAnchor}const ${PATCH_MARKER} = true;
function resolveNativeAutoRateLimitRetryConfig() {
\tconst enabledRaw = String(process.env.OPENCLAW_AUTO_RATE_LIMIT_RETRY ?? "1").trim().toLowerCase();
\tconst enabled = !(enabledRaw === "0" || enabledRaw === "false" || enabledRaw === "off" || enabledRaw === "no");
\tconst parsePositiveInt = (value, fallback) => {
\t\tconst parsed = Number.parseInt(String(value ?? ""), 10);
\t\treturn Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
\t};
\treturn {
\t\tenabled,
\t\tmaxWaitMs: parsePositiveInt(process.env.OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_WAIT_MS, ${DEFAULT_MAX_WAIT_MS}),
\t\tbufferMs: parsePositiveInt(process.env.OPENCLAW_AUTO_RATE_LIMIT_RETRY_BUFFER_MS, ${DEFAULT_BUFFER_MS}),
\t\tmaxAttempts: parsePositiveInt(process.env.OPENCLAW_AUTO_RATE_LIMIT_RETRY_MAX_ATTEMPTS, ${DEFAULT_MAX_ATTEMPTS})
\t};
}
function resolveNativeAutoRateLimitRetryDelayMs(err) {
\tif (!isFallbackSummaryError(err) || !isPureTransientRateLimitSummary(err)) return null;
\tconst cfg = resolveNativeAutoRateLimitRetryConfig();
\tif (!cfg.enabled) return null;
\tconst expiry = err.soonestCooldownExpiry;
\tconst now = Date.now();
\tconst waitMs = typeof expiry === "number" && Number.isFinite(expiry) && expiry > now ? expiry - now + cfg.bufferMs : 60 * 1000;
\treturn Math.min(Math.max(waitMs, cfg.bufferMs), cfg.maxWaitMs);
}
function resolveNativeGoogle503RetryDelayMs(err) {
\tconst message = err instanceof Error ? err.message : typeof err === "string" ? err : "";
\tif (!/\\bGoogle Generative AI API error\\s*\\(503\\)\\b/i.test(message)) return null;
\tconst cfg = resolveNativeAutoRateLimitRetryConfig();
\tif (!cfg.enabled) return null;
\treturn Math.min(Math.max(60 * 1000, cfg.bufferMs), cfg.maxWaitMs);
}
function sleepNativeAutoRateLimitRetry(ms, abortSignal) {
\treturn new Promise((resolve, reject) => {
\t\tif (abortSignal?.aborted) {
\t\t\treject(abortSignal.reason ?? new Error("Retry aborted"));
\t\t\treturn;
\t\t}
\t\tconst timer = setTimeout(resolve, ms);
\t\tabortSignal?.addEventListener("abort", () => {
\t\t\tclearTimeout(timer);
\t\t\treject(abortSignal.reason ?? new Error("Retry aborted"));
\t\t}, { once: true });
\t});
}
`;

  let patched = original.replace(helperAnchor, helper);
  if (patched === original) {
    throw new Error("Cannot find helper insertion point in OpenClaw runtime.");
  }

  const counterAnchor = `\tlet liveModelSwitchRetries = 0;`;
  const counterReplacement = `\tlet liveModelSwitchRetries = 0;
\tlet nativeAutoRateLimitRetryAttempts = 0;`;
  patched = patched.replace(counterAnchor, counterReplacement);
  if (!patched.includes("nativeAutoRateLimitRetryAttempts = 0")) {
    throw new Error("Cannot find retry counter insertion point in OpenClaw runtime.");
  }

  const catchAnchor = `\t\tif (isTransientHttp && !didRetryTransientHttpError) {
\t\t\tdidRetryTransientHttpError = true;
\t\t\tdefaultRuntime.error(\`Transient HTTP provider error before reply (\${message}). Retrying once in \${TRANSIENT_HTTP_RETRY_DELAY_MS}ms.\`);
\t\t\tawait new Promise((resolve) => {
\t\t\t\tsetTimeout(resolve, TRANSIENT_HTTP_RETRY_DELAY_MS);
\t\t\t});
\t\t\tcontinue;
\t\t}
\t\tdefaultRuntime.error(\`Embedded agent failed before reply: \${message}\`);`;
  const catchReplacement = `\t\tif (isTransientHttp && !didRetryTransientHttpError) {
\t\t\tdidRetryTransientHttpError = true;
\t\t\tdefaultRuntime.error(\`Transient HTTP provider error before reply (\${message}). Retrying once in \${TRANSIENT_HTTP_RETRY_DELAY_MS}ms.\`);
\t\t\tawait new Promise((resolve) => {
\t\t\t\tsetTimeout(resolve, TRANSIENT_HTTP_RETRY_DELAY_MS);
\t\t\t});
\t\t\tcontinue;
\t\t}
\t\tconst nativeAutoRateLimitRetryDelayMs = resolveNativeAutoRateLimitRetryDelayMs(err) ?? resolveNativeGoogle503RetryDelayMs(err);
\t\tconst nativeAutoRateLimitRetryConfig = nativeAutoRateLimitRetryDelayMs === null ? null : resolveNativeAutoRateLimitRetryConfig();
\t\tif (nativeAutoRateLimitRetryDelayMs !== null && nativeAutoRateLimitRetryConfig && nativeAutoRateLimitRetryAttempts < nativeAutoRateLimitRetryConfig.maxAttempts) {
\t\t\tnativeAutoRateLimitRetryAttempts += 1;
\t\t\tdefaultRuntime.error(\`Rate-limit before reply (\${message}). Auto-retrying attempt \${nativeAutoRateLimitRetryAttempts}/\${nativeAutoRateLimitRetryConfig.maxAttempts} in \${nativeAutoRateLimitRetryDelayMs}ms.\`);
\t\t\tawait sleepNativeAutoRateLimitRetry(nativeAutoRateLimitRetryDelayMs, params.replyOperation?.abortSignal ?? params.opts?.abortSignal);
\t\t\tcontinue;
\t\t}
\t\tdefaultRuntime.error(\`Embedded agent failed before reply: \${message}\`);`;
  patched = patched.replace(catchAnchor, catchReplacement);
  if (!patched.includes("Rate-limit before reply")) {
    throw new Error("Cannot find catch insertion point in OpenClaw runtime.");
  }
  fs.copyFileSync(file, `${file}.pre-auto-rate-limit-retry.bak`);
  fs.writeFileSync(file, patched);
  console.log(`Applied OpenClaw rate-limit auto-retry patch to ${file}`);
  return true;
}

function patchErrors(file) {
  const original = fs.readFileSync(file, "utf8");
  if (original.includes("Google Generative AI API error\\s*\\(503\\)")) {
    console.log("OpenClaw Google 503 classifier patch already applied.");
    return false;
  }

  const anchor = `\tif (isRateLimitErrorMessage(raw)) return toReasonClassification("rate_limit");
\tif (isOverloadedErrorMessage(raw)) return toReasonClassification("overloaded");`;
  const replacement = `\tif (isRateLimitErrorMessage(raw)) return toReasonClassification("rate_limit");
\tif (isOverloadedErrorMessage(raw)) return toReasonClassification("overloaded");
\tif (/\\bGoogle Generative AI API error\\s*\\(503\\)\\b/i.test(raw)) return toReasonClassification("overloaded");`;
  const patched = original.replace(anchor, replacement);
  if (patched === original) {
    throw new Error("Cannot find Google 503 classifier insertion point.");
  }
  fs.copyFileSync(file, `${file}.pre-google-503-classifier.bak`);
  fs.writeFileSync(file, patched);
  console.log(`Applied OpenClaw Google 503 classifier patch to ${file}`);
  return true;
}

const distDir = findOpenClawDistDir();
patchAgentRunner(path.join(distDir, "agent-runner.runtime-DwojO3MD.js"));
patchErrors(path.join(distDir, "errors-ClLKaCGB.js"));
