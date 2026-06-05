# AIMess Figma MCP Write Bridge

This workspace uses `cursor-talk-to-figma-mcp` because it supports write operations through a Figma plugin bridge:

- `create_frame`
- `create_text`
- `create_rectangle`
- `create_component` / `create_component_set` (local OpenClaw extension)
- `get_bounding_boxes` / `detect_overlaps` (local OpenClaw extension for visual QA)
- styling/layout tools
- selection/document inspection

## Installed paths

- Repo: `tools/figma-mcp/talk-to-figma`
- MCP server source: `tools/figma-mcp/talk-to-figma/src/talk_to_figma_mcp/server.ts`
- MCP server build used locally: `tools/figma-mcp/package/dist/server.cjs` and `tools/figma-mcp/talk-to-figma/dist/server.cjs`
- Figma plugin source: `tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/code.js`
- Figma plugin manifest: `tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/manifest.json`
- WebSocket server: `tools/figma-mcp/talk-to-figma/src/socket.ts`

## Start bridge

```bash
cd /Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma
export PATH="$HOME/.bun/bin:$PATH"
bun socket
```

The server listens on `ws://localhost:3055`.

## Figma plugin setup (one-time manual step)

Figma requires a plugin UI to run inside the open file for write access. REST API alone cannot create frames/pages.

1. Open Figma desktop/web file: `AiMess - App`.
2. Go to `Plugins` → `Development` → `New Plugin...`.
3. Choose `Link existing plugin`.
4. Select:

```text
/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/manifest.json
```

5. Run the plugin in the `AiMess - App` file.
6. In plugin UI, connect/join a channel. Use channel name:

```text
aimess-production
```

## MCP client config

For clients that read `.mcp.json`, use:

```json
{
  "mcpServers": {
    "TalkToFigma": {
      "command": "bunx",
      "args": ["cursor-talk-to-figma-mcp@0.3.5"]
    }
  }
}
```

OpenClaw may require registering this under `mcp.servers` and restarting/reloading Gateway before the MCP tools appear in an agent tool list.

## Check current tool list

```bash
node - <<'NODE'
const fs=require('fs');
const p='tools/figma-mcp/package/dist/server.cjs';
const s=fs.readFileSync(p,'utf8');
const tools=[...s.matchAll(/server\\.tool\\(\\s*["']([^"']+)["']/g)].map(m=>m[1]);
console.log({path:p, toolCount:tools.length, tools});
NODE
```

Expected local count after OpenClaw extensions: **44 tools**.

## Local extra tools added by OpenClaw

- `create_component` — create a real native Figma `COMPONENT` node.
- `create_component_set` — combine existing components into a native component set / variants.
- `get_bounding_boxes` — return absolute node boxes for visual QA.
- `detect_overlaps` — detect rectangular overlaps between nodes.

After changing MCP/plugin code:

1. Rebuild MCP server:
   ```bash
   cd tools/figma-mcp/talk-to-figma
   ./node_modules/.bin/tsup src/talk_to_figma_mcp/server.ts --format esm,cjs --dts --out-dir dist
   cp dist/server.* ../package/dist/
   ```
2. Reload/restart the MCP server process used by OpenClaw.
3. Re-run/reload the local Figma development plugin from the manifest path above so plugin-side commands match server-side tools.

## Safety

- Use a dedicated channel: `aimess-production`.
- Create a new page/frame area only: `AIMess Production Handoff v1`.
- Do not mutate existing `🎉 [FINAL] APP` frames without explicit approval.
