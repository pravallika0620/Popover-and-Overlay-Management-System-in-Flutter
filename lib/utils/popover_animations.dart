import 'package:flutter/animation.dart';

/// Central place for every animation constant used by the popover
/// system, so every widget stays visually consistent and the timings
/// are easy to tune from one location.

/// Used when a popover simply fades into view (tooltips).
const Curve fadeInCurve = Curves.easeOut;

/// Used when a popover slides in from an edge (dropdowns, context menus).
const Curve slideInCurve = Curves.easeOutCubic;

/// Used when a popover scales up from its anchor point (modals).
const Curve scaleInCurve = Curves.easeOutBack;

/// Default duration for popover enter/exit animations. Individual
/// popovers may still be driven by a duration loaded from
/// `assets/popover_config.json`; this constant is the sensible default
/// when no configuration value is supplied.
const Duration popoverAnimationDuration = Duration(milliseconds: 220);

/// Slightly shorter duration used for exit/dismiss transitions so the
/// UI feels snappier on the way out than on the way in.
const Duration popoverExitDuration = Duration(milliseconds: 150);
