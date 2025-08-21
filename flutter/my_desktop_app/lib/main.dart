import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  WebSocket? _ws;
  bool _joyAdvertised = false;

  @override
  void initState() {
    super.initState();
    _connectToRos();
  }

  void _connectToRos() async {
    try {
      // WSS でポート443に接続（Nginx経由）
      _ws = await WebSocket.connect('ws://100.109.100.122:9090');
      
      // /chatter トピックにサブスクライブ
      _ws?.add(jsonEncode({
        "op": "subscribe",
        "topic": "/chatter",
        "type": "std_msgs/msg/String"
      }));

      // Advertise /joy so rosbridge can infer the type before publish
      _ws?.add(jsonEncode({
        'op': 'advertise',
        'topic': '/joy',
        'type': 'sensor_msgs/msg/Joy',
      }));
      Future.delayed(const Duration(milliseconds: 200), () {
        _joyAdvertised = true;
      });

      _ws?.listen((data) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map && parsed['msg'] is Map && parsed['msg']['data'] is String) {
            setState(() {
              _rosMessage = parsed['msg']['data'] as String;
            });
          }
        } catch (e) {
          print('Invalid message: $e');
        }
      });
    } catch (e) {
      print('WebSocket error: $e');
    }
  }

  Future<void> _sendJoyMessage(RawKeyEvent event) async {
    if (_ws == null) return;

    final Map<String, dynamic> joyMsg = {
      'op': 'publish',
      'topic': '/joy',
      'msg': {
        'axes': [0.0, 0.0, 0.0, 0.0, 0.0],
        // sensor_msgs/msg/Joy の buttons は整数配列なので int にする
        'buttons': [0, 0, 0, 0, 0, 0, 0, 0],
      }
    };

    // If not advertised (e.g. on fresh connection), advertise now and wait briefly
    if (!_joyAdvertised) {
      _ws?.add(jsonEncode({
        'op': 'advertise',
        'topic': '/joy',
        'type': 'sensor_msgs/msg/Joy',
      }));
      await Future.delayed(const Duration(milliseconds: 200));
      _joyAdvertised = true;
    }

    switch (event.logicalKey.keyLabel.toLowerCase()) {
      case 'a':
        (joyMsg['msg'] as Map<String, dynamic>)['axes'][0] = 1.0;
        break;
      case 'd':
        (joyMsg['msg'] as Map<String, dynamic>)['axes'][0] = -1.0;
        break;
      case 'w':
        (joyMsg['msg'] as Map<String, dynamic>)['axes'][1] = 1.0;
        break;
      case 's':
        (joyMsg['msg'] as Map<String, dynamic>)['axes'][1] = -1.0;
        break;
      default:
        return;
    }

    _ws!.add(jsonEncode(joyMsg));
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: _sendJoyMessage,
      child: Scaffold(
        appBar: AppBar(title: const Text('ROS2 Flutter Demo')),
        body: Center(
          child: Text(
            _rosMessage,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
