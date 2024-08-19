import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_long_press_gesture_recognizer/multi_long_press_gesture_recognizer.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi Long press', () {
    late MultiLongPressGestureRecognizer gesture;
    late List<String> recognized;
    late TestPointer pointer1;
    late TestPointer pointer2;

    void setUpHandlers() {
      gesture
        ..onMultiLongPressDown = (MultiLongPressDownDetails details) {
          recognized.add('down');
        }
        ..onMultiLongPressCancel = () {
          recognized.add('cancel');
        }
        ..onMultiLongPress = (MultiLongPressDetails details) {
          recognized.add('press');
        }
        ..onMultiLongPressMoveUpdate =
            (MultiLongPressMoveUpdateDetails details) {
          recognized.add('move');
        }
        ..onMultiLongPressUp = (MultiLongPressUpDetails details) {
          recognized.add('up');
        };
    }

    setUp(() {
      recognized = [];
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        preAcceptSlopTolerance: 20,
      );
      setUpHandlers();
      pointer1 = TestPointer(1);
      pointer2 = TestPointer(2);
    });

    tearDown(() {
      gesture.dispose();
      recognized.clear();
    });

    // ----- Util methods -----
    void setupDown(
      GestureTester tester, {
      Offset offset1 = const Offset(10.0, 10.0),
      Offset offset2 = const Offset(20.0, 10.0),
      List<GestureRecognizer>? gestures,
    }) {
      initialDownEvents(
        tester,
        gesture,
        recognized,
        pointer1,
        offset1,
        pointer2,
        offset2,
        gestures: gestures,
      );
    }
    // ----- Util methods -----

    testGesture('Should recognize long press', (GestureTester tester) {
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press']);
    });

    testGesture('Should recognize long press with altered duration',
        (GestureTester tester) {
      gesture.dispose();
      gesture = MultiLongPressGestureRecognizer(
        pointerThreshold: 2,
        duration: const Duration(milliseconds: 100),
      );
      setUpHandlers();
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 50));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 50));
      expect(recognized, const <String>['down', 'press']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press']);
    });

    testGesture('Filters long press based on device kind',
        (GestureTester tester) {
      gesture.dispose();
      gesture = MultiLongPressGestureRecognizer(
        pointerThreshold: 2,
        duration: const Duration(milliseconds: 500),
        supportedDevices: <PointerDeviceKind>{PointerDeviceKind.touch},
      );
      setUpHandlers();

      // "Unsupported" mouse pointer (should be ignored)
      final TestPointer pointer3 = TestPointer(3, PointerDeviceKind.mouse);
      var down3 = pointer3.down(const Offset(150, 150));
      gesture.addPointer(down3);
      tester.closeArena(pointer3.pointer);
      expect(recognized, const <String>[]);
      tester.route(down3);
      expect(recognized, const <String>[]);
      tester.route(pointer3.move(const Offset(170, 170)));
      expect(recognized, const <String>[]);
      tester.route(pointer3.up());
      expect(recognized, const <String>[]);

      // Usual touch pointers
      setupDown(tester);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press']);
    });

    testGesture('Should recognize long press move', (GestureTester tester) {
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer1.move(const Offset(25, 15)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer2.move(const Offset(15, 15)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
    });

    testGesture('Should recognize long press up', (GestureTester tester) {
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer1.move(const Offset(25, 15)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer2.move(const Offset(15, 15)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.route(pointer1.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
    });

    testGesture('Up cancels long press', (GestureTester tester) {
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'cancel']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'cancel']);
    });

    testGesture('Moving before accept cancels', (GestureTester tester) {
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.route(pointer1.move(const Offset(100, 100)));
      expect(recognized, const <String>['down', 'cancel']);
      tester.async.elapse(const Duration(seconds: 1));
      tester.route(pointer1.up());
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'cancel']);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down', 'cancel']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'cancel']);
    });

    testGesture('Moving under slop before accept is ok',
        (GestureTester tester) {
      setupDown(tester);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.route(pointer1.move(const Offset(20, 20)));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer1.up());
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'up']);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down', 'press', 'up']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'up']);
    });

    testGesture('Moving under slop after accept is ok', (GestureTester tester) {
      gesture.dispose();
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        postAcceptSlopTolerance: 50,
      );
      setUpHandlers();
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer1.move(const Offset(20, 20)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer1.move(const Offset(5, 5)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.route(pointer1.up());
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
    });

    testGesture('Moving after accept stops events', (GestureTester tester) {
      gesture.dispose();
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        postAcceptSlopTolerance: 50,
      );
      setUpHandlers();
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer1.move(const Offset(20, 20)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer1.move(const Offset(100, 100)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer1.up());
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down', 'press', 'move']);
      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move']);
    });

    testGesture('Second pointer repeatedly triggers down/cancel',
        (GestureTester tester) {
      setupDown(tester);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'cancel']);
      tester.async.elapse(const Duration(seconds: 1));
      expect(recognized, const <String>['down', 'cancel']);

      var expected = ['down', 'cancel'];
      for (int i = 3; i < 20; i++) {
        final TestPointer pointerX = TestPointer(i);
        final PointerDownEvent downX =
            pointerX.down(Offset(100 + (i + 2), 100 + (i * 10)));
        gesture.addPointer(downX);
        tester.closeArena(pointerX.pointer);
        expect(recognized, expected);
        tester.route(downX);
        expected.add('down');
        expect(recognized, expected);
        tester.async.elapse(const Duration(milliseconds: 300));
        expect(recognized, expected);

        tester.route(pointerX.up());
        expected.add('cancel');
        expect(recognized, expected);
        tester.async.elapse(const Duration(seconds: 1));
        expect(recognized, expected);
      }

      gesture.dispose();
      expect(recognized, expected);
    });

    testGesture('No move events after up', (GestureTester tester) {
      setupDown(tester);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer2.move(const Offset(30, 30)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.async.elapse(const Duration(milliseconds: 300));

      final TestPointer pointer3 = TestPointer(3);
      var down3 = pointer3.down(const Offset(150, 150));
      gesture.addPointer(down3);
      tester.closeArena(pointer3.pointer);
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.route(down3);
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.route(pointer3.move(const Offset(170, 170)));
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.route(pointer3.up());
      expect(recognized, const <String>['down', 'press', 'move', 'up']);

      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
    });

    testGesture('Resets after last pointer tracking stopped',
        (GestureTester tester) {
      setupDown(tester);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer2.move(const Offset(30, 30)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.async.elapse(const Duration(milliseconds: 300));

      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      tester.route(pointer1.up());
      expect(recognized, const <String>['down', 'press', 'move', 'up']);
      // Released all pointers
      recognized.clear();
      // Start again with new pointers
      final TestPointer pointer3 = TestPointer(3);
      final PointerDownEvent down3 = pointer3.down(const Offset(10, 10));
      gesture.addPointer(down3);
      tester.closeArena(pointer3.pointer);
      expect(recognized, const <String>[]);
      tester.route(down3);
      expect(recognized, const <String>[]);

      final TestPointer pointer4 = TestPointer(4);
      final PointerDownEvent down4 = pointer4.down(const Offset(20, 10));
      gesture.addPointer(down4);
      tester.closeArena(pointer4.pointer);
      expect(recognized, const <String>[]);
      tester.route(down4);
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(seconds: 1));
      expect(recognized, const <String>['down', 'press']);

      tester.route(pointer3.move(const Offset(20, 20)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer4.move(const Offset(30, 20)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.route(pointer3.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
      tester.route(pointer4.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);

      gesture.dispose();
      expect(recognized, const <String>['down', 'press', 'move', 'move', 'up']);
    });

    testGesture(
        'No events after repeatedly exceeding post-slop with new pointers',
        (GestureTester tester) {
      gesture.dispose();
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        postAcceptSlopTolerance: 50,
      );
      setUpHandlers();
      setupDown(tester);

      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);
      tester.route(pointer2.move(const Offset(30, 30)));
      expect(recognized, const <String>['down', 'press', 'move']);
      // Move under slop
      tester.route(pointer2.move(const Offset(40, 40)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      // Exceed slop (stops events)
      tester.route(pointer2.move(const Offset(100, 100)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.async.elapse(const Duration(milliseconds: 300));

      // Further pointers shouldn't trigger events until all pointers have been removed.
      var expected = ['down', 'press', 'move', 'move'];
      for (int i = 3; i < 20; i++) {
        final TestPointer pointerX = TestPointer(i);
        final PointerDownEvent downX = pointerX.down(const Offset(100, 100));
        gesture.addPointer(downX);
        tester.closeArena(pointerX.pointer);
        expect(recognized, expected);
        tester.route(downX);
        expect(recognized, expected);
        // Exceed slop again
        tester.route(pointerX.move(const Offset(200, 200)));
        expect(recognized, expected);
        tester.route(pointerX.up());
        expect(recognized, expected);
      }

      gesture.dispose();
      expect(recognized, expected);
    });
  });

  group('Compete with drag gestures', () {
    late MultiLongPressGestureRecognizer gesture;
    late List<String> recognized;
    late TestPointer pointer1;
    late TestPointer pointer2;

    late VerticalDragGestureRecognizer drag;
    // Copied from long_press_test
    bool isDangerousStack = false;

    void setUpHandlers() {
      gesture
        ..onMultiLongPressDown = (MultiLongPressDownDetails details) {
          recognized.add('down');
        }
        ..onMultiLongPressCancel = () {
          recognized.add('cancel');
        }
        ..onMultiLongPress = (MultiLongPressDetails details) {
          recognized.add('press');
        }
        ..onMultiLongPressMoveUpdate =
            (MultiLongPressMoveUpdateDetails details) {
          recognized.add('move');
        }
        ..onMultiLongPressUp = (MultiLongPressUpDetails details) {
          recognized.add('up');
        };
    }

    setUp(() {
      recognized = [];
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        preAcceptSlopTolerance: 120,
      );
      setUpHandlers();
      pointer1 = TestPointer(1);
      pointer2 = TestPointer(2);

      drag = VerticalDragGestureRecognizer();
      drag.onStart = (DragStartDetails details) {
        expect(isDangerousStack, isFalse);
        recognized.add('drag_start');
      };
    });

    tearDown(() {
      gesture.dispose();
      drag.dispose();
      recognized.clear();
    });

    // ----- Util methods -----
    void setupDown(
      GestureTester tester, {
      Offset offset1 = const Offset(10.0, 10.0),
      Offset offset2 = const Offset(20.0, 10.0),
      List<GestureRecognizer>? gestures,
    }) {
      initialDownEvents(
        tester,
        gesture,
        recognized,
        pointer1,
        offset1,
        pointer2,
        offset2,
        gestures: gestures,
      );
    }
    // ----- Util methods -----

    testGesture('Drag start delayed by microtask', (GestureTester tester) {
      setupDown(tester, gestures: [drag]);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      isDangerousStack = true;
      gesture.dispose();
      isDangerousStack = false;
      expect(recognized, const <String>['down', 'cancel']);
      tester.async.flushMicrotasks();
      expect(recognized, const <String>['down', 'cancel', 'drag_start']);
      drag.dispose();
      expect(recognized, const <String>['down', 'cancel', 'drag_start']);
    });

    testGesture('Rejected via drag start', (GestureTester tester) {
      setupDown(tester, gestures: [drag]);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.route(pointer1.move(const Offset(100, 200)));
      tester.route(pointer2.move(const Offset(200, 200)));

      expect(recognized, const <String>['down', 'cancel', 'drag_start']);
      drag.dispose();
      expect(recognized, const <String>['down', 'cancel', 'drag_start']);
    });

    testGesture(
        "Co-exist with drag gesture via third pointer or don't cancel on unrelated gesture rejects",
        (GestureTester tester) {
      setupDown(tester, gestures: [drag]);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 700));
      expect(recognized, const <String>['down', 'press']);

      tester.route(pointer1.move(const Offset(20, 20)));
      expect(recognized, const <String>['down', 'press', 'move']);
      tester.route(pointer2.move(const Offset(30, 20)));
      expect(recognized, const <String>['down', 'press', 'move', 'move']);

      // "Interfere" with third drag pointer.
      // (Flutter will still send non-moving move events for the other pointers!)
      final TestPointer pointer3 = TestPointer(3);
      final PointerDownEvent down3 = pointer3.down(const Offset(100, 100));
      gesture.addPointer(down3);
      drag.addPointer(down3);
      tester.closeArena(pointer3.pointer);
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      tester.route(down3);
      expect(recognized, const <String>['down', 'press', 'move', 'move']);
      // ---- Clear events ----
      recognized.clear();
      // ---- Clear events ----
      tester.route(pointer3.move(const Offset(100, 120)));
      expect(recognized, const <String>['drag_start']);

      // Events of the original pointers should still work normally
      tester.route(pointer1.move(const Offset(25, 25)));
      expect(recognized, const <String>['drag_start', 'move']);
      tester.route(pointer2.move(const Offset(35, 25)));
      expect(recognized, const <String>['drag_start', 'move', 'move']);
      tester.route(pointer1.up());
      expect(recognized, const <String>['drag_start', 'move', 'move', 'up']);
      tester.route(pointer2.up());
      expect(recognized, const <String>['drag_start', 'move', 'move', 'up']);

      drag.dispose();
      expect(recognized, const <String>['drag_start', 'move', 'move', 'up']);
    });
  });

  group('Compete with scale gestures', () {
    late MultiLongPressGestureRecognizer gesture;
    late List<String> recognized;
    late TestPointer pointer1;
    late TestPointer pointer2;

    late ScaleGestureRecognizer drag;
    // Copied from long_press_test
    bool isDangerousStack = false;

    void setUpHandlers() {
      gesture
        ..onMultiLongPressDown = (MultiLongPressDownDetails details) {
          recognized.add('down');
        }
        ..onMultiLongPressCancel = () {
          recognized.add('cancel');
        }
        ..onMultiLongPress = (MultiLongPressDetails details) {
          recognized.add('press');
        }
        ..onMultiLongPressMoveUpdate =
            (MultiLongPressMoveUpdateDetails details) {
          recognized.add('move');
        }
        ..onMultiLongPressUp = (MultiLongPressUpDetails details) {
          recognized.add('up');
        };
    }

    setUp(() {
      recognized = [];
      gesture = MultiLongPressGestureRecognizer(
        duration: const Duration(milliseconds: 500),
        pointerThreshold: 2,
        preAcceptSlopTolerance: 5,
      );
      setUpHandlers();
      pointer1 = TestPointer(1);
      pointer2 = TestPointer(2);

      drag = ScaleGestureRecognizer();
      drag.onStart = (ScaleStartDetails details) {
        expect(isDangerousStack, isFalse);
        recognized.add('scale_start');
      };
    });

    tearDown(() {
      gesture.dispose();
      drag.dispose();
      recognized.clear();
    });

    testGesture('Rejected via scale start', (GestureTester tester) {
      final PointerDownEvent down = pointer1.down(const Offset(10.0, 10.0));
      drag.addPointer(down);
      gesture.addPointer(down);
      tester.closeArena(pointer1.pointer);
      expect(recognized, const <String>[]);
      tester.route(down);
      expect(recognized, const <String>[]);

      final PointerDownEvent down2 = pointer2.down(const Offset(20.0, 10.0));
      drag.addPointer(down2);
      gesture.addPointer(down2);
      tester.closeArena(pointer2.pointer);
      expect(recognized, const <String>[]);
      tester.route(down2);

      expect(recognized, const <String>['down']);
      tester.async.elapse(const Duration(milliseconds: 300));
      expect(recognized, const <String>['down']);

      tester.route(pointer1.move(const Offset(5, 5)));
      tester.route(pointer2.move(const Offset(40, 20)));

      expect(recognized, const <String>['down', 'cancel', 'scale_start']);
      drag.dispose();
      expect(recognized, const <String>['down', 'cancel', 'scale_start']);
    });
  });
}

void initialDownEvents(
  GestureTester tester,
  MultiLongPressGestureRecognizer gesture,
  List<String> recognized,
  TestPointer pointer1,
  Offset offset1,
  TestPointer pointer2,
  Offset offset2, {
  List<GestureRecognizer>? gestures,
}) {
  final PointerDownEvent down = pointer1.down(offset1);
  gesture.addPointer(down);
  gestures?.forEach((x) => x.addPointer(down));
  tester.closeArena(pointer1.pointer);
  expect(recognized, const <String>[]);
  tester.route(down);
  expect(recognized, const <String>[]);

  final PointerDownEvent down2 = pointer2.down(offset2);
  gesture.addPointer(down2);
  gestures?.forEach((x) => x.addPointer(down2));
  tester.closeArena(pointer2.pointer);
  expect(recognized, const <String>[]);
  tester.route(down2);
  expect(recognized, const <String>['down']);
}
