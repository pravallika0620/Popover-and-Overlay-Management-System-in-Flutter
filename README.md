# PopoverPro

An advanced popover and overlay management system built on Flutter's
`Overlay` / `OverlayEntry` APIs (no third-party popover packages) —
tooltips, dropdown menus, context menus, and modals, all driven by a
single reusable `PopoverController`.

## Project structure

```
.
├── assets/
│   └── popover_config.json         # popover content/styling config
├── lib/
│   ├── controllers/
│   │   └── popover_controller.dart # show/hide/toggle overlay lifecycle
│   ├── state/
│   │   └── popover_state.dart      # tracks active popovers & positions
│   ├── utils/
│   │   ├── gesture_handler.dart    # tap/long-press → popover wiring
│   │   └── popover_animations.dart # shared curves & durations
│   ├── widgets/
│   │   ├── tooltip_popover.dart
│   │   ├── dropdown_popover.dart
│   │   ├── context_menu_popover.dart
│   │   └── modal_popover.dart
│   └── main.dart                   # demo app wiring everything together
├── test/
│   └── popover_widget_test.dart
├── integration_test/
│   └── popover_flow_test.dart
├── android/                        # Android host project
├── Dockerfile
├── docker-compose.yml
├── build.sh                        # one-shot pub get → test → build apk
└── .env.example
```

## What's implemented

- **`PopoverController`** — `show()`, `hide()`, `toggle()`, `isShowing()`,
  `updatePosition()`. Supports multiple simultaneously-visible popovers
  keyed by id, which is what allows nested popovers (e.g. a dropdown
  item opening a context menu) without the two conflicting.
- **`PopoverState`** — a `ChangeNotifier` (not a global singleton)
  exposing `activePopoverIds` and `popoverPositions`, injectable via the
  `PopoverScope` `InheritedNotifier`.
- **`TooltipPopover`** — fades in below its trigger with a small arrow
  pointing back at it. `Key('tooltip-popover')`.
- **`DropdownPopover`** — anchored, scrollable list of items;
  `onItemSelected` reports the tapped item's global position so a caller
  can open a nested popover right where the tap happened.
  `Key('dropdown-popover')`.
- **`ContextMenuPopover`** — opens exactly at a long-press location (or
  programmatically via `showAt()`, used for the nested-popover demo).
  `Key('context-menu-popover')`.
- **`ModalPopover`** — centered card over a full-screen semi-transparent
  backdrop, with a `Key('modal-close-button')` close button.
  `Key('modal-popover')`.
- **`assets/popover_config.json`** — loaded at startup and used to style
  each popover (background color, per-popover animation duration).
- **Nested popover demo** — in `lib/main.dart`, selecting an item in the
  `DropdownPopover` opens a `ContextMenuPopover` at that item's tapped
  position, demonstrating two independently-tracked popovers coexisting.

## Running locally (with the Flutter SDK already installed)

```bash
flutter pub get
flutter run
```

## Running tests

```bash
flutter test                                   # widget tests
flutter test integration_test/popover_flow_test.dart   # integration test
```

## Building with Docker

The project ships a `Dockerfile`/`docker-compose.yml` so the build does
not depend on the host machine having Flutter/Android SDKs installed.

```bash
# Verify the environment
docker-compose run --rm flutter_build flutter --version

# Get packages
docker-compose run --rm flutter_build flutter pub get

# Run the test suite
docker-compose run --rm flutter_build flutter test

# Build the release APK
docker-compose run --rm flutter_build flutter build apk --release
```

Or run everything in one shot:

```bash
docker-compose run --rm flutter_build ./build.sh
```

The resulting APK is written to
`build/app/outputs/flutter-apk/app-release.apk` (this is mounted back to
the host via the `docker-compose.yml` volume, so it appears in the
repository once the build finishes).

> **Note on the `android/` folder:** Gradle/AGP/NDK versions are tightly
> coupled to the exact Flutter SDK version used to build. `build.sh`
> (and the Dockerfile) run `flutter create --platforms=android .` before
> building, which asks Flutter itself to (re)generate the platform
> scaffold for whatever Flutter version is installed in the image. This
> is safe and idempotent — it only fills in/updates platform boilerplate
> (Gradle wrapper, `build.gradle` versions, etc.) and never touches
> `lib/`, `test/`, `integration_test/`, `assets/`, or `pubspec.yaml`.

## Configuration format

`assets/popover_config.json`:

```json
{
  "popovers": [
    {
      "id": "string",
      "type": "tooltip | dropdown | context | modal",
      "position": "top | bottom | left | right | center",
      "content": "string",
      "backgroundColor": "#RRGGBB",
      "animationDuration": 200
    }
  ]
}
```

## Design notes

- No global singletons: `PopoverState` and `PopoverController` are
  created once in `PopoverDemoScreen` and passed explicitly to every
  widget that needs them (or accessed via `PopoverScope` where an
  `InheritedNotifier` is more convenient), which keeps the system easy
  to unit-test.
- `OverlayEntry`s are always removed in the owning widget's `dispose()`
  as well as on explicit hide/toggle, to avoid overlay memory leaks.
- Positioning uses each trigger's `RenderBox.localToGlobal(Offset.zero)`
  and clamps against `MediaQuery` bounds so popovers stay on-screen near
  screen edges.
- Animation curves/durations are centralized in
  `lib/utils/popover_animations.dart` and can be overridden per-instance
  from the JSON configuration.
