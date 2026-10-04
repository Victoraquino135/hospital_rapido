import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';
import 'package:ubs_saude/services/api_service.dart';

AdminAppointment fakeAppointment(String status,
        {String? risk, String? riskLabel}) =>
    AdminAppointment.fromJson({
      'id': 22,
      'scheduled_at': DateTime.now()
          .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0)
          .toIso8601String(),
      'patient': 'Paciente Fictício',
      'patient_document': '***.***.***-25',
      'specialty': 'Clínica Geral',
      'professional': 'Profissional Fictício',
      'professional_id': 2,
      'status': status,
      'legal_priority': 'geral',
      'risk_classification': risk,
      'risk_label': riskLabel,
      'arrived_at':
          status == 'agendado' ? null : DateTime.now().toIso8601String(),
    });

class FakeStaffApi extends ApiService {
  FakeStaffApi(this.professional);
  final bool professional;
  int checkIns = 0;
  int classifications = 0;
  int calls = 0;

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
          String? patient}) async =>
      [fakeAppointment('agendado')];

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
          {DateTime? day,
          String? specialty,
          String? status,
          String? risk}) async =>
      [fakeAppointment('em_espera')];

  @override
  Future<List<AdminAppointment>> professionalQueue([DateTime? day]) async =>
      [fakeAppointment('em_triagem', risk: 'baixo', riskLabel: 'Baixo')];

  @override
  Future<void> receptionCheckIn(int id) async {
    checkIns++;
  }

  @override
  Future<void> receptionAbsence(int id) async {}

  @override
  Future<void> classifyRisk(int id, String level, String? observation) async {
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
    expect(find.textContaining('Sinais vitais'), findsNothing);
    expect(find.textContaining('Diagnóstico'), findsNothing);
    await tester.tap(find.text('Baixo').last);
    await tester.pumpAndSettle();
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
