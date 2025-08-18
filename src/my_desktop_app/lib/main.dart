import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Linux Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Random _rand = Random();
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _counter = 0;
  int _score = 0; // スコアを記憶
  // simple word list for the typing game
  final List<String> _wordList = [
    'apple', 'banana', 'cherry', 'dog', 'elephant', 'flutter', 'widget', 'state', 'async', 'future',
    'keyboard', 'monitor', 'window', 'linux', 'desktop', 'random', 'function', 'variable'
  ];

  late String _targetWord; // 対象の単語
  String _currentInput = '';

  @override
  void initState() {
    super.initState();
  _targetWord = _wordList[_rand.nextInt(_wordList.length)];
    // Ensure the hidden text field receives keyboard focus after build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
  _focusNode.dispose();
    super.dispose();
  }

  // Check the submitted input as a whole word (case-insensitive)
  void _checkInput(String input) {
    final submitted = input.trim();
    if (submitted.isEmpty) return;
    if (submitted.toLowerCase() == _targetWord.toLowerCase()) {
      setState(() {
        _score++;
        _targetWord = _wordList[_rand.nextInt(_wordList.length)];
        _currentInput = '';
      });
      _ctrl.clear();
      _focusNode.requestFocus();
    }
  }

  void _handleCorrect() {
    setState(() {
      _score++;
      _targetWord = _wordList[_rand.nextInt(_wordList.length)];
      _currentInput = '';
    });
    _ctrl.clear();
    _focusNode.requestFocus();
  }

  void _onInputChanged(String s) {
    setState(() {
      _currentInput = s;
    });
    if (s.trim().isNotEmpty && s.trim().toLowerCase() == _targetWord.toLowerCase()) {
      // auto-advance on full match
      _handleCorrect();
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
  appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Type the word shown:'),
            const SizedBox(height: 8),
            // Show target with real-time match highlighting (larger)
            Builder(builder: (context) {
              final baseStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 64) ?? const TextStyle(fontSize: 64);
              return RichText(
                text: TextSpan(
                  children: _targetWord.split('').asMap().entries.map((e) {
                    final i = e.key;
                    final ch = e.value;
                    final input = _currentInput;
                    TextStyle style = baseStyle;
                    if (i < input.length) {
                      final inCh = input[i];
                      if (inCh.toLowerCase() == ch.toLowerCase()) {
                        style = style.copyWith(color: Colors.green);
                      } else {
                        style = style.copyWith(color: Colors.red);
                      }
                    }
                    return TextSpan(text: ch, style: style);
                  }).toList(),
                ),
                textAlign: TextAlign.center,
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Center(
                child: SizedBox(
                  width: 900, // keep a readable width on desktop (larger)
                  child: Opacity(
                    opacity: 0.0,
                    child: SizedBox(
                      width: 1,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        onSubmitted: _checkInput,
                        onChanged: _onInputChanged,
                        autofocus: true,
                        textCapitalization: TextCapitalization.none,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(fontSize: 18, color: Colors.transparent),
                        cursorColor: Colors.blue,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterText: '', // hide length counter
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // current input is shown inside the TextField via its controller
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28),
            ),
          ],
        ),
      ),
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
