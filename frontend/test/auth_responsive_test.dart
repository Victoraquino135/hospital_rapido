import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';
import 'package:ubs_saude/services/api_service.dart';

class PendingLoginApi extends ApiService {
  int loginCalls = 0;
  final completion = Completer<Session>();

  @override
  Future<Session> login(String document, String password) {
    loginCalls++;
    return completion.future;
  }
}

Future<void> setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    accessibility.highContrast = false;
    accessibility.fontSizeScale = 1;
    ApiService.session = null;
  });

  tearDown(() {
    accessibility.highContrast = false;
    accessibility.fontSizeScale = 1;
  });

  testWidgets('login_matches_compact_and_wide_hierarchy', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(360, 800), const Size(1280, 900)]) {
      await setViewport(tester, size);
      await tester.pumpWidget(const UbsApp(home: LoginPage()));
      expect(find.bySemanticsLabel('UBS Rápida, saúde perto de você'),
          findsOneWidget);
      expect(find.text('Acesse sua conta'), findsOneWidget);
      expect(find.byType(AppActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('registration_wraps_at_360_with_max_text_scale',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await setViewport(tester, const Size(360, 800));
    accessibility.fontSizeScale = 1.30;
    await tester.pumpWidget(const UbsApp(home: RegisterPage()));
    await tester.pump();

    expect(find.text('Criar conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovery_keeps_primary_action_visible', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await setViewport(tester, const Size(360, 800));
    await tester.pumpWidget(const UbsApp(home: RecoveryPage()));

    final action = find.byType(AppActionButton);
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('email_verification_keeps_code_semantics', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await setViewport(tester, const Size(360, 800));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const UbsApp(
      home: EmailVerificationPage(
        email: 'maria@example.com',
        sendOnOpen: false,
      ),
    ));

    expect(find.bySemanticsLabel('Código de verificação de seis dígitos'),
        findsOneWidget);
    expect(find.byType(AppActionButton), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('login_disables_only_submit_while_request_is_pending',
      (tester) async {
    final api = PendingLoginApi();
    await tester.pumpWidget(UbsApp(home: LoginPage(api: api)));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '52998224725');
    await tester.enterText(fields.at(1), 'Paciente@123');
    final submit = find.text('Entrar →');
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(api.loginCalls, 1);
    expect(fields, findsNWidgets(2));
    expect(find.text('Aguarde…'), findsOneWidget);

    api.completion.completeError(const ApiException('Falha controlada.'));
    await tester.pump();
  });
}
