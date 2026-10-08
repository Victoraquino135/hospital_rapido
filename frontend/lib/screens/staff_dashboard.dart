part of '../main.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key, this.api});
  final ApiService? api;

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late final ApiService api = widget.api ?? ApiService();
  final search = TextEditingController();
  DateTime day = DateTime.now();
  Map<String, dynamic> summary = {};
  List<AdminAppointment> items = [];
  final specialties = <String>{};
  final professionals = <int, String>{};
  String? specialty, status, risk;
  int? professionalId;
  bool loading = true, working = false;

  bool get isReception => ApiService.session?.role == 'recepcao';
  bool get isNursing => ApiService.session?.role == 'enfermagem';
  bool get isProfessional => ApiService.session?.role == 'profissional';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (working) return;
    working = true;
    if (!loading && mounted) setState(() {});
    try {
      if (isNursing) {
        final result = await Future.wait([
          api.nursingSummary(day),
          api.nursingQueue(
              day: day, specialty: specialty, status: status, risk: risk),
        ]);
        summary = result[0] as Map<String, dynamic>;
        items = result[1] as List<AdminAppointment>;
      } else if (isProfessional) {
        items = await api.professionalQueue(day);
        summary = {
          'awaiting': items.where((item) => item.status == 'em_triagem').length,
          'in_care':
              items.where((item) => item.status == 'em_atendimento').length,
        };
      } else {
        final result = await Future.wait([
          api.receptionSummary(day),
          api.receptionAppointments(
              day: day,
              specialty: specialty,
              professionalId: professionalId,
              status: status,
              patient: search.text),
        ]);
        summary = result[0] as Map<String, dynamic>;
        items = result[1] as List<AdminAppointment>;
      }
      for (final item in items) {
        specialties.add(item.specialty);
        professionals[item.professionalId] = item.professional;
      }
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      working = false;
      if (mounted) setState(() => loading = false);
    }
  }

  bool get _hasActiveFilters =>
      specialty != null ||
      professionalId != null ||
      status != null ||
      risk != null ||
      search.text.trim().isNotEmpty;

  Future<void> _clearFilters() async {
    if (working) return;
    setState(() {
      specialty = null;
      professionalId = null;
      status = null;
      risk = null;
      search.clear();
    });
    await load();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (working) return;
    setState(() => working = true);
    try {
      await action();
      working = false;
      await load();
      if (mounted) notice(context, success);
    } on ApiException catch (e) {
      working = false;
      if (mounted) {
        setState(() {});
        notice(context, e.message);
      }
    }
  }

  Future<bool> _confirm(String title, String message, String label) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) =>
              AlertDialog(title: Text(title), content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Voltar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(label)),
              ])) ??
      false;

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  Future<void> _chooseDay() async {
    final chosen = await showDatePicker(
        context: context,
        initialDate: day,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (chosen != null) {
      setState(() => day = chosen);
      await load();
    }
  }

  Future<void> _details(AdminAppointment item) async {
    try {
      final value = isNursing
          ? await api.nursingDetails(item.id)
          : isProfessional
              ? await api.professionalDetails(item.id)
              : await api.receptionDetails(item.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(value['patient']?.toString() ?? 'Agendamento'),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(value['patient_document']?.toString() ?? ''),
                        Text('Especialidade: ${value['specialty']}'),
                        Text('Profissional: ${value['professional']}'),
                        Text(
                            'Horário: ${showDate(DateTime.parse(value['scheduled_at']))}'),
                        Text('Status: ${statusLabel(value['status'])}'),
                        Text(
                            'Prioridade: ${value['priority_reason'] ?? 'Sem prioridade legal'}'),
                        if (value['arrived_at'] != null)
                          Text(
                              'Chegada: ${showDate(DateTime.parse(value['arrived_at']))}'),
                        if (value['risk_label'] != null)
                          Text('Risco: ${value['risk_label']}'),
                        if (value['triage_complaint'] != null)
                          Text('Queixa: ${value['triage_complaint']}'),
                        if (value['vital_signs'] != null)
                          Text('Sinais vitais: ${value['vital_signs']}'),
                        if (value['triage_observation'] != null)
                          Text('Observação: ${value['triage_observation']}'),
                      ])),
                  actions: [
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'))
                  ]));
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    }
  }

  Future<void> _checkIn(AdminAppointment item) async {
    if (!await _confirm('Confirmar chegada?',
        'Registrar o check-in presencial de ${item.patient}?', 'Confirmar')) {
      return;
    }
    await _run(() => api.receptionCheckIn(item.id),
        'Check-in registrado com sucesso.');
  }

  Future<void> _absence(AdminAppointment item) async {
    if (!await _confirm('Marcar não comparecimento?',
        'Confirmar que ${item.patient} não compareceu?', 'Marcar ausência')) {
      return;
    }
    await _run(
        () => api.receptionAbsence(item.id), 'Não comparecimento registrado.');
  }

  Future<void> _classify(AdminAppointment item) async {
    final value = await showDialog<List<String?>>(
        context: context, builder: (_) => const _RiskDialog());
    if (value == null) {
      return;
    }
    await _run(
        () => api.classifyRisk(
            item.id, value[0]!, value[1]!, value[2]!, value[3]),
        'Classificação de risco registrada.');
  }

  Future<void> _start(AdminAppointment item) async {
    if (!await _confirm('Iniciar atendimento?',
        'Iniciar o atendimento de ${item.patient}?', 'Iniciar')) {
      return;
    }
    await _run(
        () => api.startCare(item.id), 'Atendimento iniciado com sucesso.');
  }

  Future<void> _call(AdminAppointment item) async {
    await _run(() => api.callPatient(item.id), 'Paciente chamado com sucesso.');
  }

  Future<void> _complete(AdminAppointment item) async {
    if (!await _confirm('Concluir atendimento?',
        'Concluir o atendimento de ${item.patient}?', 'Concluir')) {
      return;
    }
    await _run(
        () => api.completeCare(item.id), 'Atendimento concluído com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    final title = isNursing
        ? 'Painel da Enfermagem'
        : isProfessional
            ? 'Painel do Profissional de Saúde'
            : 'Painel da Recepção';
    return ResponsiveAppShell(
        wideNavigationMode: WideNavigationMode.contentOnly,
        title: title,
        subtitle: ApiService.session?.name,
        primaryAction: Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: working ? null : load,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar')),
          OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sair')),
        ]),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: load,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      if (isNursing) ...[
                        const AppSurfaceCard(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Simulação acadêmica',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    SizedBox(height: 4),
                                    Text(
                                        'A classificação de risco é manual, deve ser feita somente por profissional autorizado e não substitui uma avaliação real.')
                                  ]))
                            ])),
                        const SizedBox(height: 12),
                      ],
                      _summaryCards(),
                      const SizedBox(height: 12),
                      _filters(),
                      const SizedBox(height: 12),
                      Semantics(
                          key: const Key('staff-results-region'),
                          container: true,
                          label: 'Resultados dos atendimentos',
                          child: items.isEmpty
                              ? AppEmptyState(
                                  icon: Icons.filter_alt_off_outlined,
                                  title: 'Nenhum atendimento encontrado',
                                  message:
                                      'Não há atendimentos para os filtros selecionados.',
                                  actionLabel: _hasActiveFilters
                                      ? 'Limpar filtros'
                                      : null,
                                  onAction: _hasActiveFilters && !working
                                      ? _clearFilters
                                      : null,
                                )
                              : Column(
                                  children: [
                                    for (final item in items) _itemCard(item)
                                  ],
                                )),
                      const SizedBox(height: 100),
                    ]))));
  }

  Widget _summaryCards() {
    final cards = isNursing
        ? <(String, int, IconData)>[
            (
              'Aguardando triagem',
              summary['awaiting_triage'] ?? 0,
              Icons.groups_outlined
            ),
            (
              'Em atendimento',
              summary['in_care'] ?? 0,
              Icons.medical_services_outlined
            ),
            ('Concluídas', summary['completed'] ?? 0, Icons.task_alt_outlined),
            for (final entry in (summary['risk_counts'] as Map? ?? {}).entries)
              (
                _riskLabel(entry.key.toString()),
                entry.value as int,
                Icons.flag
              ),
          ]
        : isProfessional
            ? <(String, int, IconData)>[
                (
                  'Encaminhados',
                  summary['awaiting'] ?? 0,
                  Icons.campaign_outlined
                ),
                (
                  'Em atendimento',
                  summary['in_care'] ?? 0,
                  Icons.medical_services_outlined
                ),
              ]
            : <(String, int, IconData)>[
                ('Agendadas', summary['scheduled'] ?? 0, Icons.event_outlined),
                ('Check-in', summary['checked_in'] ?? 0, Icons.how_to_reg),
                (
                  'Em atendimento',
                  summary['in_care'] ?? 0,
                  Icons.medical_services_outlined
                ),
                (
                  'Concluídas',
                  summary['completed'] ?? 0,
                  Icons.task_alt_outlined
                ),
                (
                  'Não compareceu',
                  summary['absent'] ?? 0,
                  Icons.person_off_outlined
                ),
              ];
    return LayoutBuilder(builder: (_, constraints) {
      final width = constraints.maxWidth < 620
          ? constraints.maxWidth
          : constraints.maxWidth < 980
              ? (constraints.maxWidth - 12) / 2
              : (constraints.maxWidth - 36) / 4;
      return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(
                  width: width,
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(children: [
                            Icon(card.$3, color: green),
                            const SizedBox(width: 10),
                            Expanded(child: Text(card.$1)),
                            Text('${card.$2}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: blue)),
                          ])))))
              .toList());
    });
  }

  Widget _filters() => LayoutBuilder(builder: (context, constraints) {
        final controls = Wrap(spacing: 12, runSpacing: 12, children: [
          OutlinedButton.icon(
              onPressed: _chooseDay,
              icon: const Icon(Icons.calendar_today),
              label: Text(showOnlyDate(day))),
          if (isReception)
            SizedBox(
                width: 250,
                child: TextField(
                    key: const Key('staff-search'),
                    controller: search,
                    onSubmitted: (_) => load(),
                    decoration: InputDecoration(
                        labelText: 'Buscar nome ou CPF',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                            tooltip: 'Buscar',
                            onPressed: load,
                            icon: const Icon(Icons.arrow_forward))))),
          _dropdown('Especialidade', specialty,
              specialties.map((x) => (x, x)).toList(), (value) {
            setState(() => specialty = value);
            load();
          }, key: const Key('staff-filter-specialty')),
          if (isReception)
            _dropdown(
                'Profissional',
                professionalId?.toString(),
                professionals.entries
                    .map((x) => (x.key.toString(), x.value))
                    .toList(), (value) {
              setState(() => professionalId = int.tryParse(value ?? ''));
              load();
            }, key: const Key('staff-filter-professional')),
          _dropdown(
              'Status',
              status,
              ((isNursing || isProfessional)
                      ? const {
                          'em_espera': 'Aguardando triagem',
                          'em_triagem': 'Em triagem',
                          'em_atendimento': 'Em atendimento',
                          'concluido': 'Concluída',
                        }
                      : const {
                          'agendado': 'Agendada',
                          'em_espera': 'Check-in realizado',
                          'em_triagem': 'Em triagem',
                          'em_atendimento': 'Em atendimento',
                          'concluido': 'Concluída',
                          'falta': 'Não compareceu',
                          'cancelado': 'Cancelada',
                        })
                  .entries
                  .map((x) => (x.key, x.value))
                  .toList(), (value) {
            setState(() => status = value);
            load();
          }, key: const Key('staff-filter-status')),
          if (isNursing)
            _dropdown('Classificação de risco', risk, const [
              ('muito_alto', 'Muito alto'),
              ('alto', 'Alto'),
              ('medio', 'Médio'),
              ('baixo', 'Baixo'),
            ], (value) {
              setState(() => risk = value);
              load();
            }, key: const Key('staff-filter-risk')),
        ]);
        if (constraints.maxWidth < 600) {
          return Card(
              key: const Key('staff-compact-filters'),
              child: ExpansionTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: const Text('Filtros'),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  children: [controls]));
        }
        return Semantics(
            key: const Key('staff-filter-region'),
            container: true,
            label: 'Filtros de atendimentos',
            child: AppSurfaceCard(child: controls));
      });

  Widget _dropdown(String label, String? value, List<(String, String)> values,
          ValueChanged<String?> changed,
          {Key? key}) =>
      SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
              key: key,
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                for (final item in values)
                  DropdownMenuItem(
                      value: item.$1,
                      child: Text(item.$2,
                          overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
              onChanged: (value) =>
                  changed(value?.isEmpty ?? true ? null : value)));

  Widget _itemCard(AdminAppointment item) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(15),
              child: LayoutBuilder(builder: (_, constraints) {
                final info = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.patient,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(
                          '${item.patientDocument} • ${item.specialty} • ${item.professional}'),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        Text(showDate(item.scheduledAt)),
                        AppStatusBadge(
                            label: statusLabel(item.status),
                            tone: statusToneFor(item.status),
                            semanticLabel:
                                'Situação: ${statusLabel(item.status)}'),
                      ]),
                      if (item.arrivedAt != null)
                        Text('Chegada: ${showDate(item.arrivedAt!)}'),
                      Text('Prioridade: ${item.priorityReason}',
                          style: TextStyle(
                              fontWeight: item.legalPriority == 'geral'
                                  ? FontWeight.normal
                                  : FontWeight.w700,
                              color: item.legalPriority == 'geral'
                                  ? null
                                  : green)),
                      if (item.riskLabel != null)
                        Semantics(
                            label: 'Nível de risco: ${item.riskLabel}',
                            child: Row(children: [
                              const Icon(Icons.flag_outlined, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text('Risco: ${item.riskLabel}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)))
                            ])),
                      if (item.triageObservation?.isNotEmpty ?? false)
                        Text('Observação: ${item.triageObservation}'),
                      if (item.triageComplaint?.isNotEmpty ?? false)
                        Text('Queixa: ${item.triageComplaint}'),
                      if (item.vitalSigns?.isNotEmpty ?? false)
                        Text('Sinais vitais: ${item.vitalSigns}'),
                      if (isProfessional) ...[
                        const SizedBox(height: 8),
                        const Text('1. Chamar  2. Iniciar  3. Concluir',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ]);
                final actions = Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                      onPressed: () => _details(item),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Detalhes')),
                  if (isReception && item.status == 'agendado')
                    AppActionButton(
                        onPressed: working ? null : () => _checkIn(item),
                        icon: Icons.how_to_reg,
                        label: 'Check-in'),
                  if (isReception &&
                      const {'agendado', 'em_espera'}.contains(item.status))
                    OutlinedButton.icon(
                        onPressed: working ? null : () => _absence(item),
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Não compareceu')),
                  if (isNursing &&
                      const {'em_espera', 'em_triagem'}.contains(item.status))
                    AppActionButton(
                        onPressed: working ? null : () => _classify(item),
                        icon: Icons.flag_outlined,
                        label: item.status == 'em_triagem'
                            ? 'Reclassificar risco'
                            : 'Classificar risco'),
                  if (isProfessional && item.status == 'em_triagem')
                    OutlinedButton.icon(
                        onPressed: working ? null : () => _call(item),
                        icon: const Icon(Icons.campaign_outlined),
                        label: Text(item.calledAt == null
                            ? 'Chamar paciente'
                            : 'Chamar novamente')),
                  if (isProfessional && item.status == 'em_triagem')
                    AppActionButton(
                        onPressed: working ? null : () => _start(item),
                        icon: Icons.play_arrow,
                        label: 'Iniciar atendimento'),
                  if (isProfessional && item.status == 'em_atendimento')
                    AppActionButton(
                        onPressed: working ? null : () => _complete(item),
                        icon: Icons.task_alt,
                        label: 'Concluir atendimento'),
                ]);
                return constraints.maxWidth < 760
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [info, const SizedBox(height: 12), actions])
                    : Row(children: [
                        Expanded(child: info),
                        const SizedBox(width: 12),
                        Flexible(child: actions)
                      ]);
              }))));
}

