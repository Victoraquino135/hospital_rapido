import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubs_saude/main.dart';

void main() {
  test('uses_48px_minimum_touch_target', () {
    expect(AppSizes.minTouchTarget, 48);
  });

  test('classifies_699_as_compact_and_700_as_medium', () {
    expect(screenClassForWidth(699), ScreenClass.compact);
    expect(screenClassForWidth(700), ScreenClass.medium);
  });

  test('classifies_1100_as_wide', () {
    expect(screenClassForWidth(1099), ScreenClass.medium);
    expect(screenClassForWidth(1100), ScreenClass.wide);
  });

  testWidgets('primary_button_is_at_least_48px', (tester) async {
    await tester.pumpWidget(UbsApp(
      home: Scaffold(
        body: AppActionButton(
          label: 'Continuar',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ),
    ));

    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48));
  });

  testWidgets('long_empty_state_wraps_at_360px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    accessibility.setFontScale(1.30);
    addTearDown(() => accessibility.setFontScale(1));

    await tester.pumpWidget(const UbsApp(
      home: Scaffold(
        body: AppEmptyState(
          title: 'Sem consultas',
          message:
              'Nenhuma consulta encontrada para este período. Escolha outro dia ou faça um novo agendamento.',
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Nenhuma consulta encontrada'), findsOneWidget);
  });

  testWidgets('empty_state_exposes_optional_action', (tester) async {
    var actions = 0;
    await tester.pumpWidget(UbsApp(
      home: Scaffold(
        body: AppEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'Nenhum resultado',
          message: 'Revise os filtros selecionados.',
          actionLabel: 'Limpar filtros',
          onAction: () => actions++,
        ),
      ),
    ));

    expect(find.text('Nenhum resultado'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    expect(actions, 1);
  });

  testWidgets('status_badge_has_text_semantics_and_contrast', (tester) async {
    final semantics = tester.ensureSemantics();
    accessibility.setContrast(true);
    addTearDown(() => accessibility.setContrast(false));
    await tester.pumpWidget(const UbsApp(
      home: Scaffold(
        body: AppStatusBadge(
          label: 'Em atendimento',
          tone: StatusTone.info,
          semanticLabel: 'Situação: Em atendimento',
        ),
      ),
    ));

    expect(find.text('Em atendimento'), findsOneWidget);
    expect(find.bySemanticsLabel('Situação: Em atendimento'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('high_contrast_surface_uses_border_and_text_label',
      (tester) async {
    accessibility.setContrast(true);
    addTearDown(() => accessibility.setContrast(false));

    await tester.pumpWidget(const UbsApp(
      home: Scaffold(
        body: AppSurfaceCard(child: Text('Risco: urgente')),
      ),
    ));

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.width, greaterThanOrEqualTo(2));
    expect(find.text('Risco: urgente'), findsOneWidget);
  });
}
