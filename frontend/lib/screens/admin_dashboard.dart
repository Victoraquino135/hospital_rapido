part of '../main.dart';

enum AdminSection {
  overview('Visão geral', Icons.dashboard_outlined),
  agenda('Agenda do dia', Icons.today_outlined),
  appointments('Agendamentos', Icons.event_note_outlined),
  checkin('Confirmar chegada', Icons.how_to_reg_outlined),
  queue('Fila de atendimento', Icons.groups_outlined),
  grids('Grades e horários', Icons.calendar_month_outlined),
  specialties('Especialidades', Icons.medical_information_outlined),
  professionals('Profissionais', Icons.medical_services_outlined),
  doctors('Médicos', Icons.health_and_safety_outlined),
  users('Usuários internos', Icons.manage_accounts_outlined),
  history('Histórico', Icons.history_outlined),
  settings('Configurações', Icons.settings_outlined);

  const AdminSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.api});
  final ApiService? api;
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final ApiService api = widget.api ?? ApiService();
  AdminSection section = AdminSection.overview;
  AdminSummary? summary;
  List<AdminAppointment> appointments = [];
  List<InternalUser> users = [];
  List<DoctorAccount> doctors = [];
  List<Map<String, dynamic>> specialties = [],
      professionals = [],
      queue = [],
      audit = [],
      grids = [];
  bool loading = true;
  String? error;
  Timer? refreshTimer;
  final specialtySearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (section == AdminSection.queue && !loading) _refreshQueue();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    specialtySearch.dispose();
    super.dispose();
  }

  Future<void> _refreshQueue() async {
    try {
      final latest = await api.queue();
      if (mounted && section == AdminSection.queue) {
        setState(() => queue = latest);
      }
    } on ApiException catch (_) {}
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      switch (section) {
        case AdminSection.overview:
          summary = await api.adminSummary();
        case AdminSection.agenda:
        case AdminSection.appointments:
        case AdminSection.checkin:
          final values = await Future.wait([
            api.adminAppointments(),
            api.adminSpecialties(),
            api.allProfessionals()
          ]);
          appointments = values[0] as List<AdminAppointment>;
          specialties = values[1] as List<Map<String, dynamic>>;
          professionals = values[2] as List<Map<String, dynamic>>;
        case AdminSection.queue:
          queue = await api.queue();
        case AdminSection.users:
        case AdminSection.professionals:
          users = await api.internalUsers(
              role: section == AdminSection.professionals ? 'medico' : null);
          specialties = await api.adminSpecialties();
        case AdminSection.doctors:
          doctors = await api.doctors();
        case AdminSection.specialties:
          specialties = await api.adminSpecialties();
        case AdminSection.grids:
          final values =
              await Future.wait([api.grids(), api.adminSpecialties()]);
          grids = values[0];
          specialties = values[1];
        case AdminSection.history:
          audit = await api.auditHistory();
        case AdminSection.settings:
          break;
      }
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void select(AdminSection value) {
    setState(() => section = value);
    load();
  }

  Future<void> logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => ResponsiveAppShell(
      title: 'Painel Administrativo • Administrador',
      subtitle: ApiService.session?.name ?? 'Administrador',
      destinations: [
        for (final item in AdminSection.values)
          AppDestination(icon: item.icon, label: item.label)
      ],
      selectedIndex: AdminSection.values.indexOf(section),
      onDestinationSelected: (index) => select(AdminSection.values[index]),
      primaryAction: Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar')),
        OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sair')),
      ]),
      body: Card(
          key: const Key('admin-module-content'),
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _content())));

  Widget _content() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'))
      ]));
    }
    return switch (section) {
      AdminSection.overview => _overview(),
      AdminSection.agenda ||
      AdminSection.appointments ||
      AdminSection.checkin =>
        _agenda(),
      AdminSection.queue => _queue(),
      AdminSection.grids => _grids(),
      AdminSection.specialties => _specialties(),
      AdminSection.doctors => _doctors(),
      AdminSection.professionals || AdminSection.users => _users(),
      AdminSection.history => _history(),
      AdminSection.settings => _settings(),
    };
  }

  Widget _title(String title, String subtitle, {Widget? action}) =>
      ResponsivePageHeader(
          title: title, subtitle: subtitle, primaryAction: action);

  Widget _overview() {
    final s = summary!;
    final cards = [
      ('Consultas agendadas', s.scheduled, Icons.event_available, blue),
      ('Chegadas confirmadas', s.checkedIn, Icons.how_to_reg, green),
      (
        'Pacientes aguardando',
        s.waiting,
        Icons.groups,
        const Color(0xFF9A6700)
      ),
      (
        'Em atendimento',
        s.inCare,
        Icons.monitor_heart_outlined,
        const Color(0xFF7A4CE0)
      ),
      ('Concluídos', s.completed, Icons.task_alt, green),
      ('Canceladas', s.cancelled, Icons.event_busy, const Color(0xFFB42318)),
      ('Faltas', s.absent, Icons.person_off_outlined, const Color(0xFFB42318)),
      ('Vagas disponíveis', s.available, Icons.event_seat_outlined, green),
    ];
    return ListView(children: [
      _title('Visão geral', 'Indicadores reais das consultas de hoje.'),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (_, c) {
        final width = c.maxWidth >= 900
            ? (c.maxWidth - 32) / 3
            : c.maxWidth >= 560
                ? (c.maxWidth - 16) / 2
                : c.maxWidth;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final item in cards)
            SizedBox(
                width: width,
                child: _metric(item.$1, item.$2, item.$3, item.$4))
        ]);
      }),
      const SizedBox(height: 22),
      InfoPanel(
          icon: Icons.verified_user_outlined,
          text:
              'As ações administrativas são validadas no servidor e registradas no histórico sem senhas, hashes ou CPF completo.')
    ]);
  }

  Widget _metric(String label, int value, IconData icon, Color color) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: accessibility.highContrast
                    ? Colors.yellow
                    : color.withValues(alpha: .12),
                child: Icon(icon,
                    color: accessibility.highContrast ? Colors.black : color)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('$value',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900)),
                  Text(label)
                ]))
          ])));

  Widget _agenda() => _AgendaAdminView(
      api: api,
      initial: appointments,
      specialties: specialties,
      professionals: professionals,
      checkinOnly: section == AdminSection.checkin,
      onChanged: load);

  Widget _queue() => ListView(children: [
        _title('Fila de atendimento',
            'Ordenada pelo backend por risco, prioridade legal e chegada.'),
        const SizedBox(height: 16),
        if (queue.isEmpty)
          const _EmptyState('Nenhum paciente aguardando atendimento.'),
        for (final item in queue)
          Card(
              child: ListTile(
            leading: CircleAvatar(child: Text('${item['position'] ?? '-'}')),
            title: Text(item['patient']?.toString() ?? 'Paciente'),
            subtitle: Text(
                '${item['specialty']} • ${item['professional']}\nChegada: ${item['arrived_at'] == null ? '-' : item['arrived_at'].toString().substring(11, 16)} • Prioridade: ${item['legal_priority'] ?? 'geral'} • Risco: ${item['risk_classification'] ?? 'não classificado'}'),
            isThreeLine: true,
            trailing: Text(statusLabel(item['status']?.toString() ?? '')),
          ))
      ]);

  Widget _users() => _InternalUsersView(
      api: api,
      initial: users,
      specialties: specialties,
      professionalOnly: section == AdminSection.professionals,
      onChanged: load);

  Widget _doctors() =>
      _DoctorsView(api: api, initial: doctors, onChanged: load);

  Widget _specialties() {
    final query = specialtySearch.text.trim().toLowerCase();
    final filtered = specialties
        .where((item) => item['name'].toString().toLowerCase().contains(query))
        .toList();
    return ListView(children: [
      _title('Especialidades',
          'Cadastre, edite e controle quais especialidades estão disponíveis para novos agendamentos.',
          action: FilledButton.icon(
              key: const Key('new-specialty-button'),
              onPressed: _openSpecialtyForm,
              icon: const Icon(Icons.add),
              label: const Text('Nova especialidade'))),
      const SizedBox(height: 16),
      TextField(
          key: const Key('specialty-search-field'),
          controller: specialtySearch,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Pesquisar especialidades',
              hintText: 'Digite o nome da especialidade',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.manage_search))),
      const SizedBox(height: 16),
      if (specialties.isEmpty)
        const _EmptyState('Nenhuma especialidade cadastrada.')
      else if (filtered.isEmpty)
        const _EmptyState('Nenhuma especialidade encontrada.')
      else
        for (final item in filtered) ...[
          _specialtyCard(item),
          const SizedBox(height: 12)
        ]
    ]);
  }

  Widget _specialtyCard(Map<String, dynamic> item) {
    final active = item['active'] as bool? ?? true;
    final details = Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(active ? Icons.check_circle_outline : Icons.block_outlined,
          size: 20,
          color: active ? green : Theme.of(context).colorScheme.error),
      const SizedBox(width: 8),
      Text(active ? 'Ativa' : 'Inativa', style: const TextStyle(fontSize: 16))
    ]);
    final actions = Wrap(spacing: 8, runSpacing: 8, children: [
      OutlinedButton.icon(
          key: Key('edit-specialty-${item['id']}'),
          onPressed: () => _openSpecialtyForm(item),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar')),
      OutlinedButton.icon(
          key: Key('toggle-specialty-${item['id']}'),
          onPressed: () => _toggleSpecialty(item),
          icon:
              Icon(active ? Icons.block_outlined : Icons.check_circle_outline),
          label: Text(active ? 'Desativar' : 'Ativar'))
    ]);
    return Semantics(
        container: true,
        label: 'Especialidade ${item['name']}, ${active ? 'ativa' : 'inativa'}',
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: LayoutBuilder(builder: (context, constraints) {
                  final information = Row(children: [
                    const Icon(Icons.medical_information_outlined, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item['name'].toString(),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2),
                          const SizedBox(height: 6),
                          details
                        ]))
                  ]);
                  if (constraints.maxWidth < 620) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          information,
                          const SizedBox(height: 12),
                          Align(
                              alignment: Alignment.centerRight, child: actions)
                        ]);
                  }
                  return Row(children: [
                    Expanded(child: information),
                    const SizedBox(width: 16),
                    actions
                  ]);
                }))));
  }

  Future<void> _openSpecialtyForm([Map<String, dynamic>? existing]) async {
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _SpecialtyFormDialog(api: api, existing: existing));
    if (saved == true) {
      await load();
      if (mounted) {
        notice(
            context,
            existing == null
                ? 'Especialidade criada com sucesso.'
                : 'Especialidade atualizada com sucesso.');
      }
    }
  }

  Future<void> _toggleSpecialty(Map<String, dynamic> item) async {
    final active = item['active'] as bool? ?? true;
    try {
      await api.setSpecialtyActive(item['id'] as int, !active);
      await load();
      if (mounted) {
        notice(context,
            active ? 'Especialidade desativada.' : 'Especialidade ativada.');
      }
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  Widget _grids() => _GridAdminView(
      api: api, grids: grids, specialties: specialties, onChanged: load);

  Widget _history() => ListView(children: [
        _title('Histórico e auditoria',
            'Ações administrativas registradas sem informações sensíveis.'),
        const SizedBox(height: 16),
        if (audit.isEmpty)
          const _EmptyState('Nenhuma ação administrativa registrada.'),
        for (final item in audit)
          Semantics(
              container: true,
              label: 'Registro de auditoria: ${item['action']}',
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final content = Row(
                            key: const Key('audit-content'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.history),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(item['action']
                                        .toString()
                                        .replaceAll('_', ' ')),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${item['actor']} • ${item['record_type']} #${item['record_id'] ?? '-'}')
                                  ]))
                            ]);
                        final metadata = _AuditMetadata(
                            createdAt: item['created_at'].toString());
                        final compact = constraints.maxWidth < 620 ||
                            MediaQuery.textScalerOf(context).scale(16) > 18;
                        if (compact) {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                content,
                                const SizedBox(height: 12),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: metadata)
                              ]);
                        }
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: content),
                              const SizedBox(width: 20),
                              metadata
                            ]);
                      }))))
      ]);

  Widget _settings() => ListView(children: [
        _title('Configurações',
            'Preferências do painel e informações de segurança.'),
        const SizedBox(height: 16),
        const InfoPanel(
            icon: Icons.accessibility_new,
            text:
                'Use o menu de acessibilidade para ajustar A−, A, A+ e alto contraste. As preferências permanecem durante a navegação.'),
        const SizedBox(height: 12),
        const InfoPanel(
            icon: Icons.password,
            text:
                'A alteração obrigatória de senha provisória no primeiro acesso ainda não faz parte desta versão. O administrador pode redefinir o acesso com uma nova senha provisória.'),
        const SizedBox(height: 18),
        Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
                onPressed: _createAnotherAdmin,
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Criar outro administrador')))
      ]);

  Future<void> _createAnotherAdmin() async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(),
        cpf = TextEditingController(),
        email = TextEditingController(),
        password = TextEditingController(),
        confirmation = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Criar outro administrador'),
                content: SizedBox(
                    width: 520,
                    child: Form(
                        key: form,
                        child: SingleChildScrollView(
                            child: Column(children: [
                          field(name, 'Nome completo', Icons.person_outline,
                              validator: requiredName),
                          field(cpf, 'CPF', Icons.badge_outlined,
                              validator: requiredCpf,
                              inputFormatters: [CpfFormatter()],
                              number: true),
                          field(email, 'E-mail', Icons.email_outlined,
                              validator: emailRule),
                          field(
                              password, 'Senha provisória', Icons.lock_outline,
                              validator: passwordRule, secret: true),
                          field(confirmation, 'Confirmação', Icons.lock_reset,
                              validator: (v) => v != password.text
                                  ? 'As senhas não coincidem.'
                                  : null,
                              secret: true)
                        ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(c, true);
                        }
                      },
                      child: const Text('Criar administrador'))
                ]));
    if (accepted == true) {
      try {
        await api.createAdmin({
          'name': name.text.trim(),
          'cpf': digits(cpf.text),
          'email': email.text.trim(),
          'password': password.text,
          'password_confirmation': confirmation.text
        });
        if (mounted) notice(context, 'Administrador criado com segurança.');
      } on ApiException catch (e) {
        if (mounted) notice(context, e.message);
      }
    }
    for (final controller in [name, cpf, email, password, confirmation]) {
      controller.dispose();
    }
  }
}

