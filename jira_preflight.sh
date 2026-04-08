#!/usr/bin/env bash
set -euo pipefail

ISSUE_KEY="${1:-}"
ASSIGNEE_HINT="${2:-}"
TRANSITION_HINT="${3:-}"
EXECUTE_WRITE="${EXECUTE_WRITE:-0}"

if [ -z "$ISSUE_KEY" ]; then
  echo "Usage: ./jira_preflight.sh <ISSUE_KEY> [ASSIGNEE_ACCOUNT_ID_OR_NAME_HINT] [TRANSITION_NAME_OR_ID]"
  echo "Set EXECUTE_WRITE=1 to apply assign/transition after preflight."
  exit 1
fi

docker exec \
  -e ISSUE_KEY="$ISSUE_KEY" \
  -e ASSIGNEE_HINT="$ASSIGNEE_HINT" \
  -e TRANSITION_HINT="$TRANSITION_HINT" \
  -e EXECUTE_WRITE="$EXECUTE_WRITE" \
  openclaw_agent \
  node -e '
const fs = require("fs");
const https = require("https");

const issueKey = (process.env.ISSUE_KEY || "").trim();
const assigneeHint = (process.env.ASSIGNEE_HINT || "").trim();
const transitionHint = (process.env.TRANSITION_HINT || "").trim();
const executeWrite = (process.env.EXECUTE_WRITE || "0") === "1";
const cfg = JSON.parse(fs.readFileSync("/home/openclawuser/.openclaw/openclaw.json", "utf8"));
const vars = (cfg.env && cfg.env.vars) || {};
const baseUrl = (vars.JIRA_BASE_URL || "").replace(/\/$/, "");
const email = vars.JIRA_USER_EMAIL || "";
const token = vars.JIRA_API_TOKEN || "";

if (!baseUrl || !email || !token) {
  console.log(JSON.stringify({
    ok: false,
    error: "MISSING_RUNTIME_CONFIG",
    required: ["JIRA_BASE_URL", "JIRA_USER_EMAIL", "JIRA_API_TOKEN"]
  }, null, 2));
  process.exit(2);
}

const auth = "Basic " + Buffer.from(email + ":" + token).toString("base64");

