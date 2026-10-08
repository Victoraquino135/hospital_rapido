import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';

Slot slot({bool selectable = true, String label = 'Disponível'}) =>
    Slot.fromJson({
      'doctor_id': 1,
      'doctor_name': 'Dra. Ana',
      'specialty': 'Pediatria',
      'scheduled_at': '2026-10-12T15:00:00',
      'availability': selectable ? 'available' : 'unavailable',
      'label': label,
      'selectable': selectable,
    });

Future<void> pumpCard(
  WidgetTester tester, {
  required Slot value,
  bool selected = false,
  VoidCallback? onPressed,
}) =>
    tester.pumpWidget(UbsApp(
      home: Scaffold(
        body: AvailabilitySlotCard(
          slot: value,
          selected: selected,
          onPressed: onPressed,
        ),
      ),
    ));

void main() {
  testWidgets('available_slot_is_actionable', (tester) async {
    var taps = 0;
    await pumpCard(tester, value: slot(), onPressed: () => taps++);

    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(48));

    await tester.tap(find.byType(AvailabilitySlotCard));
    expect(taps, 1);
  });

  testWidgets('unavailable_slot_never_invokes_callback', (tester) async {
    var taps = 0;
    await pumpCard(
      tester,
      value: slot(selectable: false, label: 'Indisponível'),
      onPressed: () => taps++,
    );

    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
    await tester.tap(find.byType(AvailabilitySlotCard));
    expect(taps, 0);
  });

  testWidgets('selected_slot_has_check_and_semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(tester, value: slot(), selected: true, onPressed: () {});

    expect(find.text('Selecionado'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(
      find.bySemanticsLabel('15:00, Selecionado'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('slot_states_survive_high_contrast', (tester) async {
    accessibility.setContrast(true);
    addTearDown(() => accessibility.setContrast(false));

    await pumpCard(
      tester,
      value: slot(selectable: false, label: 'Indisponível'),
      onPressed: () {},
    );

    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
}
