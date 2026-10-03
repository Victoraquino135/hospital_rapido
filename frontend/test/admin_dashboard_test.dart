import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ubs_saude/main.dart';
import 'package:ubs_saude/models/api_models.dart';
import 'package:ubs_saude/services/api_service.dart';

class FakeAdminApi extends ApiService {
  @override
  Future<AdminSummary> adminSummary([DateTime? day]) async =>
      AdminSummary.fromJson({
        'scheduled': 4,
        'checked_in': 2,
        'waiting': 2,
        'in_care': 1,
        'completed': 3,
        'cancelled': 1,
      });

  @override
  Future<List<InternalUser>> internalUsers(
          {String? search, String? role, bool? active}) async =>
      [];

  @override
  Future<List<AdminAppointment>> adminAppointments(
          {DateTime? day,
          String? specialty,
          int? professionalId,
          String? status,
          String? patient}) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> queue() async => [];

  @override
  Future<List<Map<String, dynamic>>> specialties() async => [];

  @override
  Future<List<Map<String, dynamic>>> adminSpecialties() async => [];

  @override
  Future<List<Map<String, dynamic>>> allProfessionals() async => [];

  @override
  Future<List<Map<String, dynamic>>> auditHistory() async => [];

  @override
  Future<List<Map<String, dynamic>>> grids() async => [];
}

class FakeAgendaApi extends FakeAdminApi {
  final agendaItem = AdminAppointment.fromJson({
    'id': 10,
    'scheduled_at': '2026-09-25T08:00:00',
    'patient': 'Paciente Fictício',
    'patient_document': '***.***.***-25',
    'specialty': 'Clínica geral',
    'professional': 'Dra. Ana',
    'professional_id': 2,
    'status': 'agendado',
    'legal_priority': 'geral',
  });

  @override
  Future<List<AdminAppointment>> adminAppointments(
          {DateTime? day,
          String? specialty,
          int? professionalId,
          String? status,
          String? patient}) async =>
      [agendaItem];

  @override
  Future<Map<String, dynamic>> adminAppointmentDetails(int id) async => {
        'id': id,
        'scheduled_at': '2026-09-25T08:00:00',
        'patient': 'Paciente Fictício',
        'patient_document': '***.***.***-25',
        'specialty': 'Clínica geral',
        'professional': 'Dra. Ana',
        'status': 'agendado',
        'legal_priority': 'geral',
        'risk_classification': null,
      };
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    accessibility.setContrast(false);
    accessibility.setFontScale(1);
    ApiService.session = const Session('token-ficticio', 'Ana Administradora',
        'admin', ['users:manage', 'appointments:checkin']);
  });

  tearDown(() {
    ApiService.session = null;
    accessibility.setContrast(false);
    accessibility.setFontScale(1);
  });

  testWidgets('painel administrativo mostra resumo real e menu responsivo',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UbsApp(home: AdminDashboard(api: FakeAdminApi())));
    await tester.pumpAndSettle();
    expect(find.text('Painel Administrativo • Administrador'), findsOneWidget);
    expect(find.text('Consultas agendadas'), findsOneWidget);
    expect(find.text('Usuários internos'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('painel administrativo suporta A+ e alto contraste no celular',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UbsApp(home: AdminDashboard(api: FakeAdminApi())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preferências de acessibilidade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A+'));
    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();
    expect(accessibility.fontSizeScale, greaterThan(1));
    expect(accessibility.highContrast, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('direcionamento reconhece os quatro perfis', () {
    ApiService.session =
        const Session('t', 'Paciente Fictício', 'paciente', []);
    expect(homeForRole(), isA<PatientDashboard>());
    ApiService.session = const Session('t', 'Admin Fictício', 'admin', []);
    expect(homeForRole(), isA<AdminDashboard>());
    ApiService.session =
        const Session('t', 'Recepção Fictícia', 'recepcao', []);
    expect(homeForRole(), isA<StaffDashboard>());
    ApiService.session =
        const Session('t', 'Profissional Fictício', 'profissional', []);
    expect(homeForRole(), isA<StaffDashboard>());
  });

  testWidgets('ver detalhes abre modal e mantém o painel aberto',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UbsApp(home: AdminDashboard(api: FakeAgendaApi())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agenda do dia'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Detalhes da consulta'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Painel Administrativo • Administrador'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
