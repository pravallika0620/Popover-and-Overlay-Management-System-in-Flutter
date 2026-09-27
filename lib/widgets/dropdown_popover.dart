import 'package:flutter/material.dart';

import '../controllers/popover_controller.dart';
import '../utils/popover_animations.dart';

/// A dropdown-style popover that shows a scrollable list of [items]
/// anchored below its trigger [child].
///
/// [DropdownPopover] is a [StatefulWidget] that manages its own
/// [OverlayEntry], inserting/removing it as the dropdown opens/closes.
/// Selecting an item calls [onItemSelected] with the item's index and
/// label, and the global position at which the item was tapped -- this
/// makes it possible for a caller to open a *nested* popover (e.g. a
/// [ContextMenuPopover]) right where the item was tapped, without this
/// widget needing to know anything about that secondary popover.
class DropdownPopover extends StatefulWidget {
  const DropdownPopover({
    super.key,
    required this.controller,
    required this.id,
    required this.items,
    required this.child,
    this.onItemSelected,
    this.backgroundColor = Colors.white,
    this.maxHeight = 220,
    this.itemWidth = 200,
    this.animationDuration = popoverAnimationDuration,
    this.closeOnSelect = true,
  });

  final PopoverController controller;
  final String id;

  /// Labels shown in the dropdown list.
  final List<String> items;

  /// The trigger widget the dropdown is anchored to.
  final Widget child;

  /// Called with (index, label, globalTapPosition) when an item is tapped.
  final void Function(int index, String label, Offset globalPosition)?
      onItemSelected;

  final Color backgroundColor;
  final double maxHeight;
  final double itemWidth;
  final Duration animationDuration;

  /// Whether selecting an item automatically closes the dropdown.
  final bool closeOnSelect;

  @override
  State<DropdownPopover> createState() => _DropdownPopoverState();
}

class _DropdownPopoverState extends State<DropdownPopover> {
  final GlobalKey _anchorKey = GlobalKey();

  // One GlobalKey per rendered item. NOTE: the `context` argument that
  // ListView's itemBuilder hands you is the *sliver list's own* element
  // context (shared across every index), not a per-item context -- so
  // calling `context.findRenderObject()` inside itemBuilder returns the
  // RenderSliverList, not the tapped item's RenderBox. A dedicated
  // GlobalKey per item is the reliable way to look up that item's own
  // render box after the fact (e.g. inside its onTap callback).
  List<GlobalKey> _itemKeys = [];

  void _toggle() {
    if (widget.controller.isShowing(widget.id)) {
      widget.controller.hide(widget.id);
      return;
    }

    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());

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
        final media = MediaQuery.of(overlayContext).size;
        double left = anchorOrigin.dx;
        left = left.clamp(8.0, media.width - widget.itemWidth - 8.0);
        final top = anchorOrigin.dy + size.height + 6;

        return Positioned(
          left: left,
          top: top,
          width: widget.itemWidth,
          child: TweenAnimationBuilder<double>(
            key: const Key('dropdown-popover'),
            tween: Tween(begin: 0, end: 1),
            duration: widget.animationDuration,
            curve: slideInCurve,
            builder: (context, value, listWidget) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -8),
                  child: listWidget,
                ),
              );
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: widget.backgroundColor,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    return InkWell(
                      key: _itemKeys[index],
                      onTap: () {
                        final itemBox = _itemKeys[index]
                            .currentContext
                            ?.findRenderObject() as RenderBox?;
                        final tapPosition = itemBox != null && itemBox.attached
                            ? itemBox.localToGlobal(
                                Offset(itemBox.size.width / 2,
                                    itemBox.size.height / 2),
                              )
                            : anchorOrigin;

                        widget.onItemSelected
                            ?.call(index, widget.items[index], tapPosition);

                        if (widget.closeOnSelect) close();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(widget.items[index]),
                      ),
                    );
                  },
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
    return GestureDetector(
      key: _anchorKey,
      onTap: _toggle,
      child: widget.child,
    );
  }
}