class _SpecialtyFormDialog extends StatefulWidget {
  const _SpecialtyFormDialog({required this.api, this.existing});

  final ApiService api;
  final Map<String, dynamic>? existing;

  @override
  State<_SpecialtyFormDialog> createState() => _SpecialtyFormDialogState();
}

class _SpecialtyFormDialogState extends State<_SpecialtyFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name =
      TextEditingController(text: widget.existing?['name']?.toString() ?? '');
  bool saving = false;
  String? serverError;

  bool get editing => widget.existing != null;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => serverError = null);
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      if (editing) {
        await widget.api
            .updateSpecialty(widget.existing!['id'] as int, name.text.trim());
      } else {
        await widget.api.createSpecialty(name.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          serverError = error.message;
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(editing ? 'Editar especialidade' : 'Nova especialidade'),
          content: SizedBox(
              width: 480,
              child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(
                        key: const Key('specialty-name-field'),
                        controller: name,
                        autofocus: true,
                        enabled: !saving,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => save(),
                        maxLength: 80,
                        decoration: const InputDecoration(
                            labelText: 'Nome da especialidade',
                            hintText: 'Ex.: Pediatria',
                            prefixIcon:
                                Icon(Icons.medical_information_outlined)),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o nome da especialidade.'
                                : null),
                    if (serverError != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                          liveRegion: true,
                          child: Text(serverError!,
                              key: const Key('specialty-form-error'),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600)))
                    ]
                  ])))),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton.icon(
                key: const Key('save-specialty-button'),
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(editing ? 'Salvar alterações' : 'Salvar'))
          ]);
}

