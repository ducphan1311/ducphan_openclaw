#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const root = path.resolve(__dirname, "..");
const dataDir = path.join(root, "data");
const taskDir = path.join(dataDir, "tasks");
const approvalDir = path.join(dataDir, "approvals");
const tasksJsonl = path.join(taskDir, "tasks.jsonl");
const approvalsJsonl = path.join(approvalDir, "approvals.jsonl");
const stateJson = path.join(taskDir, "state.json");
const approvalStateJson = path.join(approvalDir, "state.json");

function ensureDirs() {
  fs.mkdirSync(taskDir, { recursive: true });
  fs.mkdirSync(approvalDir, { recursive: true });
}

function now() {
  return new Date().toISOString();
}

function id(prefix) {
  const stamp = new Date().toISOString().replace(/[-:.TZ]/g, "").slice(0, 14);
  return `${prefix}_${stamp}_${crypto.randomBytes(4).toString("hex")}`;
}

function readJson(file, fallback) {
  if (!fs.existsSync(file)) return fallback;
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file, value) {
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function appendJsonl(file, value) {
  fs.appendFileSync(file, `${JSON.stringify(value)}\n`);
}

function loadState() {
  ensureDirs();
  return readJson(stateJson, { version: 1, tasks: {} });
}

function saveState(state) {
  writeJson(stateJson, state);
}

function loadApprovalState() {
  ensureDirs();
  return readJson(approvalStateJson, { version: 1, approvals: {} });
}

function saveApprovalState(state) {
  writeJson(approvalStateJson, state);
}

function createTask(args) {
  const state = loadState();
  const taskId = args.taskId || id("task");
  const task = {
    task_id: taskId,
    requester: args.requester || "unknown",
    source: args.source || "manual",
    status: "queued",
    goal: args.goal,
    priority: args.priority || "normal",
    created_at: now(),
    updated_at: now(),
    steps: args.steps || [],
    approvals: [],
    audit_targets: args.auditTargets || [],
    metadata: args.metadata || {}
  };
  state.tasks[taskId] = task;
  saveState(state);
  appendJsonl(tasksJsonl, { event: "task_created", at: now(), task });
  return task;
}

function updateTask(args) {
  const state = loadState();
  const task = state.tasks[args.taskId];
  if (!task) throw new Error(`Task not found: ${args.taskId}`);
  Object.assign(task, args.patch || {});
  task.updated_at = now();
  state.tasks[args.taskId] = task;
  saveState(state);
  appendJsonl(tasksJsonl, { event: "task_updated", at: now(), task_id: args.taskId, patch: args.patch || {} });
  return task;
}

function addStep(args) {
  const state = loadState();
  const task = state.tasks[args.taskId];
  if (!task) throw new Error(`Task not found: ${args.taskId}`);
  const step = {
    id: args.stepId || id("step"),
    worker: args.worker,
    status: args.status || "queued",
    instruction: args.instruction,
    created_at: now(),
    updated_at: now(),
    result: null,
    error: null
  };
  task.steps.push(step);
  task.updated_at = now();
  saveState(state);
  appendJsonl(tasksJsonl, { event: "step_added", at: now(), task_id: args.taskId, step });
  return step;
}

function updateStep(args) {
  const state = loadState();
  const task = state.tasks[args.taskId];
  if (!task) throw new Error(`Task not found: ${args.taskId}`);
  const step = task.steps.find((item) => item.id === args.stepId);
  if (!step) throw new Error(`Step not found: ${args.stepId}`);
  Object.assign(step, args.patch || {});
  step.updated_at = now();
  task.updated_at = now();
  saveState(state);
  appendJsonl(tasksJsonl, { event: "step_updated", at: now(), task_id: args.taskId, step_id: args.stepId, patch: args.patch || {} });
  return step;
}

function requestApproval(args) {
  const approvals = loadApprovalState();
  const tasks = loadState();
  const approvalId = args.approvalId || id("approval");
  const record = {
    approval_id: approvalId,
    task_id: args.taskId,
    requester: args.requester || "unknown",
    action: args.action,
    risk: args.risk || "high",
    status: "pending",
    required_role: args.requiredRole || "owner_or_admin",
    details: args.details || {},
    created_at: now(),
    updated_at: now(),
    decided_by: null,
    decided_at: null,
    decision_note: null
  };
  approvals.approvals[approvalId] = record;
  saveApprovalState(approvals);
  appendJsonl(approvalsJsonl, { event: "approval_requested", at: now(), approval: record });

  if (args.taskId && tasks.tasks[args.taskId]) {
    tasks.tasks[args.taskId].approvals.push(approvalId);
    tasks.tasks[args.taskId].updated_at = now();
    saveState(tasks);
  }
  return record;
}

function decideApproval(args) {
  const state = loadApprovalState();
  const approval = state.approvals[args.approvalId];
  if (!approval) throw new Error(`Approval not found: ${args.approvalId}`);
  if (!["approved", "rejected"].includes(args.decision)) {
    throw new Error("Decision must be approved or rejected");
  }
  approval.status = args.decision;
  approval.decided_by = args.decidedBy || "unknown";
  approval.decided_at = now();
  approval.updated_at = now();
  approval.decision_note = args.note || null;
  saveApprovalState(state);
  appendJsonl(approvalsJsonl, { event: "approval_decided", at: now(), approval_id: args.approvalId, decision: args.decision, decided_by: approval.decided_by });
  return approval;
}

function listTasks() {
  return Object.values(loadState().tasks).sort((a, b) => a.created_at.localeCompare(b.created_at));
}

function listApprovals() {
  return Object.values(loadApprovalState().approvals).sort((a, b) => a.created_at.localeCompare(b.created_at));
}

function print(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

function parseJsonArg(raw, fallback = {}) {
  if (!raw) return fallback;
  return JSON.parse(raw);
}

function usage() {
  console.error(`Usage:
  node scripts/task_registry.js create-task '<json>'
  node scripts/task_registry.js update-task <task_id> '<json_patch>'
  node scripts/task_registry.js add-step <task_id> '<json>'
  node scripts/task_registry.js update-step <task_id> <step_id> '<json_patch>'
  node scripts/task_registry.js request-approval '<json>'
  node scripts/task_registry.js decide-approval <approval_id> approved|rejected '<json>'
  node scripts/task_registry.js list-tasks
  node scripts/task_registry.js list-approvals`);
  process.exit(2);
}

function main(argv) {
  ensureDirs();
  const cmd = argv[2];
  try {
    if (cmd === "create-task") return print(createTask(parseJsonArg(argv[3])));
    if (cmd === "update-task") return print(updateTask({ taskId: argv[3], patch: parseJsonArg(argv[4]) }));
    if (cmd === "add-step") return print(addStep({ taskId: argv[3], ...parseJsonArg(argv[4]) }));
    if (cmd === "update-step") return print(updateStep({ taskId: argv[3], stepId: argv[4], patch: parseJsonArg(argv[5]) }));
    if (cmd === "request-approval") return print(requestApproval(parseJsonArg(argv[3])));
    if (cmd === "decide-approval") return print(decideApproval({ approvalId: argv[3], decision: argv[4], ...parseJsonArg(argv[5]) }));
    if (cmd === "list-tasks") return print(listTasks());
    if (cmd === "list-approvals") return print(listApprovals());
    usage();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

if (require.main === module) main(process.argv);

module.exports = {
  createTask,
  updateTask,
  addStep,
  updateStep,
  requestApproval,
  decideApproval,
  listTasks,
  listApprovals
};

