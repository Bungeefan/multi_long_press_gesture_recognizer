import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'multi_long_press_gesture_recognizer.dart';

class MultiLongPressGestureRecognizerTest extends StatelessWidget {
  final Widget child;

  const MultiLongPressGestureRecognizerTest({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        MultiLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            MultiLongPressGestureRecognizer>(
          () => MultiLongPressGestureRecognizer(
            duration: const Duration(milliseconds: 2000),
            preAcceptSlopTolerance: 25,
            postAcceptSlopTolerance: 50,
            pointerThreshold: 2,
          ),
          (instance) {
            instance
              ..onMultiLongPressDown = (details) {
                debugPrint("----------Down Callback triggered----------"
                    "\n$details");
              }
              ..onMultiLongPress = (details) {
                debugPrint("----------Press Callback triggered----------"
                    "\n$details");
                HapticFeedback.vibrate();
              }
              ..onMultiLongPressCancel = () {
                debugPrint("----------Cancel Callback triggered----------");
              }
              ..onMultiLongPressMoveUpdate = (details) {
                debugPrint("----------Move Update Callback triggered----------"
                    "\n$details");
              }
              ..onMultiLongPressUp = (details) {
                debugPrint("----------Up Callback triggered----------"
                    "\n$details");
              };
          },
        ),
      },
      child: child,
    );
  }
}
