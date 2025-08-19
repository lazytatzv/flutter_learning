import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  // 自己署名証明書でも接続できるようにオーバーライド
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROS2 Flutter Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _rosMessage = 'No data';

  @override
  void initState() {
    super.initState();
    _connectToRos();
  }

  void _connectToRos() async {
    try {
      // WSS でポート443に接続（Nginx経由）
      final ws = await WebSocket.connect('ws://100.109.100.122:9090');
      
      // /chatter トピックにサブスクライブ
      ws.add(jsonEncode({
        "op": "subscribe",
        "topic": "/chatter",
        "type": "std_msgs/msg/String"
      }));

      ws.listen((data) {
        final msg = jsonDecode(data);
        setState(() {
          _rosMessage = msg['msg']?['data'] ?? 'No data';
        });
      });
    } catch (e) {
      print('WebSocket error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROS2 Flutter Demo')),
      body: Center(
        child: Text(
          _rosMessage,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