String _riskLabel(String value) =>
    const {
      'muito_alto': 'Risco muito alto',
      'alto': 'Risco alto',
      'medio': 'Risco médio',
      'baixo': 'Risco baixo',
    }[value] ??
    value;

class _RiskDialog extends StatefulWidget {
  const _RiskDialog();

  @override
  State<_RiskDialog> createState() => _RiskDialogState();
}

class _RiskDialogState extends State<_RiskDialog> {
  final formKey = GlobalKey<FormState>();
  final complaint = TextEditingController();
  final vitalSigns = TextEditingController();
  final observation = TextEditingController();
  String level = 'baixo';

  @override
  void dispose() {
    complaint.dispose();
    vitalSigns.dispose();
    observation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          actionsOverflowDirection: VerticalDirection.down,
          title: const Text('Classificação de risco manual'),
          content: SingleChildScrollView(
              child: Form(
                  key: formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                        initialValue: level,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Nível de risco'),
                        items: const [
                          DropdownMenuItem(
                              value: 'muito_alto', child: Text('Muito alto')),
                          DropdownMenuItem(value: 'alto', child: Text('Alto')),
                          DropdownMenuItem(
                              value: 'medio', child: Text('Médio')),
                          DropdownMenuItem(
                              value: 'baixo', child: Text('Baixo')),
                        ],
                        onChanged: (value) => level = value ?? level),
                    const SizedBox(height: 12),
                    TextFormField(
                        key: const Key('triage-complaint'),
                        controller: complaint,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        validator: (value) => (value ?? '').trim().length < 3
                            ? 'Informe a queixa principal.'
                            : null,
                        decoration: const InputDecoration(
                            labelText: 'Queixa principal',
                            hintText:
                                'Relato fictício apresentado pelo paciente.')),
                    const SizedBox(height: 12),
                    TextFormField(
                        key: const Key('triage-vital-signs'),
                        controller: vitalSigns,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        validator: (value) => (value ?? '').trim().length < 3
                            ? 'Informe os sinais vitais aferidos.'
                            : null,
                        decoration: const InputDecoration(
                            labelText: 'Sinais vitais aferidos',
                            hintText:
                                'Ex.: PA e temperatura fictícias para demonstração.')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: observation,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            labelText: 'Observação curta (opcional)',
                            hintText:
                                'Registre somente a observação necessária.')),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.pop(context, <String?>[
                    level,
                    complaint.text.trim(),
                    vitalSigns.text.trim(),
                    observation.text.trim()
                  ]);
                },
                child: const Text('Salvar classificação')),
          ]);
}