class _AuditMetadata extends StatelessWidget {
  const _AuditMetadata({required this.createdAt});

  final String createdAt;

  @override
  Widget build(BuildContext context) {
    final formatted = createdAt.replaceFirst('T', ' ').substring(0, 16);
    return Column(
        key: const Key('audit-metadata'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(formatted, style: const TextStyle(fontSize: 16))
        ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
          child: Column(children: [
        const Icon(Icons.inbox_outlined, size: 44),
        const SizedBox(height: 12),
        Text(message)
      ])));
}

class _AgendaAdminView extends StatefulWidget {
  const _AgendaAdminView(
      {required this.api,
      required this.initial,
      required this.specialties,
      required this.professionals,
      required this.checkinOnly,
      required this.onChanged});
  final ApiService api;
  final List<AdminAppointment> initial;
  final List<Map<String, dynamic>> specialties, professionals;
  final bool checkinOnly;
  final Future<void> Function() onChanged;
  @override
  State<_AgendaAdminView> createState() => _AgendaAdminViewState();
}

class _AgendaAdminViewState extends State<_AgendaAdminView> {
  late List<AdminAppointment> items = widget.initial;
  final search = TextEditingController();
  String? status, specialty;
  int? professionalId;
  DateTime day = DateTime.now();
  bool busy = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> filter() async {
    setState(() => busy = true);
    try {
      items = await widget.api.adminAppointments(
          day: day,
          specialty: specialty,
          professionalId: professionalId,
          status: widget.checkinOnly ? 'agendado' : status,
          patient: search.text);
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: Text(title), content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(action))
              ])) ??
      false;

  Future<void> registerAbsence(AdminAppointment item) async {
    if (!await _confirm(
        'Registrar falta?',
        'Registrar a ausência de ${item.patient}? Esta ação ficará no histórico.',
        'Registrar falta')) {
      return;
    }
    try {
      await widget.api.registerAbsence(item.id);
      await filter();
      await widget.onChanged();
      if (mounted) notice(context, 'Falta registrada.');
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  Future<void> showDetails(AdminAppointment item) async {
    try {
      final value = await widget.api.adminAppointmentDetails(item.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text('Detalhes da consulta'),
                content: Semantics(
                    label: 'Detalhes administrativos da consulta',
                    child: SizedBox(
                        width: 480,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value['patient'].toString(),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              Text(
                                  'CPF protegido: ${value['patient_document']}'),
                              Text(
                                  'Data e horário: ${showDate(DateTime.parse(value['scheduled_at'].toString()))}'),
                              Text('Especialidade: ${value['specialty']}'),
                              Text('Profissional: ${value['professional']}'),
                              Text('Prioridade: ${value['legal_priority']}'),
                              Text(
                                  'Risco: ${value['risk_classification'] ?? 'Não classificado'}'),
                              Text(
                                  'Status: ${statusLabel(value['status'].toString())}'),
                            ]))),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Fechar'))
                ],
              ));
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  Future<void> checkIn(AdminAppointment item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Confirmar chegada?'),
                content: Text(
                    'Confirmar a chegada de ${item.patient} para ${item.specialty}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Confirmar chegada'))
                ]));
    if (confirmed != true) return;
    try {
      await widget.api.checkIn(item.id);
      await filter();
      await widget.onChanged();
      if (mounted) notice(context, 'Chegada confirmada pelo backend.');
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        Text(widget.checkinOnly ? 'Confirmar chegada' : 'Agenda e agendamentos',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const Text(
            'Filtre por data, especialidade, profissional, status, nome ou CPF. O CPF nunca é exibido por completo.'),
        const SizedBox(height: 16),
        Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                  width: 260,
                  child: TextField(
                      controller: search,
                      decoration: const InputDecoration(
                          labelText: 'Nome ou CPF do paciente',
                          prefixIcon: Icon(Icons.search)),
                      onSubmitted: (_) => filter())),
              if (!widget.checkinOnly)
                SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                        initialValue: status,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(
                              value: 'agendado', child: Text('Agendada')),
                          DropdownMenuItem(
                              value: 'em_espera', child: Text('Check-in')),
                          DropdownMenuItem(
                              value: 'em_triagem', child: Text('Em triagem')),
                          DropdownMenuItem(
                              value: 'em_atendimento',
                              child: Text('Em atendimento')),
                          DropdownMenuItem(
                              value: 'concluido', child: Text('Concluída')),
                          DropdownMenuItem(
                              value: 'cancelado', child: Text('Cancelada')),
                          DropdownMenuItem(value: 'falta', child: Text('Falta'))
                        ],
                        onChanged: (v) {
                          status = v;
                          filter();
                        })),
              SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                      initialValue: specialty,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Especialidade'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas')),
                        for (final value in widget.specialties)
                          DropdownMenuItem(
                              value: value['name'].toString(),
                              child: Text(value['name'].toString()))
                      ],
                      onChanged: (v) {
                        specialty = v;
                        filter();
                      })),
              SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int>(
                      initialValue: professionalId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Profissional'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todos')),
                        for (final value in widget.professionals)
                          DropdownMenuItem(
                              value: value['id'] as int,
                              child: Text(value['name'].toString()))
                      ],
                      onChanged: (v) {
                        professionalId = v;
                        filter();
                      })),
              OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDate: day);
                    if (picked != null) {
                      day = picked;
                      filter();
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(showOnlyDate(day))),
              FilledButton.icon(
                  onPressed: busy ? null : filter,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Aplicar filtros'))
            ]),
        const SizedBox(height: 16),
        if (busy) const LinearProgressIndicator(),
        if (!busy && items.isEmpty)
          const _EmptyState(
              'Nenhum agendamento encontrado para os filtros selecionados.'),
        for (final item in items)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(builder: (_, c) {
                    final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${item.scheduledAt.hour.toString().padLeft(2, '0')}:${item.scheduledAt.minute.toString().padLeft(2, '0')} • ${item.patient}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                              '${item.patientDocument} • ${item.specialty} • ${item.professional}'),
                          Text('Prioridade: ${item.legalPriority}'),
                          const SizedBox(height: 6),
                          AppStatusBadge(
                              label: 'Status: ${statusLabel(item.status)}',
                              tone: statusToneFor(item.status),
                              semanticLabel:
                                  'Situação: ${statusLabel(item.status)}')
                        ]);
                    final action = Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                          onPressed: () => showDetails(item),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver detalhes')),
                      if (item.status == 'agendado' &&
                          (ApiService.session?.can('appointments:checkin') ??
                              false)) ...[
                        FilledButton.icon(
                            onPressed: () => checkIn(item),
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Confirmar chegada')),
                        OutlinedButton.icon(
                            onPressed: () => registerAbsence(item),
                            icon: const Icon(Icons.person_off_outlined),
                            label: const Text('Registrar falta')),
                      ]
                    ]);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          action
                        ]);
                  })))
      ]);
}

