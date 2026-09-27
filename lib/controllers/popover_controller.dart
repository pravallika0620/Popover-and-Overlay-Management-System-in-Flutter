import 'package:flutter/material.dart';

import '../state/popover_state.dart';

/// Builds the widget shown inside a popover's [OverlayEntry].
///
/// [close] can be called by the popover's own content (e.g. a close
/// button) to dismiss it programmatically.
typedef PopoverBuilder = Widget Function(
  BuildContext context,
  VoidCallback close,
);

/// Manages the lifecycle of one or more overlay-based popovers.
///
/// A single [PopoverController] can drive several simultaneously visible
/// popovers (each identified by a unique [String] id), which is what
/// makes nested/stacked popovers possible: a dropdown item can trigger a
/// secondary context menu without the two conflicting, because each has
/// its own [OverlayEntry] and its own slot in [PopoverState].
///
/// The controller is a plain, injectable object (constructed once per
/// screen/app and handed to widgets that need it) rather than a global
/// singleton, which keeps the popover system easy to test.
class PopoverController {
  PopoverController({required this.state});

  final PopoverState state;

  final Map<String, OverlayEntry> _entries = {};
  final Map<String, PopoverBuilder> _builders = {};

  /// Whether a specific popover ([id] given) or any popover (no id) is
  /// currently showing.
  bool isShowing([String? id]) {
    if (id != null) return _entries.containsKey(id);
    return _entries.isNotEmpty;
  }

  /// Inserts the popover identified by [id] into the nearest [Overlay].
  ///
  /// If a popover with the same [id] is already showing it is replaced
  /// (removed, then reinserted) so callers can safely call [show] again
  /// to, for example, reposition or restyle an existing popover.
  void show({
    required BuildContext context,
    required String id,
    required PopoverBuilder builder,
    Offset position = Offset.zero,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
  }) {
    if (_entries.containsKey(id)) {
      hide(id);
    }

    _builders[id] = builder;

    final entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            if (barrierDismissible)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => hide(id),
                  child: ColoredBox(
                    color: barrierColor,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            _builders[id]!(overlayContext, () => hide(id)),
          ],
        );
      },
    );

    _entries[id] = entry;
    state.addPopover(id, position: position);
    Overlay.of(context).insert(entry);
  }

  /// Hides the popover identified by [id]. If [id] is omitted, every
  /// currently visible popover is hidden and removed from the overlay.
  void hide([String? id]) {
    if (id != null) {
      final entry = _entries.remove(id);
      _builders.remove(id);
      entry?.remove();
      state.removePopover(id);
      return;
    }

    for (final entry in _entries.values) {
      entry.remove();
    }
    _entries.clear();
    _builders.clear();
    state.clear();
  }

  /// Shows the popover if it isn't currently visible, hides it otherwise.
  void toggle({
    required BuildContext context,
    required String id,
    required PopoverBuilder builder,
    Offset position = Offset.zero,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
  }) {
    if (isShowing(id)) {
      hide(id);
    } else {
      show(
        context: context,
        id: id,
        builder: builder,
        position: position,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
      );
    }
  }

  /// Updates the tracked position of an already-visible popover and asks
  /// its [OverlayEntry] to rebuild, e.g. after a scroll or orientation
  /// change moves the trigger widget.
  void updatePosition(String id, Offset position) {
    state.updatePopoverPosition(id, position);
    _entries[id]?.markNeedsBuild();
  }

  /// Removes every popover and releases resources. Call this from the
  /// owning widget's `dispose()`.
  void dispose() {
    hide();
  }
}
