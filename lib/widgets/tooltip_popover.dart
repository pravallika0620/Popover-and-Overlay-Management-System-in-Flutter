import 'package:flutter/material.dart';

import '../controllers/popover_controller.dart';
import '../utils/popover_animations.dart';

/// A tooltip-style popover with a small arrow pointing back at the
/// widget that triggered it.
///
/// [TooltipPopover] is a [StatefulWidget] that wraps a [child] trigger
/// and, on tap (or long-press, if [showOnLongPress] is true), inserts an
/// [OverlayEntry] into the nearest [Overlay] to display [message].
class TooltipPopover extends StatefulWidget {
  const TooltipPopover({
    super.key,
    required this.controller,
    required this.id,
    required this.message,
    required this.child,
    this.backgroundColor = const Color(0xFF323232),
    this.textStyle,
    this.showOnLongPress = false,
    this.animationDuration = popoverAnimationDuration,
  });

  /// Shared controller used to track this popover alongside any others.
  final PopoverController controller;

  /// Unique id for this tooltip instance.
  final String id;

  /// Text shown inside the tooltip bubble.
  final String message;

  /// The widget the tooltip is anchored to.
  final Widget child;

  final Color backgroundColor;
  final TextStyle? textStyle;

  /// If true, the tooltip opens on long-press instead of tap.
  final bool showOnLongPress;

  final Duration animationDuration;

  @override
  State<TooltipPopover> createState() => _TooltipPopoverState();
}

class _TooltipPopoverState extends State<TooltipPopover> {
  final GlobalKey _anchorKey = GlobalKey();

  void _toggle() {
    if (widget.controller.isShowing(widget.id)) {
      widget.controller.hide(widget.id);
      return;
    }

    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final size = renderBox.size;
    final anchorOrigin = renderBox.localToGlobal(Offset.zero);

    widget.controller.show(
      context: context,
      id: widget.id,
      position: anchorOrigin,
      builder: (overlayContext, close) {
        final mediaWidth = MediaQuery.of(overlayContext).size.width;
        const bubbleWidth = 220.0;
        double left = anchorOrigin.dx + size.width / 2 - bubbleWidth / 2;
        left = left.clamp(8.0, mediaWidth - bubbleWidth - 8.0);
        final top = anchorOrigin.dy + size.height + 8;
        final arrowOffset =
            (anchorOrigin.dx + size.width / 2 - left).clamp(12.0, bubbleWidth - 12.0);

        return Positioned(
          left: left,
          top: top,
          width: bubbleWidth,
          child: TweenAnimationBuilder<double>(
            key: const Key('tooltip-popover'),
            tween: Tween(begin: 0, end: 1),
            duration: widget.animationDuration,
            curve: fadeInCurve,
            builder: (context, value, bubble) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -4),
                  child: bubble,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: arrowOffset - 6),
                    child: CustomPaint(
                      size: const Size(12, 6),
                      painter: _ArrowPainter(color: widget.backgroundColor),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: widget.textStyle ??
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.controller.isShowing(widget.id)) {
      widget.controller.hide(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _anchorKey,
      onTap: widget.showOnLongPress ? null : _toggle,
      onLongPress: widget.showOnLongPress ? _toggle : null,
      child: widget.child,
    );
  }
}

/// Small downward-pointing arrow used to visually connect a tooltip
/// bubble back to its trigger widget.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