function request(path, method = "GET", body) {
  return new Promise((resolve) => {
    const url = new URL(baseUrl + path);
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method,
      headers: {
        Authorization: auth,
        Accept: "application/json",
        "Content-Type": "application/json"
      }
    }, (res) => {
      let raw = "";
      res.on("data", (chunk) => raw += chunk);
      res.on("end", () => {
        let json = null;
        try { json = JSON.parse(raw); } catch {}
        resolve({ status: res.statusCode || 0, raw, json });
      });
    });
    req.on("error", (err) => resolve({ status: 0, raw: String(err), json: null }));
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function briefBody(obj) {
  if (!obj) return null;
  if (Array.isArray(obj)) return { type: "array", length: obj.length };
  const errorMessages = obj.errorMessages || null;
  const errors = obj.errors || null;
  if (errorMessages || errors) return { errorMessages, errors };
  return null;
}

function failureDetails(res) {
  const body = briefBody(res && res.json);
  const raw = String((res && res.raw) || "").trim();
  return {
    body,
    rawSnippet: raw ? raw.slice(0, 500) : null
  };
}

function normalizeText(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function scoreCandidate(user, hintNorm) {
  const nameNorm = normalizeText(user.displayName || "");
  const emailNorm = normalizeText(user.emailAddress || "");
  const joined = (nameNorm + " " + emailNorm).trim();
  if (!joined || !hintNorm) return 0;
  let score = 0;
  if (nameNorm === hintNorm) score += 1000;
  if (joined.includes(hintNorm)) score += 500;
  const hintTokens = hintNorm.split(" ").filter(Boolean);
  for (const token of hintTokens) {
    if (nameNorm.includes(token)) score += 100;
    else if (emailNorm.includes(token)) score += 60;
  }
  return score;
}

function pickTransition(transitions, hint) {
  if (!hint || !Array.isArray(transitions) || transitions.length === 0) return null;
  const cleanHint = normalizeText(hint);
  const byId = transitions.find((t) => String(t.id) === hint);
  if (byId) return byId;
  const exact = transitions.find((t) => normalizeText(t.name) === cleanHint);
  if (exact) return exact;
  const partial = transitions.find((t) => normalizeText(t.name).includes(cleanHint));
  if (partial) return partial;
  return null;
}

async function resolveAssignee(issueKeyValue, projectKeyValue, hint) {
  if (!hint) return { requested: null, mode: "none", resolved: null, candidates: [] };
  if (hint.includes(":")) {
    const byId = await request("/rest/api/3/user/assignable/search?issueKey=" + encodeURIComponent(issueKeyValue) + "&accountId=" + encodeURIComponent(hint) + "&maxResults=1");
    const users = Array.isArray(byId.json) ? byId.json : [];
    return {
      requested: hint,
      mode: "accountId",
      resolved: users[0] ? { accountId: users[0].accountId, displayName: users[0].displayName } : null,
      candidates: users.map((u) => ({ accountId: u.accountId, displayName: u.displayName }))
    };
  }
  const queryRes = await request("/rest/api/3/user/assignable/search?project=" + encodeURIComponent(projectKeyValue) + "&query=" + encodeURIComponent(hint) + "&maxResults=100");
  const issueScopeRes = await request("/rest/api/3/user/assignable/search?issueKey=" + encodeURIComponent(issueKeyValue) + "&maxResults=100");
  const projectScopeRes = await request("/rest/api/3/user/assignable/search?project=" + encodeURIComponent(projectKeyValue) + "&maxResults=100");
  const merged = new Map();
  for (const list of [queryRes.json, issueScopeRes.json, projectScopeRes.json]) {
    if (!Array.isArray(list)) continue;
    for (const u of list) {
      if (!u || !u.accountId) continue;
      if (!merged.has(u.accountId)) merged.set(u.accountId, u);
    }
  }
  const hintNorm = normalizeText(hint);
  const scored = Array.from(merged.values())
    .map((u) => ({ user: u, score: scoreCandidate(u, hintNorm) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score);
  const resolved = scored[0] ? {
    accountId: scored[0].user.accountId,
    displayName: scored[0].user.displayName,
    score: scored[0].score
  } : null;
  return {
    requested: hint,
    mode: "fuzzy-name",
    resolved,
    candidates: scored.slice(0, 10).map((x) => ({
      accountId: x.user.accountId,
      displayName: x.user.displayName,
      score: x.score
    }))
  };
}

async function run() {
  const result = {
    ok: true,
    issueKey,
    assigneeHint: assigneeHint || null,
    transitionHint: transitionHint || null,
    executeWrite,
    steps: {},
    guidance: {
      manualWebAllowed: false,
      reason: "API_NOT_EVALUATED"
    },
    capability: {
      writeAccess: "unknown",
      evidence: null
    }
  };

  const issueRes = await request("/rest/api/3/issue/" + encodeURIComponent(issueKey));
  const projectKey = issueRes.json && issueRes.json.fields && issueRes.json.fields.project && issueRes.json.fields.project.key;
  result.steps.issue_exists = {
    endpoint: "/rest/api/3/issue/{issueKey}",
    status: issueRes.status,
    pass: issueRes.status === 200,
    details: issueRes.status === 200 ? {
      id: issueRes.json && issueRes.json.id,
      key: issueRes.json && issueRes.json.key,
      projectKey: issueRes.json && issueRes.json.fields && issueRes.json.fields.project && issueRes.json.fields.project.key,
      assigneeAccountId: issueRes.json && issueRes.json.fields && issueRes.json.fields.assignee && issueRes.json.fields.assignee.accountId
    } : briefBody(issueRes.json)
  };

  if (issueRes.status !== 200) {
    result.ok = false;
    console.log(JSON.stringify(result, null, 2));
    process.exit(3);
  }

  const transitionsRes = await request("/rest/api/3/issue/" + encodeURIComponent(issueKey) + "/transitions");
  const transitions = (transitionsRes.json && transitionsRes.json.transitions) || [];
  result.steps.transitions_valid = {
    endpoint: "/rest/api/3/issue/{issueKey}/transitions",
    status: transitionsRes.status,
    pass: transitionsRes.status === 200 && transitions.length > 0,
    details: transitionsRes.status === 200 ? transitions.map((t) => ({ id: t.id, name: t.name })) : briefBody(transitionsRes.json)
  };

  const resolvedAssignee = await resolveAssignee(issueKey, projectKey, assigneeHint);
  const assignablePath = resolvedAssignee.resolved && resolvedAssignee.resolved.accountId
    ? "/rest/api/3/user/assignable/search?issueKey=" + encodeURIComponent(issueKey) + "&accountId=" + encodeURIComponent(resolvedAssignee.resolved.accountId) + "&maxResults=1"
    : "/rest/api/3/user/assignable/search?issueKey=" + encodeURIComponent(issueKey) + "&maxResults=5";
  const assignableRes = await request(assignablePath);
  const assignableUsers = Array.isArray(assignableRes.json) ? assignableRes.json : [];
  const hasResolvedAssignee = !assigneeHint || !!(resolvedAssignee.resolved && resolvedAssignee.resolved.accountId);
  result.steps.assignable_user = {
    endpoint: "/rest/api/3/user/assignable/search",
    status: assignableRes.status,
    pass: assignableRes.status === 200 && assignableUsers.length > 0 && hasResolvedAssignee,
    details: assignableRes.status === 200 ? {
      requested: resolvedAssignee.requested,
      mode: resolvedAssignee.mode,
      resolved: resolvedAssignee.resolved,
      candidates: resolvedAssignee.candidates,
      assignable: assignableUsers.map((u) => ({ accountId: u.accountId, displayName: u.displayName }))
    } : briefBody(assignableRes.json)
  };

  const permsRes = await request("/rest/api/3/mypermissions?issueKey=" + encodeURIComponent(issueKey) + "&permissions=ADD_COMMENTS");
  const canComment = !!(permsRes.json && permsRes.json.permissions && permsRes.json.permissions.ADD_COMMENTS && permsRes.json.permissions.ADD_COMMENTS.havePermission);
  result.steps.comment_permission = {
    endpoint: "/rest/api/3/mypermissions?permissions=ADD_COMMENTS",
    status: permsRes.status,
    pass: permsRes.status === 200 && canComment,
    details: permsRes.status === 200 ? {
      ADD_COMMENTS: canComment
    } : briefBody(permsRes.json)
  };

  if (!result.steps.transitions_valid.pass || !result.steps.assignable_user.pass || !result.steps.comment_permission.pass) {
    result.ok = false;
  }

  if (executeWrite) {
    result.writes = {};
    if (assigneeHint) {
      const accountId = resolvedAssignee.resolved && resolvedAssignee.resolved.accountId;
      if (!accountId) {
        result.writes.assign = {
          attempted: false,
          pass: false,
          reason: "ASSIGNEE_NOT_RESOLVED"
        };
        result.ok = false;
      } else {
        const assignRes = await request("/rest/api/3/issue/" + encodeURIComponent(issueKey) + "/assignee", "PUT", { accountId });
        result.writes.assign = {
          attempted: true,
          endpoint: "/rest/api/3/issue/{issueKey}/assignee",
          status: assignRes.status,
          pass: assignRes.status === 204,
          details: assignRes.status === 204 ? { accountId } : failureDetails(assignRes)
        };
        if (assignRes.status !== 204) result.ok = false;
      }
    }

    if (transitionHint) {
      const chosen = pickTransition(transitions, transitionHint);
      if (!chosen) {
        result.writes.transition = {
          attempted: false,
          pass: false,
          reason: "TRANSITION_NOT_FOUND",
          available: transitions.map((t) => ({ id: t.id, name: t.name }))
        };
        result.ok = false;
      } else {
        const transitionRes = await request("/rest/api/3/issue/" + encodeURIComponent(issueKey) + "/transitions", "POST", {
          transition: { id: String(chosen.id) }
        });
        result.writes.transition = {
          attempted: true,
          endpoint: "/rest/api/3/issue/{issueKey}/transitions",
          transition: { id: chosen.id, name: chosen.name },
          status: transitionRes.status,
          pass: transitionRes.status === 204,
          details: transitionRes.status === 204 ? null : failureDetails(transitionRes)
        };
        if (transitionRes.status !== 204) result.ok = false;
      }
    }

    const verifyRes = await request("/rest/api/3/issue/" + encodeURIComponent(issueKey) + "?fields=status,assignee");
    result.writes.verify = {
      endpoint: "/rest/api/3/issue/{issueKey}?fields=status,assignee",
      status: verifyRes.status,
      pass: verifyRes.status === 200,
      details: verifyRes.status === 200 ? {
        status: verifyRes.json && verifyRes.json.fields && verifyRes.json.fields.status && verifyRes.json.fields.status.name,
        assignee: verifyRes.json && verifyRes.json.fields && verifyRes.json.fields.assignee && verifyRes.json.fields.assignee.displayName,
        assigneeAccountId: verifyRes.json && verifyRes.json.fields && verifyRes.json.fields.assignee && verifyRes.json.fields.assignee.accountId
      } : briefBody(verifyRes.json)
    };
    if (verifyRes.status !== 200) result.ok = false;
  }

  const assignStatus = result.writes && result.writes.assign && result.writes.assign.status;
  const transitionStatus = result.writes && result.writes.transition && result.writes.transition.status;
  const hardFailStatuses = new Set([401, 403, 404]);
  const hardFail = hardFailStatuses.has(assignStatus) || hardFailStatuses.has(transitionStatus);
  const preflightOk = !!(result.steps.issue_exists.pass && result.steps.transitions_valid.pass && result.steps.assignable_user.pass);
  if (hardFail && executeWrite) {
    result.guidance = {
      manualWebAllowed: true,
      reason: "WRITE_HARD_FAILED",
      evidence: {
        assignStatus: assignStatus || null,
        transitionStatus: transitionStatus || null
      }
    };
    result.capability = {
      writeAccess: "no",
      evidence: {
        assignStatus: assignStatus || null,
        transitionStatus: transitionStatus || null
      }
    };
  } else if (preflightOk) {
    result.guidance = {
      manualWebAllowed: false,
      reason: "API_READY_OR_SUCCEEDED"
    };
    if (executeWrite && result.writes && result.writes.assign && result.writes.assign.status === 204) {
      result.capability = {
        writeAccess: "yes",
        evidence: {
          assignStatus: 204
        }
      };
    }
  } else {
    result.guidance = {
      manualWebAllowed: false,
      reason: "RETRY_API_FLOW_REQUIRED"
    };
  }

  console.log(JSON.stringify(result, null, 2));
  process.exit(result.ok ? 0 : 4);
}

run();
'
