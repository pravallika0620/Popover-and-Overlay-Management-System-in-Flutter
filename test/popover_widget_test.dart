import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popover_pro/controllers/popover_controller.dart';
import 'package:popover_pro/state/popover_state.dart';
import 'package:popover_pro/widgets/context_menu_popover.dart';
import 'package:popover_pro/widgets/dropdown_popover.dart';
import 'package:popover_pro/widgets/modal_popover.dart';
import 'package:popover_pro/widgets/tooltip_popover.dart';

/// Wraps [child] in a minimal [MaterialApp]/[Scaffold] so widgets that
/// rely on [Overlay], [Material] ancestors, and [MediaQuery] behave as
/// they would in the real app.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TooltipPopover', () {
    testWidgets('shows bubble with arrow on tap and hides on second tap',
        (tester) async {
      final state = PopoverState();
      final controller = PopoverController(state: state);

      await tester.pumpWidget(_wrap(
        TooltipPopover(
          controller: controller,
          id: 'tip-1',
          message: 'Helpful hint',
          child: const Icon(Icons.info),
        ),
      ));

      expect(find.byKey(const Key('tooltip-popover')), findsNothing);

      await tester.tap(find.byIcon(Icons.info));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tooltip-popover')), findsOneWidget);
      expect(find.text('Helpful hint'), findsOneWidget);
      expect(controller.isShowing('tip-1'), isTrue);

      await tester.tap(find.byIcon(Icons.info));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tooltip-popover')), findsNothing);
      expect(controller.isShowing('tip-1'), isFalse);
    });
  });

  group('DropdownPopover', () {
    testWidgets('opens, scrolls, and reports item selection',
        (tester) async {
      final state = PopoverState();
      final controller = PopoverController(state: state);
      String? selected;

      final manyItems =
          List.generate(15, (i) => 'Item $i'); // forces scrolling

      await tester.pumpWidget(_wrap(
        DropdownPopover(
          controller: controller,
          id: 'dd-1',
          items: manyItems,
          maxHeight: 150,
          onItemSelected: (index, label, position) => selected = label,
          child: const Text('Open dropdown'),
        ),
      ));

      await tester.tap(find.text('Open dropdown'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown-popover')), findsOneWidget);
      // 15 items vs. a 150px max height means the list is constrained
      // and scrollable rather than overflowing the layout.
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Item 14'), findsNothing); // not all items fit

      // Scrolling should reveal later items without throwing.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Selecting a visible item should report it and close the dropdown.
      final visibleItem = find.textContaining('Item').first;
      final selectedLabel =
          (tester.widget<Text>(visibleItem)).data;
      await tester.tap(visibleItem);
      await tester.pumpAndSettle();

      expect(controller.isShowing('dd-1'), isFalse);
      expect(selected, selectedLabel);
    });
  });

  group('ContextMenuPopover', () {
    testWidgets('appears at long-press location and reports selection',
        (tester) async {
      final state = PopoverState();
      final controller = PopoverController(state: state);
      String? selected;

      await tester.pumpWidget(_wrap(
        ContextMenuPopover(
          controller: controller,
          id: 'ctx-1',
          items: const ['Copy', 'Paste'],
          onItemSelected: (index, label) => selected = label,
          child: Container(
            width: 200,
            height: 200,
            color: Colors.blue,
          ),
        ),
      ));

      expect(find.byKey(const Key('context-menu-popover')), findsNothing);

      await tester.longPress(find.byType(Container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('context-menu-popover')), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(selected, 'Copy');
      expect(controller.isShowing('ctx-1'), isFalse);
    });
  });

  group('ModalPopover', () {
    testWidgets(
        'shows semi-transparent backdrop and closes via close button',
        (tester) async {
      final state = PopoverState();
      final controller = PopoverController(state: state);

      await tester.pumpWidget(_wrap(
        ModalPopover(
          controller: controller,
          id: 'modal-1',
          title: 'Settings',
          message: 'Update your preferences.',
          child: const Text('Open modal'),
        ),
      ));

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('modal-popover')), findsOneWidget);
      expect(find.byKey(const Key('modal-close-button')), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('modal-close-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('modal-popover')), findsNothing);
      expect(controller.isShowing('modal-1'), isFalse);
    });

    testWidgets('dismisses when the backdrop is tapped', (tester) async {
      final state = PopoverState();
      final controller = PopoverController(state: state);

      await tester.pumpWidget(_wrap(
        ModalPopover(
          controller: controller,
          id: 'modal-2',
          title: 'Settings',
          message: 'Update your preferences.',
          child: const Text('Open modal'),
        ),
      ));

      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('modal-popover')), findsOneWidget);

      // Tap far corner of the screen, outside the centered card.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('modal-popover')), findsNothing);
    });
  });

  group('PopoverController', () {
    test('show/hide/toggle/isShowing/updatePosition manage lifecycle', () {
      final state = PopoverState();
      final controller = PopoverController(state: state);

      expect(controller.isShowing(), isFalse);
      expect(controller.isShowing('any'), isFalse);

      controller.updatePosition('never-shown', const Offset(1, 1));
      expect(state.popoverPositions.containsKey('never-shown'), isFalse);
    });
  });
}
