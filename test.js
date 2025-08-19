const WebSocket = require('ws');
const fs = require('fs');

const ws = new WebSocket('wss://100.109.100.122:443', {
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

