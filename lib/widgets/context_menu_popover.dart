import 'package:flutter/material.dart';

import '../controllers/popover_controller.dart';
import '../utils/popover_animations.dart';

/// A context-menu popover that appears exactly where a long-press (or a
/// programmatic trigger, e.g. from a nested [DropdownPopover] item)
/// occurred, rather than being anchored to the trigger widget's bounds.
///
/// [ContextMenuPopover] is a [StatefulWidget] that manages its own
/// [OverlayEntry]. It can be used two ways:
///  * Wrapped directly around a [child] to open on long-press at the
///    long-press location.
///  * Opened programmatically via [showAt], which is handy for nested
///    popovers (e.g. showing a context menu at the position of a tapped
///    dropdown item).
class ContextMenuPopover extends StatefulWidget {
  const ContextMenuPopover({
    super.key,
    required this.controller,
    required this.id,
    required this.items,
    this.child,
    this.onItemSelected,
    this.backgroundColor = const Color(0xFF2B2B2B),
    this.textColor = Colors.white,
    this.menuWidth = 180,
    this.animationDuration = popoverAnimationDuration,
  });

  final PopoverController controller;
  final String id;
  final List<String> items;

  /// Optional trigger widget; long-pressing it opens the menu at the
  /// gesture location. May be null if this menu is only ever opened
  /// programmatically via [showAt] (nested-popover scenario).
  final Widget? child;

  final void Function(int index, String label)? onItemSelected;
  final Color backgroundColor;
  final Color textColor;
  final double menuWidth;
  final Duration animationDuration;

  @override
  State<ContextMenuPopover> createState() => ContextMenuPopoverState();
}

class ContextMenuPopoverState extends State<ContextMenuPopover> {
  /// Opens the context menu at an arbitrary global [position]. Exposed
  /// so a parent (or a sibling popover, like a dropdown) can trigger a
  /// nested context menu without this widget needing a visible trigger
  /// of its own.
  void showAt(BuildContext hostContext, Offset position) {
    if (widget.controller.isShowing(widget.id)) {
      widget.controller.hide(widget.id);
      return;
    }

    widget.controller.show(
      context: hostContext,
      id: widget.id,
      position: position,
      builder: (overlayContext, close) {
        final media = MediaQuery.of(overlayContext).size;
        double left = position.dx;
        double top = position.dy;
        left = left.clamp(8.0, media.width - widget.menuWidth - 8.0);
        final estimatedHeight = widget.items.length * 44.0 + 8;
        if (top + estimatedHeight > media.height - 8) {
          top = (media.height - estimatedHeight - 8).clamp(8.0, media.height);
        }

        return Positioned(
          left: left,
          top: top,
          width: widget.menuWidth,
          child: TweenAnimationBuilder<double>(
            key: const Key('context-menu-popover'),
            tween: Tween(begin: 0, end: 1),
            duration: widget.animationDuration,
            curve: scaleInCurve,
            builder: (context, value, menu) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.85 + (0.15 * value),
                  alignment: Alignment.topLeft,
                  child: menu,
                ),
              );
            },
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(8),
              color: widget.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    return InkWell(
                      onTap: () {
                        widget.onItemSelected
                            ?.call(index, widget.items[index]);
                        close();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          widget.items[index],
                          style: TextStyle(color: widget.textColor),
                        ),
                      ),
                    );
                  }),
                ),
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
    if (widget.child == null) {
      // No visible trigger; this instance is only opened via showAt().
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPressStart: (details) => showAt(context, details.globalPosition),
      child: widget.child,
    );
  }
}
