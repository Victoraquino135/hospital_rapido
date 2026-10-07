part of '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.api});
  final ApiService? api;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final document = TextEditingController(), password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool busy = false, hide = true;
  Future<void> login() async {
    if (busy) return;
    if (!validateAndFocus(formKey)) {
      return;
    }
    setState(() => busy = true);
    try {
      await (widget.api ?? ApiService()).login(document.text, password.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => homeForRole()), (_) => false);
      }
    } on ApiException catch (e) {
      if (mounted) notice(context, e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    document.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      child: AuthLayout(
          child: Form(
              key: formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark()),
                    const SizedBox(height: 28),
                    const Text('Acesse sua conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Faça login para continuar com sua saúde sempre em dia.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    field(document, 'CPF', Icons.badge_outlined,
                        number: true,
                        validator: requiredCpf,
                        inputFormatters: [CpfFormatter()]),
                    field(password, 'Senha', Icons.lock_outline,
                        secret: hide,
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Informe a senha.' : null,
                        suffix: IconButton(
                            tooltip: hide ? 'Mostrar senha' : 'Ocultar senha',
                            onPressed: () => setState(() => hide = !hide),
                            icon: Icon(hide
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined))),
                    AppActionButton(
                        label: 'Entrar →',
                        icon: Icons.login,
                        onPressed: login,
                        busy: busy,
                        expand: true),
                    TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RecoveryPage())),
                        child: const Text('Esqueci minha senha')),
                    const Divider(height: 32),
                    const Text('Ainda não tem uma conta?',
                        textAlign: TextAlign.center),
                    OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage())),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Cadastrar-se'))
                  ]))));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Map<String, String> serverErrors = {};
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      cpf = TextEditingController(),
      birth = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController(),
      guardianName = TextEditingController(),
      guardianCpf = TextEditingController(),
      guardianPhone = TextEditingController(),
      guardianEmail = TextEditingController();
  String relationship = 'Mãe';
  bool busy = false, hide = true, minor = false;
  String priority = 'geral', birthIso = '';
  Future<void> chooseBirth() async {
    final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDate: DateTime(2000));
    if (picked != null) {
      setState(() {
        birth.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        birthIso =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        final now = DateTime.now();
        minor = now.year -
                picked.year -
                ((now.month < picked.month ||
                        (now.month == picked.month && now.day < picked.day))
                    ? 1
                    : 0) <
            18;
      });
    }
  }

  Future<void> register() async {
    setState(() => serverErrors = {});
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!validateAndFocus(formKey) || birthIso.isEmpty) {
      notice(context, 'Corrija os campos indicados.');
      return;
    }
    final data = {
      'name': name.text.trim(),
      'cpf': digits(cpf.text),
      'birth_date': birthIso,
      'email': email.text.trim(),
      'phone': digits(phone.text),
      'password': password.text,
      'priority': priority,
      if (minor) ...{
        'guardian_name': guardianName.text.trim(),
        'guardian_cpf': digits(guardianCpf.text),
        'guardian_phone': digits(guardianPhone.text),
        'guardian_email': guardianEmail.text.trim(),
        'guardian_relationship': relationship
      }
    };
    setState(() => busy = true);
    try {
      await ApiService().register(data);
      if (mounted) {
        notice(context, 'Cadastro realizado. Entre com suas credenciais.');
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
            () => serverErrors = {if (e.field != null) e.field!: e.message});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) validateAndFocus(formKey);
        });
        notice(context, e.message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      name,
      cpf,
      birth,
      email,
      phone,
      password,
      confirmation,
      guardianName,
      guardianCpf,
      guardianPhone,
      guardianEmail
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      child: AuthLayout(
          child: Form(
              key: formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark()),
                    const SizedBox(height: 22),
                    const Text('Criar conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    field(name, 'Nome completo', Icons.person_outline,
                        validator: requiredName,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ -]')),
                          LengthLimitingTextInputFormatter(80)
                        ]),
                    field(cpf, 'CPF', Icons.badge_outlined,
                        number: true,
                        hint: '000.000.000-00',
                        errorText: serverErrors['cpf'],
                        validator: requiredCpf,
                        inputFormatters: [CpfFormatter()]),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                            label: 'Data de nascimento',
                            button: true,
                            child: TextFormField(
                                controller: birth,
                                readOnly: true,
                                onTap: chooseBirth,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Selecione a data de nascimento.'
                                    : null,
                                decoration: const InputDecoration(
                                    labelText: 'Data de nascimento',
                                    prefixIcon:
                                        Icon(Icons.calendar_today_outlined),
                                    hintText: 'dd/MM/aaaa')))),
                    field(email, 'E-mail', Icons.email_outlined,
                        errorText: serverErrors['email'], validator: emailRule),
                    field(phone, 'Telefone / celular', Icons.phone_outlined,
                        number: true,
                        hint: '(00) 00000-0000',
                        validator: phoneRule,
                        inputFormatters: [PhoneFormatter()]),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: priority,
                        decoration: const InputDecoration(
                            labelText: 'Perfil prioritário',
                            prefixIcon: Icon(Icons.priority_high)),
                        items: const [
                          DropdownMenuItem(
                              value: 'geral', child: Text('Geral')),
                          DropdownMenuItem(value: 'pcd', child: Text('PCD')),
                          DropdownMenuItem(
                              value: 'gestante', child: Text('Gestante')),
                          DropdownMenuItem(
                              value: 'lactante', child: Text('Lactante'))
                        ],
                        onChanged: (v) => setState(() => priority = v!)),
                    const SizedBox(height: 16),
                    if (minor) ...[
                      const InfoPanel(
                          icon: Icons.family_restroom,
                          text:
                              'Dados do responsável — obrigatórios para menores de 18 anos.'),
                      const SizedBox(height: 16),
                      field(guardianName, 'Nome completo do responsável',
                          Icons.person_outline,
                          errorText: serverErrors['guardian_name'],
                          validator: (v) => guardianNameRule(v, name.text),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(80)
                          ]),
                      field(guardianCpf, 'CPF do responsável',
                          Icons.badge_outlined,
                          number: true,
                          errorText: serverErrors['guardian_cpf'],
                          validator: (v) => guardianCpfRule(v, cpf.text),
                          inputFormatters: [CpfFormatter()]),
                      field(guardianPhone, 'Telefone do responsável',
                          Icons.phone_outlined,
                          number: true,
                          errorText: serverErrors['guardian_phone'],
                          validator: (v) => guardianPhoneRule(v, phone.text),
                          inputFormatters: [PhoneFormatter()]),
                      field(guardianEmail, 'E-mail do responsável',
                          Icons.email_outlined,
                          errorText: serverErrors['guardian_email'],
                          validator: (v) => guardianEmailRule(v, email.text)),
                      DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: relationship,
                          decoration: const InputDecoration(
                              labelText: 'Grau de parentesco'),
                          items: [
                            'Mãe',
                            'Pai',
                            'Avó/Avô',
                            'Tutor(a) legal',
                            'Outro responsável legal'
                          ]
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setState(() => relationship = v!)),
                      const SizedBox(height: 16)
                    ],
                    field(password, 'Senha', Icons.lock_outline,
                        secret: hide,
                        validator: passwordRule,
                        suffix: IconButton(
                            tooltip: hide ? 'Mostrar senha' : 'Ocultar senha',
                            onPressed: () => setState(() => hide = !hide),
                            icon: Icon(hide
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined))),
                    PasswordRules(password: password.text),
                    field(confirmation, 'Confirmar senha', Icons.lock_outline,
                        secret: hide,
                        validator: (v) => v == password.text
                            ? null
                            : 'As senhas não conferem.'),
                    AppActionButton(
                        label: 'Cadastrar',
                        icon: Icons.person_add_alt_1,
                        onPressed: register,
                        busy: busy,
                        expand: true),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Já tem uma conta? Fazer login'))
                  ]))));
}

