const WebSocket = require('./openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma/node_modules/ws');
const crypto = require('crypto');
const channel = process.argv[2] || 'aimess-production';
const command = process.argv[3] || 'get_document_info';
const params = process.argv[4] ? JSON.parse(process.argv[4]) : {};
const id = crypto.randomUUID();
const ws = new WebSocket('ws://localhost:3055');
const timeout = setTimeout(()=>{ console.error('TIMEOUT'); ws.close(); process.exit(2); }, 20000);
ws.on('open', () => {
  ws.send(JSON.stringify({id: crypto.randomUUID(), type:'join', channel}));
  setTimeout(()=>{
    ws.send(JSON.stringify({
      id,
      type:'message',
      channel,
      message:{ id, command, params:{...params, commandId:id} }
    }));
  }, 500);
});
ws.on('message', raw => {
  const data = JSON.parse(String(raw));
  if (data.type === 'broadcast' && data.message && data.message.id === id) {
    clearTimeout(timeout);
    console.log(JSON.stringify(data.message, null, 2));
    ws.close();
  } else if (data.message && data.message.id === id && data.message.result) {
    clearTimeout(timeout);
    console.log(JSON.stringify(data.message, null, 2));
    ws.close();
  }
});
ws.on('error', e => { clearTimeout(timeout); console.error(e); process.exit(1); });