class _DoctorsView extends StatefulWidget {
  const _DoctorsView(
      {required this.api, required this.initial, required this.onChanged});
  final ApiService api;
  final List<DoctorAccount> initial;
  final Future<void> Function() onChanged;

  @override
  State<_DoctorsView> createState() => _DoctorsViewState();
}

class _DoctorsViewState extends State<_DoctorsView> {
  late List<DoctorAccount> doctors = widget.initial;
  late bool hasActiveDoctor = widget.initial.any((doctor) => doctor.active);
  final search = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> filter() async {
    setState(() => busy = true);
    try {
      final values = await Future.wait([
        widget.api.doctors(search: search.text),
        widget.api.doctors(active: true),
      ]);
      doctors = values[0];
      hasActiveDoctor = values[1].isNotEmpty;
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openForm([DoctorAccount? existing]) async {
    await showDialog<void>(
        context: context,
        builder: (_) => _DoctorDialog(api: widget.api, existing: existing));
    await filter();
    await widget.onChanged();
  }

  Future<void> toggle(DoctorAccount doctor) async {
    if (doctor.active) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Desativar Médico?'),
                content: Text(
                    '${doctor.name} perderá o acesso, mas consultas e histórico serão preservados.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Desativar')),
                ],
              ));
      if (confirmed != true) return;
    }
    try {
      await widget.api.setDoctorActive(doctor.id, !doctor.active);
      await filter();
      await widget.onChanged();
      if (mounted) {
        notice(
            context, doctor.active ? 'Médico desativado.' : 'Médico ativado.');
      }
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      ResponsivePageHeader(
          title: 'Médicos',
          subtitle: 'Contas com acesso exclusivo à fila médica.',
          primaryAction: AppActionButton(
              label: 'Cadastrar Médico',
              icon: Icons.person_add_alt_1,
              onPressed: () => openForm())),
      const SizedBox(height: AppSpacing.md),
      Semantics(
          label: hasActiveDoctor
              ? 'Há Médico ativo para atendimento'
              : 'Não há Médico ativo para atendimento',
          child: AppSurfaceCard(
              child: Row(children: [
            Icon(
                hasActiveDoctor
                    ? Icons.check_circle_outline
                    : Icons.warning_amber,
                color: hasActiveDoctor
                    ? green
                    : Theme.of(context).colorScheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(hasActiveDoctor
                    ? 'Há Médico ativo para atendimento'
                    : 'Não há Médico ativo para atendimento')),
          ]))),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(
            child: TextField(
                key: const Key('doctor-search'),
                controller: search,
                decoration: const InputDecoration(
                    labelText: 'Pesquisar por nome ou CPF',
                    prefixIcon: Icon(Icons.search)),
                onSubmitted: (_) => filter())),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
            tooltip: 'Pesquisar',
            onPressed: busy ? null : filter,
            icon: const Icon(Icons.search)),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (busy) const LinearProgressIndicator(),
      if (!busy && doctors.isEmpty)
        const AppEmptyState(
            icon: Icons.medical_services_outlined,
            title: 'Nenhum Médico encontrado',
            message: 'Cadastre uma conta ou altere o termo pesquisado.'),
      for (final doctor in doctors) ...[
        AppSurfaceCard(child: LayoutBuilder(builder: (context, constraints) {
          final details =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctor.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('${doctor.maskedCpf} • ${doctor.specialty}'),
            Text(doctor.active ? 'Ativo' : 'Inativo'),
          ]);
          final actions = Wrap(spacing: 8, runSpacing: 8, children: [
            IconButton(
                tooltip: 'Editar Médico',
                onPressed: () => openForm(doctor),
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: doctor.active ? 'Desativar Médico' : 'Ativar Médico',
                onPressed: () => toggle(doctor),
                icon: Icon(doctor.active
                    ? Icons.block_outlined
                    : Icons.check_circle_outline)),
          ]);
          return constraints.maxWidth < 540
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      details,
                      const SizedBox(height: AppSpacing.sm),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ])
              : Row(children: [
                  Expanded(child: details),
                  actions,
                ]);
        })),
        const SizedBox(height: AppSpacing.sm),
      ],
    ]);
  }
}

