# Figma MCP Write Bridge

Visible, versionable local setup for the Figma MCP bridge used by OpenClaw.

This folder is intentionally kept at:

```text
openclaw_manager/tools/figma-mcp
```

instead of inside `openclaw_data/.openclaw/workspace/...` so it is easy to inspect, edit, and commit to GitHub.

---

## 1. How the bridge works

There are **three layers**:

```text
AI / MCP client
   ↓ calls MCP tools
MCP server: server.ts / dist/server.cjs
   ↓ sends command over WebSocket
Socket bridge: src/socket.ts or openclaw-node-socket.js
   ↓ forwards command to Figma plugin UI
Figma plugin: src/cursor_mcp_plugin/code.js
   ↓ calls Figma Plugin API
Figma file
```

Important: adding a tool usually requires changes in **both**:

1. MCP server-side tool definition
2. Figma plugin-side command handler

If you only add the server-side tool, the tool may appear in the MCP client but fail with:

```text
Unknown command: your_tool_name
```

---

## 2. Important paths

All paths below are relative to repo root:

```text
openclaw_manager/
```

### Easy-to-see copy

```text
tools/figma-mcp
```

### MCP server source — tool definitions live here

```text
tools/figma-mcp/talk-to-figma/src/talk_to_figma_mcp/server.ts
```

This is where MCP tools are registered with:

```ts
server.tool("tool_name", "description", schema, async (params) => { ... })
```

### Built MCP server files — clients usually run these

```text
tools/figma-mcp/talk-to-figma/dist/server.cjs
tools/figma-mcp/talk-to-figma/dist/server.js
tools/figma-mcp/package/dist/server.cjs
tools/figma-mcp/package/dist/server.js
```

The local `package/dist` copy exists because older/local OpenClaw scripts previously inspected/used this package copy.

### Figma plugin command handler — actual Figma API commands live here

```text
tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/code.js
```

Look for:

```js
async function handleCommand(command, params) {
  switch (command) {
    case "create_frame":
      return await createFrame(params);
  }
}
```

Each real Figma write operation needs a `case` here plus an implementation function.

### Figma plugin manifest — import this in Figma

```text
tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/manifest.json
```

### WebSocket server

```text
tools/figma-mcp/talk-to-figma/src/socket.ts
tools/figma-mcp/openclaw-node-socket.js
```

---

## 3. How I know how many MCP tools exist

MCP tools are registered in the built server file as calls to:

```js
server.tool("tool_name", ...)
```

So the current tool count can be checked by scanning `server.cjs`.

Run from repo root:

```bash
node - <<'NODE'
const fs = require('fs');
const p = 'tools/figma-mcp/package/dist/server.cjs';
const s = fs.readFileSync(p, 'utf8');
const tools = [...s.matchAll(/server\.tool\(\s*["']([^"']+)["']/g)].map(m => m[1]);
console.log('Path:', p);
console.log('Tool count:', tools.length);
console.log(tools.join('\n'));
NODE
```

Expected after local OpenClaw extensions:

```text
Tool count: 44
```

To check both built copies:

```bash
node - <<'NODE'
const fs = require('fs');
for (const p of [
  'tools/figma-mcp/talk-to-figma/dist/server.cjs',
  'tools/figma-mcp/package/dist/server.cjs'
]) {
  const s = fs.readFileSync(p, 'utf8');
  const tools = [...s.matchAll(/server\.tool\(\s*["']([^"']+)["']/g)].map(m => m[1]);
  console.log('\n' + p);
  console.log('Tool count:', tools.length);
  console.log(tools.join('\n'));
}
NODE
```

---

## 4. Current local tool list

Current expected count: **44 tools**.

Core tools from upstream plus local extensions:

```text
get_document_info
get_selection
read_my_design
get_node_info
get_nodes_info
create_rectangle
create_frame
create_text
set_fill_color
set_stroke_color
move_node
clone_node
resize_node
delete_node
delete_multiple_nodes
export_node_as_image
set_text_content
get_styles
get_local_components
get_annotations
set_annotation
set_multiple_annotations
create_component
create_component_set
get_bounding_boxes
detect_overlaps
create_component_instance
get_instance_overrides
set_instance_overrides
set_corner_radius
scan_text_nodes
scan_nodes_by_types
set_multiple_text_contents
set_layout_mode
set_padding
set_axis_align
set_layout_sizing
set_item_spacing
get_reactions
set_default_connector
create_connections
set_focus
set_selections
join_channel
```

### Local tools added by OpenClaw

```text
create_component
create_component_set
get_bounding_boxes
detect_overlaps
```

What they do:

