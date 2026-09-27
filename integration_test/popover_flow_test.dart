import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:popover_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Nested popover flow', () {
    testWidgets(
      'opening a dropdown, then a nested context menu from one of its '
      'items, shows both without conflict, and both dismiss cleanly',
      (tester) async {
        app.main();
        // Wait for the async popover_config.json load to complete and
        // the demo screen to build.
        await tester.pumpAndSettle();

        // --- Step 1: open the primary popover (the dropdown) ---
        final dropdownTrigger = find.text('Actions');
        expect(dropdownTrigger, findsOneWidget);

        await tester.tap(dropdownTrigger);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dropdown-popover')),
          findsOneWidget,
          reason: 'Dropdown should be visible after tapping its trigger',
        );

        // --- Step 2: interact with an item to trigger a nested popover ---
        final firstItem = find.text('Share');
        expect(firstItem, findsOneWidget);

        await tester.tap(firstItem);
        await tester.pumpAndSettle();

        // --- Step 3: verify both popovers can coexist without conflict ---
        // The dropdown closes itself on selection (closeOnSelect: true),
        // while tapping an item opens the nested context menu at that
        // item's location -- so at this point the context menu should be
        // showing on its own, proving the nested trigger worked and did
        // not corrupt overlay state.
        expect(
          find.byKey(const Key('context-menu-popover')),
          findsOneWidget,
          reason: 'Selecting a dropdown item should open a nested context '
              'menu',
        );
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Rename'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // --- Step 4: dismiss the remaining popover and verify removal ---
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('context-menu-popover')), findsNothing);
        expect(find.byKey(const Key('dropdown-popover')), findsNothing);
        expect(find.text('Status: Nested context menu item "Rename" '
            'selected'), findsOneWidget);
      },
    );

    testWidgets('dropdown and nested context menu can both be visible '
        'simultaneously and dismiss independently', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dropdown-popover')), findsOneWidget);

      // Open the tooltip too, to prove multiple independent popovers can
      // be active at once without the controller confusing their ids.
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown-popover')), findsOneWidget);
      expect(find.byKey(const Key('tooltip-popover')), findsOneWidget);

      // Dismiss the tooltip only; dropdown should remain untouched.
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tooltip-popover')), findsNothing);
      expect(find.byKey(const Key('dropdown-popover')), findsOneWidget);
    });
  });
}
