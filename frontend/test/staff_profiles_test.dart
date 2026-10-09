import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';
import 'package:ubs_saude/services/api_service.dart';

AdminAppointment fakeAppointment(String status,
        {String? risk,
        String? riskLabel,
        String patient = 'Paciente Fictício'}) =>
    AdminAppointment.fromJson({
      'id': 22,
      'scheduled_at': DateTime.now()
          .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0)
          .toIso8601String(),
      'patient': patient,
      'patient_document': '***.***.***-25',
      'specialty': 'Clínica Geral',
      'professional': 'Profissional Fictício',
      'professional_id': 2,
      'status': status,
      'legal_priority': 'geral',
      'priority_reason': 'Sem prioridade legal',
      'risk_classification': risk,
      'risk_label': riskLabel,
      'arrived_at':
          status == 'agendado' ? null : DateTime.now().toIso8601String(),
    });

class FakeStaffApi extends ApiService {
  FakeStaffApi(this.professional, {this.patientName = 'Paciente Fictício'});
  final bool professional;
  final String patientName;
  int checkIns = 0;
  int classifications = 0;
  int calls = 0;
  Completer<void>? nextReceptionRequest;
  DateTime? lastDay;
  String? lastSpecialty, lastStatus, lastRisk, lastPatient;
  int? lastProfessionalId;

  @override
  Future<Map<String, dynamic>> receptionSummary([DateTime? day]) async => {
        'scheduled': 1,
        'checked_in': 2,
        'in_care': 3,
        'completed': 4,
        'absent': 5,
      };

  @override
  Future<List<AdminAppointment>> receptionAppointments(
      {DateTime? day,
      String? specialty,
      int? professionalId,
      String? status,
      String? patient}) async {
    final pending = nextReceptionRequest;
    nextReceptionRequest = null;
    lastDay = day;
    lastSpecialty = specialty;
    lastProfessionalId = professionalId;
    lastStatus = status;
    lastPatient = patient;
    if (pending != null) await pending.future;
    if (specialty != null ||
        professionalId != null ||
        status != null ||
        (patient?.isNotEmpty ?? false)) {
      return [];
    }
    return [fakeAppointment('agendado', patient: patientName)];
  }

  @override
  Future<Map<String, dynamic>> nursingSummary([DateTime? day]) async => {
        'awaiting_triage': 1,
        'in_care': 2,
        'completed': 3,
        'risk_counts': {
          'muito_alto': 1,
          'alto': 2,
          'medio': 3,
          'baixo': 4,
        }
      };

  @override
  Future<List<AdminAppointment>> nursingQueue(
      {DateTime? day, String? specialty, String? status, String? risk}) async {
    lastDay = day;
    lastSpecialty = specialty;
    lastStatus = status;
    lastRisk = risk;
    if (specialty != null || status != null || risk != null) return [];
    return [
      fakeAppointment('em_espera',
          risk: 'baixo', riskLabel: 'Baixo', patient: patientName)
    ];
  }

  @override
  Future<List<AdminAppointment>> professionalQueue([DateTime? day]) async => [
        fakeAppointment('em_triagem',
            risk: 'baixo', riskLabel: 'Baixo', patient: patientName)
      ];

  @override
  Future<void> receptionCheckIn(int id) async {
    checkIns++;
  }

  @override
  Future<void> receptionAbsence(int id) async {}

  @override
  Future<void> classifyRisk(int id, String level, String complaint,
      String vitalSigns, String? observation) async {
    classifications++;
  }

  @override
  Future<void> startCare(int id) async {}

  @override
  Future<void> completeCare(int id) async {}

  @override
  Future<Map<String, dynamic>> receptionDetails(int id) async => _details();

  @override
  Future<Map<String, dynamic>> nursingDetails(int id) async => _details();

  @override
  Future<Map<String, dynamic>> professionalDetails(int id) async => _details();

  @override
  Future<void> callPatient(int id) async {
    calls++;
  }

