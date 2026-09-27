import 'package:flutter/material.dart';

import '../controllers/popover_controller.dart';

/// Wires a trigger widget's gestures (tap or long-press) to a
/// [PopoverController], computing the global position of the gesture (or
/// of the trigger widget itself) so the resulting popover can be
/// positioned correctly.
///
/// This keeps positioning/gesture boilerplate out of the individual
/// popover widgets and in one reusable place.
class PopoverGestureHandler extends StatelessWidget {
  const PopoverGestureHandler({
    super.key,
    required this.child,
    required this.controller,
    required this.popoverId,
    required this.builder,
    this.useLongPress = false,
    this.anchorToTriggerOrigin = true,
    this.barrierDismissible = true,
  });

  /// The widget that, when tapped or long-pressed, opens the popover.
  final Widget child;

  /// Controller responsible for showing/hiding the popover.
  final PopoverController controller;

  /// Unique id for the popover this trigger opens.
  final String popoverId;

  /// Builds the popover content.
  final PopoverBuilder builder;

  /// Whether the gesture that opens the popover is a long-press
  /// (context menus) instead of a tap (tooltips, dropdowns).
  final bool useLongPress;

  /// When true, the popover is anchored to the trigger widget's own
  /// top-left corner (good for tooltips/dropdowns). When false, it is
  /// anchored to the exact point where the gesture occurred (good for
  /// context menus).
  final bool anchorToTriggerOrigin;

  final bool barrierDismissible;

  Offset _triggerOrigin(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  void _open(BuildContext context, Offset? gesturePosition) {
    final position = anchorToTriggerOrigin
        ? _triggerOrigin(context)
        : (gesturePosition ?? _triggerOrigin(context));

    controller.toggle(
      context: context,
      id: popoverId,
      builder: builder,
      position: position,
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: useLongPress ? null : () => _open(context, null),
      onLongPressStart:
          useLongPress ? (details) => _open(context, details.globalPosition) : null,
      child: child,
    );
  }
}