class _DoctorDialog extends StatefulWidget {
  const _DoctorDialog({required this.api, this.existing});
  final ApiService api;
  final DoctorAccount? existing;

  @override
  State<_DoctorDialog> createState() => _DoctorDialogState();
}

class _DoctorDialogState extends State<_DoctorDialog> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.existing?.name);
  final cpf = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  late bool active = widget.existing?.active ?? true;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    cpf.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final data = <String, dynamic>{
      'name': name.text.trim(),
      'active': active,
      if (cpf.text.trim().isNotEmpty) 'cpf': digits(cpf.text),
      if (widget.existing == null) 'password': password.text,
      if (widget.existing == null) 'password_confirmation': confirmation.text,
    };
    try {
      if (widget.existing == null) {
        await widget.api.createDoctor(data);
      } else {
        await widget.api.updateDoctor(widget.existing!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.existing == null ? 'Cadastrar Médico' : 'Editar Médico'),
        content: SizedBox(
            width: 540,
            child: Form(
                key: formKey,
                child: SingleChildScrollView(
                    child: Column(children: [
                  TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: requiredName),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                      controller: cpf,
                      inputFormatters: [CpfFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: widget.existing == null
                              ? 'CPF'
                              : 'Novo CPF (opcional)',
                          prefixIcon: const Icon(Icons.badge_outlined)),
                      validator: (value) => widget.existing != null &&
                              (value ?? '').trim().isEmpty
                          ? null
                          : requiredCpf(value)),
                  if (widget.existing == null) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(Icons.lock_outline)),
                        validator: passwordRule),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                        controller: confirmation,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: Icon(Icons.lock_reset)),
                        validator: (value) => value != password.text
                            ? 'As senhas não coincidem.'
                            : null),
                  ],
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Conta ativa'),
                      value: active,
                      onChanged: saving
                          ? null
                          : (value) => setState(() => active = value)),
                  const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.health_and_safety_outlined),
                      title: Text('Perfil: Médico'),
                      subtitle: Text('Especialidade inicial: Clínica Geral')),
                ])))),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Salvando...' : 'Salvar')),
        ],
      );
}