class ResponsiblePage extends StatefulWidget {
  const ResponsiblePage({super.key, required this.patientData});
  final Map<String, dynamic> patientData;
  @override
  State<ResponsiblePage> createState() => _ResponsiblePageState();
}

class _ResponsiblePageState extends State<ResponsiblePage> {
  final name = TextEditingController(),
      cpf = TextEditingController(),
      birth = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      other = TextEditingController();
  final formKey = GlobalKey<FormState>();
  Map<String, String> serverErrors = {};
  String relationship = 'Mãe';
  bool busy = false;
  Future<void> pickBirth() async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDate: DateTime(1980));
    if (d != null) {
      setState(() => birth.text =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> save() async {
    setState(() => serverErrors = {});
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!validateAndFocus(formKey)) return;
    setState(() => busy = true);
    try {
      await ApiService().register({
        ...widget.patientData,
        'guardian_name': name.text.trim(),
        'guardian_cpf': digits(cpf.text),
        'guardian_birth_date': birth.text,
        'guardian_relationship': relationship,
        'guardian_other_relationship': relationship == 'Outro responsável legal'
            ? other.text.trim()
            : null,
        'guardian_phone': digits(phone.text),
        'guardian_email': email.text.trim().isEmpty ? null : email.text.trim()
      });
      if (mounted) {
        notice(context, 'Cadastro realizado. Entre com suas credenciais.');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
            () => serverErrors = {if (e.field != null) e.field!: e.message});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) validateAndFocus(formKey);
        });
        notice(context, e.message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, cpf, birth, phone, email, other]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      child: AuthLayout(
          child: Form(
              key: formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Responsável legal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Dados obrigatórios para concluir o cadastro do menor.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    field(name, 'Nome completo do responsável',
                        Icons.person_outline,
                        errorText: serverErrors['guardian_name'],
                        validator: (v) => guardianNameRule(
                            v, widget.patientData['name'] ?? '')),
                    field(cpf, 'CPF do responsável', Icons.badge_outlined,
                        number: true,
                        errorText: serverErrors['guardian_cpf'],
                        validator: (v) =>
                            guardianCpfRule(v, widget.patientData['cpf'] ?? ''),
                        inputFormatters: [CpfFormatter()]),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                            controller: birth,
                            readOnly: true,
                            onTap: pickBirth,
                            validator: guardianBirthRule,
                            forceErrorText: serverErrors['guardian_birth_date'],
                            decoration: const InputDecoration(
                                labelText: 'Data de nascimento',
                                prefixIcon:
                                    Icon(Icons.calendar_today_outlined)))),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: relationship,
                        decoration: const InputDecoration(
                            labelText: 'Parentesco',
                            prefixIcon: Icon(Icons.family_restroom)),
                        items: const [
                          DropdownMenuItem(value: 'Mãe', child: Text('Mãe')),
                          DropdownMenuItem(value: 'Pai', child: Text('Pai')),
                          DropdownMenuItem(
                              value: 'Avó/Avô', child: Text('Avó/Avô')),
                          DropdownMenuItem(
                              value: 'Tutor(a) legal',
                              child: Text('Tutor(a) legal')),
                          DropdownMenuItem(
                              value: 'Outro responsável legal',
                              child: Text('Outro responsável legal'))
                        ],
                        onChanged: (v) => setState(() => relationship = v!)),
                    const SizedBox(height: 16),
                    if (relationship == 'Outro responsável legal')
                      field(other, 'Descreva o parentesco', Icons.edit_outlined,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Informe o parentesco.'
                              : null),
                    field(phone, 'Telefone / celular', Icons.phone_outlined,
                        number: true,
                        errorText: serverErrors['guardian_phone'],
                        validator: (v) => guardianPhoneRule(
                            v, widget.patientData['phone'] ?? ''),
                        inputFormatters: [PhoneFormatter()]),
                    field(email, 'E-mail do responsável', Icons.email_outlined,
                        errorText: serverErrors['guardian_email'],
                        validator: (v) => guardianEmailRule(
                            v, widget.patientData['email'] ?? '')),
                    AppActionButton(
                        label: 'Concluir cadastro',
                        icon: Icons.check_circle_outline,
                        onPressed: save,
                        busy: busy,
                        expand: true)
                  ]))));
}
