import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_long_press_gesture_recognizer/multi_long_press_gesture_recognizer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter MLP Demo",
      theme: ThemeData(),
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
  String? _lastState;
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        MultiLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            MultiLongPressGestureRecognizer>(
          () => MultiLongPressGestureRecognizer(
            duration: const Duration(milliseconds: 500),
            preAcceptSlopTolerance: 18.0,
            pointerThreshold: 2,
          ),
          (instance) {
            instance
              ..onMultiLongPressDown = (details) {
                setState(() {
                  _lastState = "Down";
                });
              }
              ..onMultiLongPress = (details) {
                HapticFeedback.vibrate();
                _lastState = "Press";
                _incrementCounter();
              }
              ..onMultiLongPressCancel = () {
                setState(() {
                  _lastState = "Cancel";
                });
              }
              ..onMultiLongPressMoveUpdate = (details) {
                setState(() {
                  _lastState = "Move";
                });
              }
              ..onMultiLongPressUp = (details) {
                setState(() {
                  _lastState = "Up";
                });
              };
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Flutter Multi-Long-Press Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Last recognizer state:"),
              Text(
                _lastState ?? "-",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 50),
              const Text(
                "You have triggered the gesture this many times:",
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
