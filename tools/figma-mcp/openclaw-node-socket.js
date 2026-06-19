#!/usr/bin/env node
const WebSocket = require('./talk-to-figma/node_modules/ws');
const port = Number(process.env.FIGMA_MCP_PORT || 3055);
const channels = new Map();
const wss = new WebSocket.Server({ port });
function send(ws, obj) { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj)); }
wss.on('connection', (ws) => {
  console.log('New client connected');
  send(ws, { type: 'system', message: 'Please join a channel to start chatting' });
  ws.on('message', (raw) => {
    let data;
    try { data = JSON.parse(String(raw)); } catch (e) { send(ws, { type: 'error', message: 'Invalid JSON' }); return; }
    console.log(`\n=== Received message from client ===`);
    console.log(`Type: ${data.type}, Channel: ${data.channel || 'N/A'}`);
    if (data.message?.command) console.log(`Command: ${data.message.command}, ID: ${data.id}`);
    console.log('Full message:', JSON.stringify(data, null, 2));
    if (data.type === 'join') {
      const channel = data.channel;
      if (!channel || typeof channel !== 'string') { send(ws, { type: 'error', message: 'Channel name is required' }); return; }
      if (!channels.has(channel)) channels.set(channel, new Set());
      channels.get(channel).add(ws); ws.channel = channel;
      console.log(`\n✓ Client joined channel "${channel}" (${channels.get(channel).size} total clients)`);
      send(ws, { type: 'system', message: `Joined channel: ${channel}`, channel });
      send(ws, { type: 'system', message: { id: data.id, result: `Connected to channel: ${channel}` }, channel });
      for (const client of channels.get(channel)) if (client !== ws) send(client, { type: 'system', message: 'A new user has joined the channel', channel });
      return;
    }
    if (data.type === 'message' || data.type === 'progress_update') {
      const channel = data.channel;
      const clients = channels.get(channel);
      if (!clients || !clients.has(ws)) { send(ws, { type: 'error', message: 'You must join the channel first' }); return; }
      let count = 0;
      for (const client of clients) if (client !== ws && client.readyState === WebSocket.OPEN) {
        count++;
        if (data.type === 'message') send(client, { type: 'broadcast', message: data.message, sender: 'peer', channel });
        else send(client, data);
      }
      if (!count) console.log(`⚠️  No other clients in channel "${channel}" to receive message!`);
      else console.log(`✓ Broadcast to ${count} peer(s) in channel "${channel}"`);
    }
  });
  ws.on('close', () => {
    for (const [channel, clients] of channels) if (clients.delete(ws)) {
      for (const client of clients) send(client, { type: 'system', message: 'A user has left the channel', channel });
    }
    console.log('Client disconnected');
  });
});
console.log(`OpenClaw Node WebSocket server running on port ${port}`);