class _InternalUsersView extends StatefulWidget {
  const _InternalUsersView(
      {required this.api,
      required this.initial,
      required this.specialties,
      required this.professionalOnly,
      required this.onChanged});
  final ApiService api;
  final List<InternalUser> initial;
  final List<Map<String, dynamic>> specialties;
  final bool professionalOnly;
  final Future<void> Function() onChanged;
  @override
  State<_InternalUsersView> createState() => _InternalUsersViewState();
}

class _InternalUsersViewState extends State<_InternalUsersView> {
  late List<InternalUser> users = widget.initial;
  final search = TextEditingController();
  String? role;
  bool? active;
  bool busy = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> filter() async {
    setState(() => busy = true);
    try {
      users = await widget.api.internalUsers(
          search: search.text,
          role: widget.professionalOnly ? 'medico' : role,
          active: active);
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggle(InternalUser user) async {
    if (user.active) {
      final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Desativar usuário?'),
                  content: Text(
                      '${user.name} perderá o acesso, mas seu histórico será preservado.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Desativar'))
                  ]));
      if (ok != true) return;
    }
    try {
      await widget.api.setInternalUserActive(user.id, !user.active);
      await filter();
      await widget.onChanged();
      if (mounted) {
        notice(
            context, user.active ? 'Usuário desativado.' : 'Usuário ativado.');
      }
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        ResponsivePageHeader(
            title:
                widget.professionalOnly ? 'Profissionais' : 'Usuários internos',
            subtitle: widget.professionalOnly
                ? 'Profissionais, especialidades e autorização para triagem.'
                : 'Recepcionistas e profissionais. Paciente não é uma opção nesta tela.',
            primaryAction: AppActionButton(
                label: 'Cadastrar usuário',
                icon: Icons.person_add,
                onPressed: () => _openForm())),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
              width: 260,
              child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                      labelText: 'Pesquisar por nome',
                      prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => filter())),
          if (!widget.professionalOnly)
            SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                    initialValue: role,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Perfil'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'recepcao', child: Text('Recepção')),
                      DropdownMenuItem(
                          value: 'enfermagem', child: Text('Enfermagem')),
                      DropdownMenuItem(value: 'medico', child: Text('Médico'))
                    ],
                    onChanged: (v) {
                      role = v;
                      filter();
                    })),
          SizedBox(
              width: 180,
              child: DropdownButtonFormField<bool>(
                  initialValue: active,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todas')),
                    DropdownMenuItem(value: true, child: Text('Ativa')),
                    DropdownMenuItem(value: false, child: Text('Inativa'))
                  ],
                  onChanged: (v) {
                    active = v;
                    filter();
                  }))
        ]),
        const SizedBox(height: 16),
        if (busy) const LinearProgressIndicator(),
        if (!busy && users.isEmpty)
          const _EmptyState(
              'Nenhum usuário encontrado para os filtros selecionados.'),
        for (final user in users)
          Card(child: LayoutBuilder(builder: (context, constraints) {
            final identity = ListTile(
                leading: CircleAvatar(
                    child: Icon(
                        user.role == 'medico' || user.role == 'enfermagem'
                            ? Icons.medical_services
                            : Icons.support_agent)),
                title: Text(user.name),
                subtitle: Text(
                    '${user.role == 'medico' ? 'Médico' : user.role == 'enfermagem' ? 'Enfermagem' : user.role == 'admin' ? 'Administrador' : 'Recepção'} • ${user.maskedCpf}\n${user.email}${user.specialty == null ? '' : ' • ${user.specialty}'}'),
                isThreeLine: true);
            final actions = Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(user.active ? Icons.check_circle : Icons.block,
                  color: user.active
                      ? green
                      : Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Text(user.active ? 'Ativo' : 'Inativo'),
              PopupMenuButton<String>(
                  tooltip: 'Ações do usuário',
                  onSelected: (action) {
                    if (action == 'edit') {
                      _openForm(user);
                    } else if (action == 'access') {
                      _resetAccess(user);
                    } else if (action == 'toggle') {
                      toggle(user);
                    }
                  },
                  itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Editar dados')),
                        const PopupMenuItem(
                            value: 'access', child: Text('Redefinir acesso')),
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(user.active ? 'Desativar' : 'Ativar'))
                      ])
            ]);
            if (constraints.maxWidth < 600) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                        child: Align(
                            alignment: Alignment.centerRight, child: actions))
                  ]);
            }
            return Row(children: [
              Expanded(child: identity),
              const SizedBox(width: 8),
              actions,
              const SizedBox(width: 8),
            ]);
          }))
      ]);

  Future<void> _openForm([InternalUser? existing]) async {
    await showDialog<void>(
        context: context,
        builder: (_) => _InternalUserDialog(
            api: widget.api,
            existing: existing,
            specialties: widget.specialties));
    await filter();
    await widget.onChanged();
  }

  Future<void> _resetAccess(InternalUser user) async {
    final password = TextEditingController(),
        confirmation = TextEditingController();
    final key = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Redefinir acesso'),
                content: Form(
                    key: key,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          'Defina uma nova senha provisória para ${user.name}.'),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: password,
                          obscureText: true,
                          validator: passwordRule,
                          decoration: const InputDecoration(
                              labelText: 'Nova senha provisória')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: confirmation,
                          obscureText: true,
                          validator: (v) => v != password.text
                              ? 'As senhas não coincidem.'
                              : null,
                          decoration:
                              const InputDecoration(labelText: 'Confirmação'))
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState!.validate()) {
                          Navigator.pop(c, true);
                        }
                      },
                      child: const Text('Redefinir'))
                ]));
    if (accepted == true) {
      try {
        await widget.api
            .resetInternalAccess(user.id, password.text, confirmation.text);
        if (mounted) {
          notice(
              context, 'Acesso redefinido. A senha anterior foi invalidada.');
        }
      } on ApiException catch (e) {
        if (mounted) notice(context, e.message);
      }
    }
    password.dispose();
    confirmation.dispose();
  }
}

