const ws = new WebSocket("ws://100.109.100.122:9090");

ws.onopen = () => {
  console.log("Connected!");
  ws.send(JSON.stringify({
    op: "subscribe",
    topic: "/chatter",
    type: "std_msgs/msg/String"
  }));
};

ws.onmessage = (msg) => {
  console.log("Received:", msg.data);
};

