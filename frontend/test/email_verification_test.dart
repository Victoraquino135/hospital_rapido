import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    accessibility.highContrast = false;
    accessibility.fontSizeScale = 1;
  });

  testWidgets('tela explica verificação e oferece campo e reenvio',
      (tester) async {
    await tester.pumpWidget(const UbsApp(
        home: EmailVerificationPage(
            email: 'paciente@example.com', sendOnOpen: false)));
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.textContaining('paciente@example.com'), findsOneWidget);
    expect(find.byKey(const Key('email-verification-code')), findsOneWidget);
    expect(find.text('Validar código'), findsOneWidget);
    expect(find.text('Reenviar código'), findsOneWidget);
    expect(find.text('Voltar e corrigir o e-mail'), findsOneWidget);
    final resend = tester
        .widget<OutlinedButton>(find.byKey(const Key('resend-email-code')));
    expect(resend.onPressed, isNotNull);
  });

  testWidgets('código incompleto mostra erro acessível sem chamar a rede',
      (tester) async {
    await tester.pumpWidget(const UbsApp(
        home: EmailVerificationPage(
            email: 'paciente@example.com', sendOnOpen: false)));
    await tester.enterText(
        find.byKey(const Key('email-verification-code')), '123');
    await tester.tap(find.text('Validar código'));
    await tester.pump();
    expect(find.text('Digite os 6 números do código.'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Código de verificação de seis dígitos'),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('cadastro com código já enviado inicia espera de reenvio',
      (tester) async {
    await tester.pumpWidget(const UbsApp(
        home: EmailVerificationPage(
            email: 'paciente@example.com',
            sendOnOpen: false,
            initialResendSeconds: 60)));
    await tester.pump();
    expect(find.textContaining('Código enviado'), findsOneWidget);
    expect(find.text('Reenviar código em 60s'), findsOneWidget);
    final resend = tester
        .widget<OutlinedButton>(find.byKey(const Key('resend-email-code')));
    expect(resend.onPressed, isNull);
  });

  testWidgets('alto contraste e fonte ampliada não quebram a tela',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    accessibility.highContrast = true;
    accessibility.fontSizeScale = 1.3;
    await tester.pumpWidget(const UbsApp(
        home: EmailVerificationPage(
            email: 'paciente@example.com', sendOnOpen: false)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.black);
  });
}