class _InternalUserDialog extends StatefulWidget {
  const _InternalUserDialog(
      {required this.api, required this.existing, required this.specialties});
  final ApiService api;
  final InternalUser? existing;
  final List<Map<String, dynamic>> specialties;
  @override
  State<_InternalUserDialog> createState() => _InternalUserDialogState();
}

class _InternalUserDialogState extends State<_InternalUserDialog> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.existing?.name),
      cpf = TextEditingController(),
      email = TextEditingController(text: widget.existing?.email),
      registration = TextEditingController(
          text: widget.existing?.professionalRegistration),
      password = TextEditingController(),
      confirmation = TextEditingController();
  late String role = widget.existing?.role ?? 'recepcao';
  late int? specialtyId = widget.existing?.specialtyId;
  late bool canTriage = widget.existing?.canTriage ?? false;
  bool saving = false;
  Map<String, String> errors = {};

  @override
  void dispose() {
    for (final c in [name, cpf, email, registration, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => errors = {});
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    final data = <String, dynamic>{
      'name': name.text.trim(),
      'email': email.text.trim(),
      'role': role,
      if (role == 'medico' || role == 'enfermagem')
        'professional_registration': registration.text.trim(),
      if (role == 'medico' || role == 'enfermagem') 'specialty_id': specialtyId,
      if (role == 'enfermagem') 'can_triage': true
    };
    if (widget.existing == null) {
      data.addAll({
        'cpf': digits(cpf.text),
        'password': password.text,
        'password_confirmation': confirmation.text,
        'active': true
      });
    }
    try {
      if (widget.existing == null) {
        await widget.api.createInternalUser(data);
      } else {
        await widget.api.updateInternalUser(widget.existing!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.field != null) {
            errors[e.field!] = e.message;
          } else {
            notice(context, e.message);
          }
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          actionsOverflowDirection: VerticalDirection.down,
          title: Text(widget.existing == null
              ? 'Cadastrar usuário interno'
              : 'Editar usuário interno'),
          content: SizedBox(
              width: 560,
              child: Form(
                  key: key,
                  child: SingleChildScrollView(
                      child: Column(children: [
                    field(name, 'Nome completo', Icons.person_outline,
                        validator: requiredName, errorText: errors['name']),
                    if (widget.existing == null)
                      field(cpf, 'CPF', Icons.badge_outlined,
                          validator: requiredCpf,
                          errorText: errors['cpf'],
                          inputFormatters: [CpfFormatter()],
                          number: true),
                    field(email, 'E-mail', Icons.email_outlined,
                        validator: emailRule, errorText: errors['email']),
                    DropdownButtonFormField<String>(
                        initialValue: role,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Perfil'),
                        items: const [
                          DropdownMenuItem(
                              value: 'recepcao', child: Text('Recepção')),
                          DropdownMenuItem(
                              value: 'enfermagem', child: Text('Enfermagem')),
                          DropdownMenuItem(
                              value: 'medico',
                              child: Text('Médico',
                                  overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: (v) => setState(() {
                              role = v!;
                              if (role == 'recepcao') {
                                specialtyId = null;
                                canTriage = false;
                              }
                            })),
                    const SizedBox(height: 16),
                    if (role == 'medico' || role == 'enfermagem') ...[
                      field(registration, 'Registro profissional',
                          Icons.workspace_premium_outlined,
                          errorText: errors['professional_registration']),
                      DropdownButtonFormField<int>(
                          initialValue: specialtyId,
                          isExpanded: true,
                          decoration: InputDecoration(
                              labelText: 'Especialidade',
                              errorText: errors['specialty_id']),
                          validator: (v) =>
                              v == null ? 'Selecione a especialidade.' : null,
                          items: [
                            for (final item in widget.specialties)
                              DropdownMenuItem(
                                  value: item['id'] as int,
                                  child: Text(item['name'].toString(),
                                      overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: (v) => setState(() => specialtyId = v)),
                      if (role == 'enfermagem')
                        const ListTile(
                            leading: Icon(Icons.verified_user_outlined),
                            title: Text('Autorizado a realizar triagem'),
                            subtitle: Text(
                                'Permissão exclusiva do perfil Enfermagem.')),
                    ],
                    if (widget.existing == null) ...[
                      field(password, 'Senha provisória', Icons.lock_outline,
                          secret: true,
                          validator: passwordRule,
                          errorText: errors['password']),
                      field(confirmation, 'Confirmação da senha',
                          Icons.lock_reset,
                          secret: true,
                          validator: (v) => v != password.text
                              ? 'As senhas não coincidem.'
                              : null,
                          errorText: errors['password_confirmation']),
                    ]
                  ])))),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            AppActionButton(label: 'Salvar', onPressed: save, busy: saving)
          ]);
}

class _GridAdminView extends StatelessWidget {
  const _GridAdminView(
      {required this.api,
      required this.grids,
      required this.specialties,
      required this.onChanged});
  final ApiService api;
  final List<Map<String, dynamic>> grids, specialties;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => ListView(children: [
        Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Grades e horários',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                Text(
                    'Períodos configuráveis, duração, vagas e intervalo de almoço.')
              ])),
          FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.add),
              label: const Text('Nova grade'))
        ]),
        const SizedBox(height: 16),
        if (grids.isEmpty) const _EmptyState('Nenhuma grade cadastrada.'),
        for (final item in grids)
          Card(
              child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text('${item['professional']} • ${item['specialty']}'),
                  subtitle: Text(
                      '${item['day']} • ${item['start_time']} às ${item['end_time']} • ${item['duration_minutes']} min • ${item['capacity']} vaga(s)\nIntervalo: ${item['break_start'] ?? 'sem'}${item['break_end'] == null ? '' : ' às ${item['break_end']}'}'),
                  isThreeLine: true,
                  trailing: IconButton(
                      tooltip: 'Remover disponibilidade',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(context, item))))
      ]);

  Future<void> _remove(BuildContext context, Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Remover disponibilidade?'),
              content: const Text(
                  'Horários com consultas vinculadas serão preservados e não podem ser removidos.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Remover')),
              ],
            ));
    if (confirmed != true) return;
    try {
      await api.removeGrid(item['id'] as int);
      await onChanged();
      if (context.mounted) notice(context, 'Disponibilidade removida.');
    } on ApiException catch (e) {
      if (context.mounted) notice(context, e.message);
    }
  }

  Future<void> _open(BuildContext context) async {
    final professionals = await api.allProfessionals();
    if (!context.mounted) return;
    await showDialog<void>(
        context: context,
        builder: (_) => _GridDialog(
            api: api, professionals: professionals, specialties: specialties));
    await onChanged();
  }
}

