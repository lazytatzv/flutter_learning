const WebSocket = require('ws');
const fs = require('fs');

// WSS 用に Tailscale のドメインを指定
const ws = new WebSocket('ws://58.3.72.136:9090', {
  rejectUnauthorized: false,  // 自己署名証明書を許可
});

ws.on('open', () => {
  console.log('Connected!');
  ws.send(JSON.stringify({
    op: "subscribe",
    topic: "/chatter",
    type: "std_msgs/msg/String"
  }));
});

ws.on('message', (msg) => {
  console.log('Received:', msg.toString());
});

ws.on('error', (err) => {
  console.error('WebSocket error:', err);
});

