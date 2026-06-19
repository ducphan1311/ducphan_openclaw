# Figma MCP / Plugin Write SOP

Use this when the task requires programmatic writes to a live Figma file.

## Safety rules

- Confirm the intended Figma file key and visible file name before writing.
- Never rely on an old `FIGMA_FILE_KEY` env var when the user provides a link; parse/use the link key.
- Preserve the user's requested channel name if provided; for AIMess use `aimess-production` unless told otherwise.
- Do not mutate existing production pages until a small safe write test passes.
- First write should be harmless and reversible: create a new clearly-named test frame/page or a frame on a scratch page.
- Do not print or read secret tokens. Presence checks are OK.
- If using browser automation, read before clicking. Do not choose ambiguous recent files blindly.
- If plugin/UI is not connected, stop and report the exact blocker instead of pretending Figma was updated.

## Preferred stack

Local workspace path:

```text
/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma
```

Known local helper:

```bash
./tools/figma-mcp/start-socket.sh
```

The Talk To Figma MCP flow has three moving parts:

1. WebSocket relay on port `3055`.
2. Figma plugin `Talk To Figma MCP Plugin`, run inside the target Figma file.
3. MCP client/server tools, joined to the same channel.

## Setup / verification sequence

1. Start or verify the WebSocket relay:

```bash
./tools/figma-mcp/start-socket.sh
```

Expected log:

```text
WebSocket server running on port 3055
```

2. Open the exact Figma URL supplied by the user. Verify:

- browser title/file name matches expected file
- URL file key matches expected key
- editing tools are enabled, not View only/Locked

3. Run/install the plugin:

- Community plugin: `https://www.figma.com/community/plugin/1485687494525374295`
- Or local development plugin: Figma `Plugins > Development > New Plugin > Link existing plugin`, choose:

```text
tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/manifest.json
```

4. In the plugin UI, join the requested channel, e.g.:

```text
aimess-production
```

5. Verify the socket log shows two peers in the same channel when both plugin and MCP client are connected.

6. Run MCP tool `join_channel` with the same channel.

7. Test read first:

- `get_document_info`
- `get_selection` or `read_my_design`

8. Test small write:

- Create a frame named like `MCP Write Test - <date>` at a safe off-canvas position or on a scratch page.
- Add small text: `MCP write connected`.
- Report node IDs and location.

9. Only after step 8 succeeds, batch-create production design frames.

## Browser recovery notes

- Use the OpenClaw browser skill operating loop: `tabs` → open/reuse labeled tab → `snapshot refs=aria` → narrow `act`.
- For Figma menu/plugin flows, snapshots often expose `Main menu`, `Plugins`, `Preferences`, and plugin search, but not all canvas controls.
- If multiple recent files have the same name, do not select by name alone; navigate directly to the exact file URL.

## Common blockers

- **View only / Locked / Ask to edit**: the browser account cannot write to the file.
- **Plugin not in menu**: install community plugin or link local manifest from Figma desktop/dev menu.
- **Only one socket peer**: plugin or MCP client is not joined to the channel.
- **No Bun in PATH**: use helper that exports `$HOME/.bun/bin`, or install Bun only with explicit approval if absent.
- **Figma API token works but cannot write**: REST API is mostly read-oriented for files; use plugin/MCP for live canvas writes.

## Completion evidence

A successful MCP write setup must include:

- exact file key and file name
- channel name
- socket relay status
- successful read result
- successful write result with created node/frame name
- note that the write was limited to a safe test object unless user approved broader writes
