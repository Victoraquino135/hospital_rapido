import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';

const destinations = [
  AppDestination(icon: Icons.home_outlined, label: 'Início'),
  AppDestination(icon: Icons.event_outlined, label: 'Consultas'),
];

Future<void> pumpShell(WidgetTester tester, double width,
    {WideNavigationMode mode = WideNavigationMode.persistentRail,
    List<AppDestination> items = destinations,
    ValueChanged<int>? onSelected}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(UbsApp(
    home: ResponsiveAppShell(
      title: 'Visão geral',
      subtitle: 'Acompanhe seu atendimento',
      destinations: items,
      selectedIndex: 0,
      onDestinationSelected: onSelected ?? (_) {},
      wideNavigationMode: mode,
      body: const Text('Conteúdo principal', key: Key('shell-body')),
    ),
  ));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    accessibility.setContrast(false);
    accessibility.setFontScale(1);
  });

  testWidgets('wide_shell_shows_sidebar_once', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpShell(tester, 1280);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('overlay_menu_starts_closed_and_closes_after_selection',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    await pumpShell(tester, 1280,
        mode: WideNavigationMode.overlayDrawer,
        onSelected: (value) => selected = value);

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('wide-navigation-menu-button')), findsOneWidget);
    expect(find.byKey(const Key('wide-navigation-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('wide-navigation-menu-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wide-navigation-panel')), findsOneWidget);
    await tester.tap(find.text('Consultas').last);
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(find.byKey(const Key('wide-navigation-panel')), findsNothing);
  });

  testWidgets('overlay_menu_dismissal_never_changes_destination',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    await pumpShell(tester, 1280,
        mode: WideNavigationMode.overlayDrawer,
        onSelected: (value) => selected = value);

    await tester.tap(find.byKey(const Key('wide-navigation-menu-button')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(selected, -1);
    expect(find.byKey(const Key('wide-navigation-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('wide-navigation-menu-button')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1270, 400));
    await tester.pumpAndSettle();
    expect(selected, -1);
    expect(find.byKey(const Key('wide-navigation-panel')), findsNothing);
  });

  testWidgets('content_only_and_empty_destinations_use_full_width',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpShell(tester, 1280, mode: WideNavigationMode.contentOnly);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('shell-body'))).dx,
        lessThan(100));

    await pumpShell(tester, 1280, items: const []);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('shell-body'))).dx,
        lessThan(100));
  });

  testWidgets('compact_shell_shows_compact_navigation_once', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpShell(tester, 360);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('brand_mark_is_present_on_both_widths', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [360.0, 1280.0]) {
      await pumpShell(tester, width);
      expect(find.bySemanticsLabel('UBS Rápida, saúde perto de você'),
          findsOneWidget);
    }
  });

  testWidgets('accessibility_button_is_top_right_on_windows', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpShell(tester, 1280);

    final button =
        find.widgetWithText(FilledButton, 'Preferências de acessibilidade');
    expect(button, findsOneWidget);
    final rect = tester.getRect(button);
    expect(rect.right, greaterThan(1000));
    expect(rect.top, lessThan(80));
  });

  testWidgets('shell_keeps_navigation_at_699_700_1099_1100', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [699.0, 700.0, 1099.0, 1100.0]) {
      await pumpShell(tester, width);
      final navigationCount = find.byType(NavigationRail).evaluate().length +
          find.byType(NavigationBar).evaluate().length;
      expect(navigationCount, 1, reason: 'largura $width');
      expect(find.byType(AccessibilityMenu), findsOneWidget,
          reason: 'largura $width');
    }
  });
}
