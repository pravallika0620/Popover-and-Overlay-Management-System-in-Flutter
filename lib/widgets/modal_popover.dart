import 'package:flutter/material.dart';

import '../controllers/popover_controller.dart';
import '../utils/popover_animations.dart';

/// A full-screen modal popover: a semi-transparent backdrop covering the
/// entire screen with a centered content card and an explicit close
/// button.
///
/// [ModalPopover] is a [StatefulWidget] that inserts its own
/// [OverlayEntry] (covering the whole screen) when [open] is called
/// (typically from tapping [child], if provided), and removes it when
/// dismissed via the backdrop, the close button, or programmatically.
class ModalPopover extends StatefulWidget {
  const ModalPopover({
    super.key,
    required this.controller,
    required this.id,
    required this.title,
    required this.message,
    this.child,
    this.backgroundColor = Colors.white,
    this.barrierColor = const Color(0x99000000),
    this.animationDuration = popoverAnimationDuration,
    this.actions,
  });

  final PopoverController controller;
  final String id;
  final String title;
  final String message;

  /// Optional trigger widget; tapping it opens the modal.
  final Widget? child;

  final Color backgroundColor;
  final Color barrierColor;
  final Duration animationDuration;

  /// Optional extra action widgets shown under the message.
  final List<Widget>? actions;

  @override
  State<ModalPopover> createState() => ModalPopoverState();
}

class ModalPopoverState extends State<ModalPopover> {
  /// Opens the modal. Public so it can be triggered from outside (e.g. a
  /// menu item elsewhere in the app), not just from [widget.child].
  void open(BuildContext hostContext) {
    if (widget.controller.isShowing(widget.id)) return;

    widget.controller.show(
      context: hostContext,
      id: widget.id,
      barrierDismissible: true,
      barrierColor: widget.barrierColor,
      builder: (overlayContext, close) {
        return Center(
          child: TweenAnimationBuilder<double>(
            key: const Key('modal-popover'),
            tween: Tween(begin: 0, end: 1),
            duration: widget.animationDuration,
            curve: scaleInCurve,
            builder: (context, value, card) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(scale: 0.9 + (0.1 * value), child: card),
              );
            },
            child: GestureDetector(
              // Swallow taps so tapping the card doesn't dismiss the modal
              // via the full-screen barrier behind it.
              onTap: () {},
              child: Material(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                elevation: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('modal-close-button'),
                              icon: const Icon(Icons.close),
                              splashRadius: 20,
                              onPressed: close,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.message),
                        if (widget.actions != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: widget.actions!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void close() {
    widget.controller.hide(widget.id);
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
    if (widget.child == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => open(context),
      child: widget.child,
    );
  }
}