- `create_component` — creates a native Figma `COMPONENT` node using `figma.createComponent()`.
- `create_component_set` — combines existing components into native variants using `figma.combineAsVariants(...)`.
- `get_bounding_boxes` — returns absolute node boxes for visual QA.
- `detect_overlaps` — detects rectangular overlaps between nodes.

---

## 5. Setup / run bridge

### 5.1 Start the socket bridge

From repo root:

```bash
cd tools/figma-mcp/talk-to-figma
export PATH="$HOME/.bun/bin:$PATH"
bun socket
```

The server listens on:

```text
ws://localhost:3055
```

Alternative OpenClaw socket wrapper:

```bash
node tools/figma-mcp/openclaw-node-socket.js
```

### 5.2 Load plugin in Figma

Figma needs the plugin UI running inside the open file for write access.

In Figma:

```text
Plugins → Development → Import plugin from manifest...
```

Select:

```text
tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/manifest.json
```

Then run the plugin in the target file and join/connect to a channel.

Recommended channel:

```text
aimess-production
```

### 5.3 MCP client config example

For clients that read `.mcp.json`:

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

For local development, prefer pointing the MCP client to the local built server rather than `bunx ...@latest`, otherwise your local tools may not appear.

Example local command pattern:

```json
{
  "mcpServers": {
    "TalkToFigmaLocal": {
      "command": "node",
      "args": ["/absolute/path/to/openclaw_manager/tools/figma-mcp/package/dist/server.cjs"]
    }
  }
}
```

OpenClaw may require registering this under its MCP server config and reloading/restarting Gateway before new tools appear in an agent tool list.

---

## 6. How to add a new tool

Example tool name:

```text
create_page
```

### Step 1 — Add MCP server tool definition

Edit:

```text
tools/figma-mcp/talk-to-figma/src/talk_to_figma_mcp/server.ts
```

Add a `server.tool(...)` block:

```ts
server.tool(
  "create_page",
  "Create a new Figma page",
  {
    name: z.string().describe("New page name")
  },
  async (params: any) => {
    try {
      const result = await sendCommandToFigma("create_page", params);
      return { content: [{ type: "text", text: JSON.stringify(result) }] };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `Error creating page: ${error instanceof Error ? error.message : String(error)}`
        }]
      };
    }
  }
);
```

Also add the command name to the `FigmaCommand` union:

```ts
| "create_page"
```

And add parameter typing in `CommandParams`:

```ts
create_page: { name: string };
```

### Step 2 — Add plugin command case

Edit:

```text
tools/figma-mcp/talk-to-figma/src/cursor_mcp_plugin/code.js
```

Inside `handleCommand(command, params)`, add:

```js
case "create_page":
  return await createPage(params);
```

### Step 3 — Add plugin implementation

In the same `code.js`, add:

```js
async function createPage(params) {
  const { name = "New Page" } = params || {};
  const page = figma.createPage();
  page.name = name;
  figma.currentPage = page;
  return {
    id: page.id,
    name: page.name,
    type: page.type,
  };
}
```

### Step 4 — Rebuild MCP server

From repo root:

```bash
cd tools/figma-mcp/talk-to-figma
./node_modules/.bin/tsup src/talk_to_figma_mcp/server.ts --format esm,cjs --dts --out-dir dist
cp dist/server.* ../package/dist/
```

### Step 5 — Reload runtime pieces

1. Restart/reload the MCP server process used by OpenClaw or your MCP client.
2. In Figma, re-run/reload the local development plugin from the manifest path.
3. Reconnect/join the channel.

### Step 6 — Verify the tool appears

From repo root:

```bash
node - <<'NODE'
const fs = require('fs');
const p = 'tools/figma-mcp/package/dist/server.cjs';
const s = fs.readFileSync(p, 'utf8');
const tools = [...s.matchAll(/server\.tool\(\s*["']([^"']+)["']/g)].map(m => m[1]);
console.log('Tool count:', tools.length);
console.log('Has create_page:', tools.includes('create_page'));
NODE
```

---

## 7. Development rules

- Keep tool names snake_case.
- Add tools in both `server.ts` and plugin `code.js`.
- Use Zod schemas in `server.ts` to document parameters clearly.
- Return compact JSON from plugin functions.
- Avoid adding secrets or tokens to this folder.
- Do not commit `node_modules`, `.git`, `.DS_Store`, or packaged archives unless intentionally needed.
- Prefer local MCP config pointing to `tools/figma-mcp/package/dist/server.cjs` while developing; avoid `@latest` because it bypasses local changes.

---

## 8. Safety

- Use a dedicated channel: `aimess-production`.
- Create new pages/frames for generated work unless explicitly editing an existing production frame.
- Do not mutate existing final app frames without explicit approval.
- For destructive tools like delete/move/bulk override, inspect selection/node IDs first.
