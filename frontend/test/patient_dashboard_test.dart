import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';
import 'package:ubs_saude/services/api_service.dart';

class FakePatientApi extends ApiService {
  FakePatientApi({
    this.hasAppointment = true,
    this.specialtyName = 'Clínica geral',
    this.professionalName = 'Dra. Ana Souza',
  });
  bool hasAppointment;
  final String specialtyName;
  final String professionalName;
  bool offline = false, expired = false;
  int summaryCalls = 0;
  int bookings = 0;
  Completer<void>? bookingCompleter;
  String status = 'agendado';
  late final at = DateTime.now().add(const Duration(days: 3));
  Appointment get item => Appointment.fromJson({
        'id': 12,
        'specialty': specialtyName,
        'professional': professionalName,
        'doctor_id': 8,
        'scheduled_at': at.toIso8601String(),
        'status': status,
      });
  PatientSummary get result => PatientSummary.fromJson({
        'patient': {
          'name': 'Victor Teste',
          'masked_cpf': '***.***.***-25',
          'birth_date': '1990-03-15',
          'email': 'victor@example.test',
          'phone': '11999998888'
        },
        'next_appointment': hasAppointment
            ? {
                'id': 12,
                'specialty': specialtyName,
                'professional': professionalName,
                'doctor_id': 8,
                'scheduled_at': at.toIso8601String(),
                'status': status,
              }
            : null,
      });
  @override
  Future<PatientSummary> summary() async {
    summaryCalls++;
    if (expired) {
      throw const ApiException('Sessão expirada.', statusCode: 401);
    }
    if (offline) {
      throw const ApiException('Sem conexão.');
    }
    return result;
  }

  @override
  Future<List<Appointment>> appointments() async =>
      hasAppointment ? [item] : [];
  @override
  Future<List<Map<String, dynamic>>> specialties() async => [
        {'id': 1, 'name': specialtyName}
      ];
  @override
  Future<List<Map<String, dynamic>>> professionals(String specialty) async => [
        {'id': 8, 'name': professionalName}
      ];
  @override
  Future<List<DateTime>> availableDates(String specialty, int doctorId) async =>
      [at];
  @override
  Future<List<Slot>> availableTimes(
          String specialty, int doctorId, DateTime day) async =>
      [
        Slot.fromJson({
          'doctor_id': 8,
          'doctor_name': professionalName,
          'specialty': specialtyName,
          'scheduled_at': at.toIso8601String()
        })
      ];
  @override
  Future<void> book(Slot slot) async {
    bookings++;
    if (bookingCompleter != null) await bookingCompleter!.future;
    hasAppointment = true;
  }
}

void main() {
  testWidgets('patient_wide_layout_prioritizes_next_appointment',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp(home: PatientDashboard(api: FakePatientApi())));
    await tester.pump();
    expect(find.byType(ResponsiveAppShell), findsOneWidget);
    expect(find.byKey(const Key('wide-navigation-menu-button')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Próxima consulta'), findsOneWidget);
    expect(find.text('Agendar consulta'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient_compact_layout_keeps_booking_action_48px',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: PatientDashboard(api: FakePatientApi(hasAppointment: false))));
    await tester.pump();
    final action =
        find.widgetWithText(AppActionButton, 'Agendar consulta').first;
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long_professional_and_specialty_wrap_without_overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePatientApi(
      specialtyName: 'Clínica médica integrada da família e comunidade',
      professionalName: 'Dra. Ana Carolina de Souza Albuquerque Ferreira',
    );
    await tester.pumpWidget(MaterialApp(home: PatientDashboard(api: api)));
    await tester.pump();
    expect(find.text(api.specialtyName), findsOneWidget);
    expect(find.text(api.professionalName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('max_text_scale_keeps_status_and_action_visible', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    accessibility.fontSizeScale = 1.5;
    addTearDown(() => accessibility.fontSizeScale = 1);
    await tester
        .pumpWidget(MaterialApp(home: PatientDashboard(api: FakePatientApi())));
    await tester.pump();
    expect(find.text('Agendada'), findsWidgets);
    expect(find.text('Agendar consulta'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard mostra paciente, próxima consulta e navegação desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePatientApi();
    await tester.pumpWidget(MaterialApp(home: PatientDashboard(api: api)));
    await tester.pump();
    expect(find.text('Olá, Victor!'), findsOneWidget);
    expect(find.text('Dra. Ana Souza'), findsOneWidget);
    expect(find.text('Minhas consultas'), findsOneWidget);
    await tester.tap(find.text('Acompanhar status'));
    await tester.pump();
    expect(find.text('Atualização automática a cada cinco segundos.'),
        findsOneWidget);
    api.status = 'em_espera';
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Check-in realizado'), findsWidgets);
    expect(api.summaryCalls, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard mobile sem consulta abre agendamento', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    accessibility.fontSizeScale = 1.3;
    addTearDown(() => accessibility.fontSizeScale = 1);
    await tester.pumpWidget(MaterialApp(
        home: PatientDashboard(api: FakePatientApi(hasAppointment: false))));
    await tester.pump();
    expect(find.text('Você não possui consultas agendadas.'), findsOneWidget);
    expect(find.text('Consultas'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    await tester.tap(find.text('Agendar consulta').first);
    await tester.pumpAndSettle();
    expect(find.text('Especialidade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agendamento confirma após resposta e atualiza painel',
      (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePatientApi(hasAppointment: false);
    await tester.pumpWidget(MaterialApp(home: PatientDashboard(api: api)));
    await tester.pump();
    await tester.tap(find.text('Agendar consulta').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clínica geral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dra. Ana Souza').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<DateTime>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('/').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();
    expect(api.bookings, 0);
    expect(find.text('Resumo'), findsOneWidget);
    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();
    expect(api.bookings, 1);
    expect(find.text('Dra. Ana Souza'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking_submits_once_while_request_is_pending', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePatientApi(hasAppointment: false)
      ..bookingCompleter = Completer<void>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BookingPanel(api: api, old: null, onChanged: () {}))));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clínica geral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dra. Ana Souza').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<DateTime>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('/').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    final confirm = find.text('Confirmar agendamento');
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();
    expect(api.bookings, 1);
    expect(find.byType(AppActionButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    api.bookingCompleter!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erro de conexão permite tentar novamente', (tester) async {
    final api = FakePatientApi()..offline = true;
    await tester.pumpWidget(MaterialApp(home: PatientDashboard(api: api)));
    await tester.pump();
    expect(find.text('Sem conexão.'), findsOneWidget);
    api.offline = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(find.text('Olá, Victor!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sessão expirada retorna ao login', (tester) async {
    final api = FakePatientApi()..expired = true;
    await tester.pumpWidget(MaterialApp(home: PatientDashboard(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.byType(PatientDashboard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
