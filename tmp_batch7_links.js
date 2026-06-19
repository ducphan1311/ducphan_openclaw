const WebSocket = require('./openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma/node_modules/ws');
const crypto = require('crypto');
const channel = process.argv[2] || 'aimess-production';
const port = process.env.FIGMA_MCP_PORT || 3055;
const links = [
  ['01 Home → Chat', '142:268', '142:274'],
  ['02 Chat → Message Actions', '142:278', '142:284'],
  ['03 Actions → Reply', '142:288', '142:294'],
  ['04 Reply → Chat', '142:298', '142:274'],
  ['05 Chat → Send Error', '142:281', '135:623'],
  ['06 Actions → Permission', '142:291', '142:301'],
  ['07 Permission → Moderation', '142:305', '135:653'],
  ['08 Home → Live', '142:271', '135:425'],
  ['09 Profile → Notifications', '142:312', '135:711'],
  ['10 Notifications → Profile', '142:319', '142:308'],
];
function rpc(ws, command, params, timeoutMs = 20000) {
  const id = crypto.randomUUID();
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`TIMEOUT ${command} ${id}`)), timeoutMs);
    function onMessage(raw) {
      let data;
      try { data = JSON.parse(String(raw)); } catch { return; }
      const msg = data.type === 'broadcast' ? data.message : data.message;
      if (!msg || msg.id !== id) return;
      clearTimeout(timer);
      ws.off('message', onMessage);
      if (msg.error) reject(new Error(msg.error)); else resolve(msg.result);
    }
    ws.on('message', onMessage);
    ws.send(JSON.stringify({ id, type: 'message', channel, message: { id, command, params: { ...params, commandId: id } } }));
  });
}
(async () => {
  const ws = new WebSocket(`ws://localhost:${port}`);
  await new Promise((resolve, reject) => { ws.once('open', resolve); ws.once('error', reject); });
  ws.send(JSON.stringify({ id: crypto.randomUUID(), type: 'join', channel }));
  await new Promise(r => setTimeout(r, 500));
  const results = [];
  for (const [label, sourceNodeId, destinationId] of links) {
    const result = await rpc(ws, 'create_prototype_link', { sourceNodeId, destinationId, trigger: 'ON_CLICK', navigation: 'NAVIGATE', transition: 'INSTANT', preserveExisting: false });
    results.push({ label, sourceNodeId, destinationId, reactions: result.reactions });
    console.log(`OK ${label}: ${sourceNodeId} -> ${destinationId}`);
  }
  ws.close();
  console.log(JSON.stringify({ ok: true, count: results.length, results }, null, 2));
})().catch(err => { console.error(err.stack || err.message); process.exit(1); });
