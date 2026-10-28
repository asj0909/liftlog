import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/layout/app_shell.dart';
import 'package:liftlog/core/layout/breakpoints.dart';

void main() {
  group('WindowSize.fromWidth', () {
    test('境界値（599 / 600 / 1023 / 1024）', () {
      expect(WindowSize.fromWidth(599), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(1023), WindowSize.medium);
      expect(WindowSize.fromWidth(1024), WindowSize.expanded);
    });
  });

  group('AdaptiveNavigationScaffold', () {
    Future<void> pumpAtWidth(
      WidgetTester tester,
      double width, {
      ValueChanged<int>? onSelected,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNavigationScaffold(
            selectedIndex: 0,
            onDestinationSelected: onSelected ?? (_) {},
            body: const Text('body'),
          ),
        ),
      );
    }

    testWidgets('600px 未満は下部 NavigationBar', (tester) async {
      await pumpAtWidth(tester, 400);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('600px 以上は NavigationRail（ラベル常時表示）', (tester) async {
      await pumpAtWidth(tester, 800);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('1024px 以上は展開された NavigationRail', (tester) async {
      await pumpAtWidth(tester, 1280);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('タブをタップすると index が通知される', (tester) async {
      int? selected;
      await pumpAtWidth(tester, 400, onSelected: (i) => selected = i);
      await tester.tap(find.text('推移'));
      expect(selected, 2);
    });
  });
}
