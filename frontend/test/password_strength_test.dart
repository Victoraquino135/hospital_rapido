import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubs_saude/main.dart';

void main() {
  test('password_strength_has_three_levels', () {
    expect(passwordStrength('abc'), PasswordStrength.weak);
    expect(passwordStrength('Paciente1'), PasswordStrength.medium);
    expect(passwordStrength('Paciente@123'), PasswordStrength.strong);
  });

  testWidgets('empty_password_has_neutral_guidance', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PasswordStrengthIndicator(password: '')),
    ));

    expect(find.textContaining('8+ caracteres'), findsOneWidget);
    expect(find.text('Fraca'), findsNothing);
    expect(find.text('Média'), findsNothing);
    expect(find.text('Forte'), findsNothing);
  });

  testWidgets('indicator_exposes_text_and_semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PasswordStrengthIndicator(password: 'Paciente@123'),
      ),
    ));

    expect(find.text('Forte'), findsOneWidget);
    expect(find.bySemanticsLabel('Força da senha: Forte'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    semantics.dispose();
  });
}
