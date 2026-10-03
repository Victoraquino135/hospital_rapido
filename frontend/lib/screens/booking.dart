part of '../main.dart';

Future<void> booking(BuildContext context, ApiService api, Appointment? old,
    VoidCallback done) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
          child: FractionallySizedBox(
              heightFactor: .9,
              child: BookingPanel(api: api, old: old, onChanged: done))));
}

class BookingPanel extends StatefulWidget {
  const BookingPanel(
      {super.key,
      required this.api,
      required this.old,
      required this.onChanged});
  final ApiService api;
  final Appointment? old;
  final VoidCallback onChanged;
  @override
  State<BookingPanel> createState() => _BookingPanelState();
}

class _BookingPanelState extends State<BookingPanel> {
  List<Map<String, dynamic>> specialties = [], professionals = [];
  List<DateTime> dates = [];
  List<Slot> times = [];
  String? specialty, error;
  int? doctor;
  DateTime? day;
  Slot? chosen;
  bool loading = true, saving = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    loadSpecialties();
  }

  Future<void> loadSpecialties() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await widget.api.specialties();
      if (!mounted) return;
      setState(() {
        specialties = value;
        specialty = widget.old?.specialty;
        loading = false;
      });
      if (specialty != null) loadProfessionals();
    } on ApiException catch (e) {
      showError(e);
    }
  }

  Future<void> loadProfessionals() async {
    final serial = ++generation;
    setState(() {
      loading = true;
      error = null;
      professionals = [];
      doctor = null;
      dates = [];
      day = null;
      times = [];
      chosen = null;
    });
    try {
      final value = await widget.api.professionals(specialty!);
      if (mounted && serial == generation) {
        setState(() {
          professionals = value;
          loading = false;
        });
      }
    } on ApiException catch (e) {
      if (serial == generation) showError(e);
    }
  }

  Future<void> loadDates() async {
    final serial = ++generation;
    setState(() {
      loading = true;
      error = null;
      dates = [];
      day = null;
      times = [];
      chosen = null;
    });
    try {
      final value = await widget.api.availableDates(specialty!, doctor!);
      if (mounted && serial == generation) {
        setState(() {
          dates = value;
          loading = false;
        });
      }
    } on ApiException catch (e) {
      if (serial == generation) showError(e);
    }
  }

  Future<void> loadTimes() async {
    final serial = ++generation;
    setState(() {
      loading = true;
      error = null;
      times = [];
      chosen = null;
    });
    try {
      final value = await widget.api.availableTimes(specialty!, doctor!, day!);
      if (mounted && serial == generation) {
        setState(() {
          times = value;
          loading = false;
        });
      }
    } on ApiException catch (e) {
      if (serial == generation) showError(e);
    }
  }

  void showError(ApiException e) {
    if (!mounted) return;
    setState(() {
      error = e.message;
      loading = false;
    });
  }

  Future<void> confirm() async {
    if (chosen == null || saving) return;
    setState(() => saving = true);
    try {
      if (widget.old == null) {
        await widget.api.book(chosen!);
      } else {
        await widget.api.reschedule(widget.old!.id, chosen!);
      }
      widget.onChanged();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
            content: Text(widget.old == null
                ? 'Consulta agendada.'
                : 'Consulta reagendada.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        final occupied =
            e.statusCode == 409 && e.message == 'Horário indisponível';
        setState(() => error = occupied
            ? 'Este horário ficou ocupado. Escolha outro horário.'
            : e.message);
        if (occupied) notice(context, error!);
        if (occupied && day != null) loadTimes();
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text(
                  widget.old == null
                      ? 'Agendar consulta'
                      : 'Reagendar consulta',
                  style: Theme.of(context).textTheme.headlineSmall)),
          IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close))
        ]),
        const SizedBox(height: 12),
        Expanded(
            child: ListView(children: [
          if (specialties.isNotEmpty)
            DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: specialty,
                decoration: const InputDecoration(labelText: 'Especialidade'),
                items: specialties
                    .map((x) => DropdownMenuItem(
                        value: x['name'] as String,
                        child: Text(x['name'] as String)))
                    .toList(),
                onChanged: loading || saving || widget.old != null
                    ? null
                    : (v) {
                        if (v == null) {
                          return;
                        }
                        setState(() => specialty = v);
                        loadProfessionals();
                      }),
          if (!loading && specialties.isEmpty && error == null)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma especialidade cadastrada.')),
          const SizedBox(height: 12),
          if (specialty != null && professionals.isNotEmpty)
            DropdownButtonFormField<int>(
                key: ValueKey('doctor-$specialty'),
                isExpanded: true,
                initialValue: doctor,
                decoration: const InputDecoration(labelText: 'Profissional'),
                items: professionals
                    .map((x) => DropdownMenuItem(
                        value: x['id'] as int,
                        child: Text(x['name'] as String)))
                    .toList(),
                onChanged: loading || saving
                    ? null
                    : (v) {
                        if (v == null) {
                          return;
                        }
                        setState(() => doctor = v);
                        loadDates();
                      }),
          if (!loading &&
              specialty != null &&
              professionals.isEmpty &&
              error == null)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum profissional para esta especialidade.')),
          const SizedBox(height: 12),
          if (doctor != null && dates.isNotEmpty)
            DropdownButtonFormField<DateTime>(
                key: ValueKey('date-$doctor'),
                isExpanded: true,
                initialValue: day,
                decoration: const InputDecoration(labelText: 'Data disponível'),
                items: dates
                    .map((x) => DropdownMenuItem(
                        value: x, child: Text(showOnlyDate(x))))
                    .toList(),
                onChanged: loading || saving
                    ? null
                    : (v) {
                        if (v == null) {
                          return;
                        }
                        setState(() => day = v);
                        loadTimes();
                      }),
          if (!loading && doctor != null && dates.isEmpty && error == null)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma data disponível.')),
          const SizedBox(height: 12),
          if (day != null && times.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final slot in times)
                ChoiceChip(
                    tooltip: slot.label,
                    label: Text(
                        '${slot.scheduledAt.hour.toString().padLeft(2, '0')}:${slot.scheduledAt.minute.toString().padLeft(2, '0')} — ${slot.label}'),
                    selected: chosen?.scheduledAt == slot.scheduledAt,
                    onSelected: saving || !slot.selectable
                        ? null
                        : (_) => setState(() => chosen = slot)),
            ]),
          if (!loading && day != null && times.isEmpty && error == null)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum horário livre nesta data.')),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator())),
          if (error != null)
            Column(children: [
              Text(error!),
              OutlinedButton(
                  onPressed: () {
                    if (day != null) {
                      loadTimes();
                    } else if (doctor != null) {
                      loadDates();
                    } else if (specialty != null) {
                      loadProfessionals();
                    } else {
                      loadSpecialties();
                    }
                  },
                  child: const Text('Tentar novamente'))
            ]),
          if (chosen != null)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resumo',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(specialty!),
                          Text(professionals.firstWhere(
                              (x) => x['id'] == doctor)['name'] as String),
                          Text(showDate(chosen!.scheduledAt)),
                        ]))),
        ])),
        FilledButton(
            onPressed: chosen == null || saving || loading ? null : confirm,
            child: saving
                ? const CircularProgressIndicator()
                : Text(widget.old == null
                    ? 'Confirmar agendamento'
                    : 'Confirmar reagendamento')),
      ]));
}