class _GridDialog extends StatefulWidget {
  const _GridDialog(
      {required this.api,
      required this.professionals,
      required this.specialties});
  final ApiService api;
  final List<Map<String, dynamic>> professionals, specialties;
  @override
  State<_GridDialog> createState() => _GridDialogState();
}

class _GridDialogState extends State<_GridDialog> {
  final key = GlobalKey<FormState>();
  final day = TextEditingController(),
      start = TextEditingController(text: '07:00'),
      end = TextEditingController(text: '18:00'),
      duration = TextEditingController(text: '60'),
      capacity = TextEditingController(text: '1'),
      breakStart = TextEditingController(text: '12:00'),
      breakEnd = TextEditingController(text: '13:00');
  int? professionalId, specialtyId;
  bool saving = false;
  @override
  void dispose() {
    for (final c in [
      day,
      start,
      end,
      duration,
      capacity,
      breakStart,
      breakEnd
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.createGrid({
        'professional_id': professionalId,
        'specialty_id': specialtyId,
        'day': day.text,
        'start_time': start.text,
        'end_time': end.text,
        'duration_minutes': int.parse(duration.text),
        'capacity': int.parse(capacity.text),
        if (breakStart.text.isNotEmpty) 'break_start': breakStart.text,
        if (breakEnd.text.isNotEmpty) 'break_end': breakEnd.text
      });
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Nova grade de atendimento'),
          content: SizedBox(
              width: 560,
              child: Form(
                  key: key,
                  child: SingleChildScrollView(
                      child: Column(children: [
                    DropdownButtonFormField<int>(
                        initialValue: professionalId,
                        decoration:
                            const InputDecoration(labelText: 'Profissional'),
                        validator: (v) =>
                            v == null ? 'Selecione o profissional.' : null,
                        items: [
                          for (final x in widget.professionals)
                            DropdownMenuItem(
                                value: x['id'] as int,
                                child: Text(x['name'].toString()))
                        ],
                        onChanged: (v) => professionalId = v),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                        initialValue: specialtyId,
                        decoration:
                            const InputDecoration(labelText: 'Especialidade'),
                        validator: (v) =>
                            v == null ? 'Selecione a especialidade.' : null,
                        items: [
                          for (final x in widget.specialties)
                            DropdownMenuItem(
                                value: x['id'] as int,
                                child: Text(x['name'].toString()))
                        ],
                        onChanged: (v) => specialtyId = v),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: day,
                        readOnly: true,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year, now.month, now.day),
                              lastDate: now.add(const Duration(days: 730)),
                              initialDate: now);
                          if (picked != null) {
                            day.text =
                                picked.toIso8601String().substring(0, 10);
                          }
                        },
                        decoration: const InputDecoration(
                            labelText: 'Data',
                            suffixIcon: Icon(Icons.calendar_today)),
                        validator: (v) => DateTime.tryParse(v ?? '') == null
                            ? 'Informe uma data válida.'
                            : null),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: start,
                              decoration:
                                  const InputDecoration(labelText: 'Início'))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: end,
                              decoration:
                                  const InputDecoration(labelText: 'Fim'))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: duration,
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Duração (min)'))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: capacity,
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Vagas'))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: breakStart,
                              decoration: const InputDecoration(
                                  labelText: 'Início intervalo'))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: breakEnd,
                              decoration: const InputDecoration(
                                  labelText: 'Fim intervalo'))),
                    ]),
                    const SizedBox(height: 12),
                    const InfoPanel(
                        icon: Icons.schedule,
                        text:
                            'Consultas duram 1 hora. Horários permitidos: 07:00 a 11:00 e 13:00 a 16:00, somente em dias úteis não feriados.')
                  ])))),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Salvando...' : 'Salvar grade'))
          ]);
}
