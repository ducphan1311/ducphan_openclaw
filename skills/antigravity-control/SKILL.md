---
name: antigravity-control
description: Open and hand off local projects, folders, or files to Google Antigravity from OpenClaw. Use when Danny asks OpenClaw to use Antigravity as a coding arm, open Antigravity, hand off a repo/file, or continue work inside Antigravity.
---

# Antigravity Control

Use this skill when the user wants OpenClaw to operate Google Antigravity as an external coding/IDE arm.

## Capabilities

- Launch `/Applications/Antigravity.app`.
- Open a local folder/file in Antigravity with macOS `open -a`.
- Use the registered `antigravity://` URL scheme for future deep-link experiments.
- Detect Antigravity local automation surfaces:
  - Electron Chrome DevTools Protocol (CDP) remote debugging on a dynamic localhost port owned by the main Antigravity process.
  - Antigravity web UI served by the bundled language server, usually `https://127.0.0.1:<dynamic-port>/`.
  - Static/support HTTP server, usually a neighboring dynamic port.
- Prepare concise handoff prompts for the user to paste into Antigravity when direct agent-to-agent APIs are unavailable.

## Commands

```bash
# Open app
scripts/antigravity_open.sh

# Open a repo/folder/file
scripts/antigravity_open.sh /absolute/path/to/project
```

## Safe workflow

1. Check the target path exists.
2. Launch Antigravity with `scripts/antigravity_open.sh <path>`.
3. If the task needs Antigravity agent action, produce a short handoff prompt with:
   - repo path
   - goal
   - files touched/needed
   - constraints
   - desired verification command
4. Do not assume Antigravity has completed work unless its output/files are inspected from OpenClaw.

## Automation Interface Findings

Observed on Danny's Mac for Antigravity 2.1.4:

- Main app process can expose Chrome DevTools Protocol (CDP):
  - Example discovered port: `127.0.0.1:50152`
  - `GET /json/version` returns `Browser: Chrome/146... Antigravity/2.1.4 Electron/41.0.2`
  - `GET /json/list` shows a page titled `Antigravity` with URL like `https://127.0.0.1:50153/`
  - This can potentially drive the UI using CDP/WebSocket automation, similar to browser automation.
- Bundled language server process:
  - Binary: `/Applications/Antigravity.app/Contents/Resources/bin/language_server`
  - Launch args observed include `--standalone`, `--override_ide_name antigravity`, `--https_server_port 0`, `--csrf_token <runtime-token>`, `--app_data_dir antigravity`, `--api_server_url https://generativelanguage.googleapis.com`, `--cloud_code_endpoint https://daily-cloudcode-pa.googleapis.com`, `--enable_sidecars`.
  - Example app UI HTTPS port: `127.0.0.1:50153`.
  - Example static/support HTTP port: `127.0.0.1:50154`.
- Extracted/probed app bundle shows protobuf/gRPC-like method names including:
  - `GetAuthStatus`, `LoginWithBrowser`, `AuthLogout`, `HasAuthToken`
  - `GetAvailableModels`, `RetrieveUserQuotaSummary`, `GetLoadCodeAssist`
  - `CreateProject`, `UpdateProject`, `DeleteProject`, `ReadProject`, `ValidateProject`, `ResolveFolder`
  - `SearchFiles`, `SearchCode`, `SearchConversations`
  - `SendAgentMessage`, `DeleteAgentMessage`
  - `ProjectUpdatesStream`, `SetupJetskiChat`
- Plain REST paths like `/api`, `/rpc`, `/v1`, `/exa.GetUserStatus` return the SPA HTML, so direct API path shape is not confirmed yet. Likely uses generated protobuf/gRPC/connect-web client from the web UI.

## Notes

- Current Antigravity app version detected on Danny's Mac: 2.1.4.
- The app registers URL scheme `antigravity://`.
- No stable public CLI for direct headless task execution was found in the app bundle yet.
- Best current integration path:
  1. use `open -a Antigravity <path>` for repo/file launch,
  2. use CDP to inspect/drive the Antigravity UI,
  3. reverse the generated web client enough to call methods like `RetrieveUserQuotaSummary` or `SendAgentMessage` safely.