  Map<String, dynamic> _details() => {
        'id': 22,
        'patient': 'Paciente Fictício',
        'patient_document': '***.***.***-25',
        'specialty': 'Clínica Geral',
        'professional': 'Profissional Fictício',
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': professional ? 'em_espera' : 'agendado',
        'arrived_at': professional ? DateTime.now().toIso8601String() : null,
      };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    accessibility.setContrast(false);
    accessibility.setFontScale(1);
  });

  tearDown(() {
    ApiService.session = null;
    accessibility.setContrast(false);
    accessibility.setFontScale(1);
  });

  testWidgets('reception_wide_uses_filter_and_results_regions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester
        .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(false))));
    await tester.pumpAndSettle();
    expect(find.byType(ResponsiveAppShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('staff-filter-region')), findsOneWidget);
    expect(find.byKey(const Key('staff-results-region')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reception_compact_collapses_filters_without_hiding_checkin',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester
        .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(false))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staff-compact-filters')), findsOneWidget);
    expect(find.text('Check-in'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'detalhes fica à direita e dados essenciais são legíveis em 390 768 1280',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    for (final width in [390.0, 768.0, 1280.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester
          .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(false))));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('staff-appointment-card-22'));
      final details = find.byKey(const Key('staff-details-button-22'));
      final cardRect = tester.getRect(card);
      final detailsRect = tester.getRect(details);
      final patient = tester.widget<Text>(find.text('Paciente Fictício'));
      final schedule = tester.widget<Text>(find.textContaining('Horário:'));

      expect(detailsRect.center.dx, greaterThan(cardRect.center.dx),
          reason: 'largura $width');
      expect(detailsRect.right, lessThanOrEqualTo(cardRect.right),
          reason: 'largura $width');
      expect(cardRect.right - detailsRect.right, lessThanOrEqualTo(20),
          reason: 'o botão deve ficar no extremo direito em $width');
      expect(detailsRect.height, greaterThanOrEqualTo(48),
          reason: 'largura $width');
      expect(patient.style?.fontSize, greaterThanOrEqualTo(20),
          reason: 'largura $width');
      expect(schedule.style?.fontSize, greaterThanOrEqualTo(18),
          reason: 'largura $width');
      expect(find.text('Especialidade: Clínica Geral'), findsOneWidget);
      expect(find.text('Profissional: Profissional Fictício'), findsOneWidget);
      expect(find.text('Prioridade: Sem prioridade legal'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'largura $width');
    }
  });

  testWidgets('empty_reception_can_clear_filters_without_changing_day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(false);
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();
    final originalDay = api.lastDay;

    await tester.enterText(find.byKey(const Key('staff-search')), 'Ninguém');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum atendimento encontrado'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(api.lastSpecialty, isNull);
    expect(api.lastProfessionalId, isNull);
    expect(api.lastStatus, isNull);
    expect(api.lastRisk, isNull);
    expect(api.lastPatient, isEmpty);
    expect(showOnlyDate(api.lastDay!), showOnlyDate(originalDay!));
    expect(find.text('Paciente Fictício'), findsOneWidget);
  });

  testWidgets('clear_filters_is_disabled_while_request_is_pending',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(false);
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('staff-search')), 'Ninguém');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Limpar filtros'), findsOneWidget);

    final pending = Completer<void>();
    api.nextReceptionRequest = pending;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Atualizar'));
    await tester.pump();
    expect(find.text('Limpar filtros'), findsNothing);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Limpar filtros'), findsOneWidget);
    expect(api.lastPatient, 'Ninguém');

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(api.lastPatient, isEmpty);
    expect(find.text('Paciente Fictício'), findsOneWidget);
  });

  testWidgets('empty_nursing_can_clear_status_and_risk', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(true);
    ApiService.session = const Session(
        'token', 'Enfermagem Fictícia', 'enfermagem', ['triage:write']);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();
    final originalDay = api.lastDay;

    await tester.tap(find.byKey(const Key('staff-filter-risk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alto').last);
    await tester.pumpAndSettle();
    expect(find.text('Nenhum atendimento encontrado'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(api.lastStatus, isNull);
    expect(api.lastRisk, isNull);
    expect(showOnlyDate(api.lastDay!), showOnlyDate(originalDay!));
  });

  testWidgets('long_patient_name_does_not_hide_actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longName =
        'Paciente com nome muito longo da Silva Albuquerque e Nascimento';
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester.pumpWidget(UbsApp(
        home: StaffDashboard(api: FakeStaffApi(false, patientName: longName))));
    await tester.pumpAndSettle();
    expect(find.text(longName), findsOneWidget);
    expect(find.text('Check-in'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('risk_level_has_text_and_semantics_in_high_contrast',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    accessibility.setContrast(true);
    ApiService.session = const Session(
        'token', 'Enfermagem Fictícia', 'enfermagem', ['triage:write']);
    await tester
        .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(true))));
    await tester.pumpAndSettle();
    expect(find.text('Risco baixo'), findsWidgets);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'Nível de risco: Baixo'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clinical_queue_survives_max_text_scale_at_360', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    accessibility.setFontScale(1.3);
    ApiService.session = const Session(
        'token', 'Enfermagem Fictícia', 'enfermagem', ['triage:write']);
    await tester
        .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(true))));
    await tester.pumpAndSettle();
    expect(find.text('Classificar risco'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('professional_actions_remain_in_workflow_order', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ApiService.session = const Session(
        'token', 'Profissional Fictício', 'profissional', ['care:update']);
    await tester
        .pumpWidget(UbsApp(home: StaffDashboard(api: FakeStaffApi(true))));
    await tester.pumpAndSettle();
    expect(find.text('1. Chamar  2. Iniciar  3. Concluir'), findsOneWidget);
    final callY = tester.getTopLeft(find.text('Chamar paciente')).dy;
    final startY = tester.getTopLeft(find.text('Iniciar atendimento')).dy;
    expect(callY, lessThanOrEqualTo(startY));
    expect(tester.takeException(), isNull);
  });

  testWidgets('recepção mostra resumo, filtros e ações próprias',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(false);
    ApiService.session =
        const Session('token', 'Recepção Fictícia', 'recepcao', []);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Painel da Recepção'), findsOneWidget);
    expect(find.text('Agendadas'), findsOneWidget);
    expect(find.text('Não compareceu'), findsWidgets);
    expect(find.byKey(const Key('staff-search')), findsOneWidget);
    expect(find.text('Paciente Fictício'), findsOneWidget);
    expect(find.text('Check-in'), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Check-in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(api.checkIns, 1);
    expect(find.text('Painel da Recepção'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profissional usa somente quatro níveis manuais de risco',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(true);
    ApiService.session = const Session(
        'token', 'Enfermagem Fictícia', 'enfermagem', ['triage:write']);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Painel da Enfermagem'), findsOneWidget);
    expect(find.text('Simulação acadêmica'), findsOneWidget);
    expect(find.text('Aguardando triagem'), findsWidgets);
    expect(find.text('Risco muito alto'), findsOneWidget);
    expect(find.byKey(const Key('staff-search')), findsNothing);

    await tester.ensureVisible(find.text('Classificar risco'));
    await tester.tap(find.text('Classificar risco'));
    await tester.pumpAndSettle();
    expect(find.text('Classificação de risco manual'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('Muito alto'), findsOneWidget);
    expect(find.text('Alto'), findsOneWidget);
    expect(find.text('Médio'), findsOneWidget);
    expect(find.text('Baixo'), findsWidgets);
    expect(find.text('Queixa principal'), findsOneWidget);
    expect(find.text('Sinais vitais aferidos'), findsOneWidget);
    expect(find.textContaining('Diagnóstico'), findsNothing);
    await tester.tap(find.text('Baixo').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('triage-complaint')), 'Queixa fictícia.');
    await tester.enterText(
        find.byKey(const Key('triage-vital-signs')), 'PA fictícia 120/80.');
    await tester.tap(find.text('Salvar classificação'));
    await tester.pumpAndSettle();
    expect(api.classifications, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profissional chama e atende sem classificar risco',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeStaffApi(true);
    ApiService.session = const Session(
        'token', 'Profissional Fictício', 'profissional', ['care:update']);
    await tester.pumpWidget(UbsApp(home: StaffDashboard(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Painel do Profissional de Saúde'), findsOneWidget);
    expect(find.text('Classificar risco'), findsNothing);
    expect(find.text('Chamar paciente'), findsOneWidget);
    await tester.tap(find.text('Chamar paciente'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
    expect(tester.takeException(), isNull);
  });
}
