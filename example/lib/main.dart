import 'dart:collection';

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
      darkTheme: ThemeData.dark(),
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
  final Queue<MapEntry<Type?, int>> _lastStates = Queue();
  int _counter = 0;

  int maxSize = 10;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _addState(Object? details) {
    var entry = (_lastStates.lastOrNull?.key == details?.runtimeType
            ? _lastStates.removeLast()
            : null) ??
        MapEntry(details?.runtimeType, 0);
    _lastStates.addWithLimit(MapEntry(entry.key, entry.value + 1), maxSize);
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
            // postAcceptSlopTolerance: 100.0,
            pointerThreshold: 2,
          ),
          (instance) {
            instance
              ..onMultiLongPressDown = (details) {
                setState(() => _addState(details));
              }
              ..onMultiLongPress = (details) {
                HapticFeedback.vibrate();
                _addState(details);
                _incrementCounter();
              }
              ..onMultiLongPressCancel = () {
                setState(() => _addState(null));
              }
              ..onMultiLongPressMoveUpdate = (details) {
                setState(() => _addState(details));
              }
              ..onMultiLongPressUp = (details) {
                setState(() => _addState(details));
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
              _buildStatesLog(context),
              _buildLegend(context),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Last recognizer state:"),
                    Text(
                      _lastStates.lastOrNull != null
                          ? _getName(_lastStates.last.key)
                          : "-",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Flexible(child: SizedBox(height: 50)),
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 5.0,
                      ),
                      color: Theme.of(context).colorScheme.surfaceBright,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(500.0),
                          minScale: 0.5,
                          maxScale: 2.0,
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 4.0,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment(0.8, 1),
                                colors: [
                                  Color(0xff1f005c),
                                  Color(0xff5b0060),
                                  Color(0xff870160),
                                  Color(0xffac255e),
                                  Color(0xffca485c),
                                  Color(0xffe16b5c),
                                  Color(0xfff39060),
                                  Color(0xffffb56b),
                                ],
                                // Gradient from https://learnui.design/tools/gradient-generator.html
                                tileMode: TileMode.mirror,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Drag Me",
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatesLog(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            const double circleDiameter = 30.0;
            const double circlePadding = 2.0;
            const double circleSize = circleDiameter + (circlePadding * 2);

            var newMaxSize = constraints.maxWidth ~/ circleSize;
            if (newMaxSize != maxSize) {
              _lastStates.clearWithLimit(newMaxSize);
            }
            maxSize = newMaxSize;

            return ConstrainedBox(
              constraints: const BoxConstraints.tightFor(height: circleSize),
              child: Row(
                children: [
                  for (MapEntry<Type?, int> state in _lastStates.take(maxSize))
                    _buildStateIcon(
                      circlePadding,
                      circleDiameter,
                      3.0,
                      state.key,
                      value: state.value == 1 ? null : state.value.toString(),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStateDescription(MultiLongPressDownDetails),
        _buildStateDescription(MultiLongPressDetails),
        _buildStateDescription(MultiLongPressMoveUpdateDetails),
        _buildStateDescription(MultiLongPressUpDetails),
        _buildStateDescription(null),
      ],
    );
  }

  Widget _buildStateDescription(Type? state, {TextStyle? textStyle}) {
    textStyle ??= const TextStyle(fontWeight: FontWeight.bold);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStateIcon(0, 14.0, 2.0, state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text("=", style: textStyle),
        ),
        Text(_getName(state), style: textStyle),
      ],
    );
  }

  Widget _buildStateIcon(
    double circlePadding,
    double circleDiameter,
    double borderWidth,
    Type? state, {
    String? value,
  }) {
    return Padding(
      padding: EdgeInsets.all(circlePadding),
      child: Container(
        width: circleDiameter,
        height: circleDiameter,
        decoration: BoxDecoration(
          color: _getColor(state),
          border: Border.all(
            color: _getBorderColor(state),
            width: borderWidth,
          ),
          shape: BoxShape.circle,
        ),
        child: value != null
            ? Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: value.length > 2 ? 8.0 : 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color? _getColor(Type? state) {
    switch (state) {
      case const (MultiLongPressDetails):
        return Colors.green;
      case const (MultiLongPressDownDetails):
        return Colors.blue;
      case const (MultiLongPressMoveUpdateDetails):
        return null;
      case const (MultiLongPressUpDetails):
        return null;
      case null:
        return null;
      default:
        return null;
    }
  }

  Color _getBorderColor(Type? state) {
    switch (state) {
      case const (MultiLongPressDetails):
        return Colors.green;
      case const (MultiLongPressDownDetails):
        return Colors.blue;
      case const (MultiLongPressMoveUpdateDetails):
        return Colors.yellow.shade600;
      case const (MultiLongPressUpDetails):
        return Colors.orange;
      case null:
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  String _getName(Type? state) {
    switch (state) {
      case const (MultiLongPressDetails):
        return "Press";
      case const (MultiLongPressDownDetails):
        return "Down";
      case const (MultiLongPressMoveUpdateDetails):
        return "Move";
      case const (MultiLongPressUpDetails):
        return "Up";
      case null:
        return "Cancel";
      default:
        throw UnsupportedError("Unknown state: $state");
    }
  }
}

extension QueueExt<T> on Queue<T> {
  void addWithLimit(T element, int limit) {
    while (length >= limit) {
      removeFirst();
    }
    add(element);
  }

  void clearWithLimit(int limit) {
    while (length >= limit) {
      removeFirst();
    }
  }
}
