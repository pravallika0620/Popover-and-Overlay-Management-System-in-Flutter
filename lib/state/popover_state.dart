import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tracks which popovers are currently active and where they are
/// positioned on screen. This is intentionally a plain [ChangeNotifier]
/// (rather than a global singleton) so it can be injected into the
/// widget tree via an [InheritedNotifier]/constructor and remain easy
/// to test in isolation.
class PopoverState extends ChangeNotifier {
  /// IDs of every popover that is currently visible, in the order they
  /// were shown. The last element is the most recently opened popover,
  /// which is useful for nested/stacked popover scenarios.
  final List<String> activePopoverIds = [];

  /// The last known global position for each active popover, keyed by id.
  final Map<String, Offset> popoverPositions = {};

  /// Whether [id] is currently among the active popovers.
  bool isActive(String id) => activePopoverIds.contains(id);

  /// Whether any popover is currently active.
  bool get hasActivePopovers => activePopoverIds.isNotEmpty;

  /// The id of the most recently opened (topmost) popover, if any.
  String? get topmostId =>
      activePopoverIds.isEmpty ? null : activePopoverIds.last;

  void addPopover(String id, {Offset position = Offset.zero}) {
    if (!activePopoverIds.contains(id)) {
      activePopoverIds.add(id);
    }
    popoverPositions[id] = position;
    notifyListeners();
  }

  void removePopover(String id) {
    final removed = activePopoverIds.remove(id);
    popoverPositions.remove(id);
    if (removed) {
      notifyListeners();
    }
  }

  void updatePopoverPosition(String id, Offset position) {
    if (activePopoverIds.contains(id)) {
      popoverPositions[id] = position;
      notifyListeners();
    }
  }

  /// Removes every tracked popover. Used when a full teardown is needed,
  /// e.g. on route change or when dismissing an entire popover stack.
  void clear() {
    if (activePopoverIds.isEmpty) return;
    activePopoverIds.clear();
    popoverPositions.clear();
    notifyListeners();
  }
}

/// Makes a [PopoverState] (and, optionally, a matching controller)
/// available to descendant widgets without resorting to a global
/// singleton.
class PopoverScope extends InheritedNotifier<PopoverState> {
  const PopoverScope({
    super.key,
    required PopoverState state,
    required super.child,
  }) : super(notifier: state);

  static PopoverState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PopoverScope>();
    assert(scope != null, 'No PopoverScope found in context');
    return scope!.notifier!;
  }
}
