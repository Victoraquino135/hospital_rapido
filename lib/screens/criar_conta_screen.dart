import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../database/database_helper.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _formKey = GlobalKey<FormState>();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {
      '#': RegExp(r'[0-9]'),
    },
  );

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {
      '#': RegExp(r'[0-9]'),
    },
  );

  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {
      '#': RegExp(r'[0-9]'),
    },
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _dataController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LIMPAR CPF
  // ==========================================================

  String _limparCpf(String cpf) {
    return cpf.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  // ==========================================================
  // VALIDAR CPF
  // ==========================================================

  bool _cpfValido(String cpf) {
    final numeros = _limparCpf(cpf);

    if (numeros.length != 11) {
      return false;
    }

    // Impede CPFs como 111.111.111-11
    if (RegExp(r'^(\d)\1{10}$').hasMatch(numeros)) {
      return false;
    }

    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += int.parse(numeros[i]) * (10 - i);
    }

    int resto = soma % 11;

    int primeiroDigito = resto < 2 ? 0 : 11 - resto;

    if (primeiroDigito != int.parse(numeros[9])) {
      return false;
    }

    soma = 0;

    for (int i = 0; i < 10; i++) {
      soma += int.parse(numeros[i]) * (11 - i);
    }

    resto = soma % 11;

    int segundoDigito = resto < 2 ? 0 : 11 - resto;

    if (segundoDigito != int.parse(numeros[10])) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // VALIDAR DATA DE NASCIMENTO
  // ==========================================================

  bool _dataValida(String data) {
    if (data.length != 10) {
      return false;
    }

    try {
      final partes = data.split('/');

      if (partes.length != 3) {
        return false;
      }

      final int dia = int.parse(partes[0]);
      final int mes = int.parse(partes[1]);
      final int ano = int.parse(partes[2]);

      if (ano < 1900 || ano > DateTime.now().year) {
        return false;
      }

      final DateTime dataNascimento = DateTime(
        ano,
        mes,
        dia,
      );

      if (dataNascimento.day != dia ||
          dataNascimento.month != mes ||
          dataNascimento.year != ano) {
        return false;
      }

      if (dataNascimento.isAfter(DateTime.now())) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // VALIDAR TELEFONE
  // ==========================================================

  bool _telefoneValido(String telefone) {
    final numeros = telefone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return numeros.length == 11;
  }

  // ==========================================================
  // CADASTRAR USUÁRIO
  // ==========================================================

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final String nome = _nomeController.text.trim();

      // CPF salvo sem máscara.
      final String cpf = _limparCpf(
        _cpfController.text,
      );

      final String dataNascimento =
          _dataController.text.trim();

      final String email =
          _emailController.text.trim().toLowerCase();

      final String telefone =
          _telefoneController.text.trim();

      final String usuario =
          _usuarioController.text.trim();

      final String senha =
          _senhaController.text;

      // ======================================================
      // VERIFICAR CPF
      // ======================================================

      if (await _databaseHelper.cpfExiste(cpf)) {
        throw 'CPF já cadastrado.';
      }

      // ======================================================
      // VERIFICAR E-MAIL
      // ======================================================

      if (await _databaseHelper.emailExiste(email)) {
        throw 'E-mail já cadastrado.';
      }

      // ======================================================
      // VERIFICAR USUÁRIO
      // ======================================================

      if (await _databaseHelper.usuarioExiste(usuario)) {
        throw 'Usuário já cadastrado.';
      }

      // ======================================================
      // CADASTRAR NA TABELA USUARIOS
      // ======================================================

      await _databaseHelper.inserirUsuario({
        'nome': nome,
        'cpf': cpf,
        'data_nascimento': dataNascimento,
        'email': email,
        'telefone': telefone,
        'usuario': usuario,
        'senha': senha,
        'tipo': 'Paciente',
      });

      // ======================================================
      // CADASTRAR TAMBÉM NA TABELA PACIENTES
      // ======================================================

      final pacientes =
          await _databaseHelper.listarPacientes();

      bool pacienteJaExiste = false;

      for (final paciente in pacientes) {
        final cpfPaciente = _limparCpf(
          paciente['cpf']?.toString() ?? '',
        );

        if (cpfPaciente == cpf) {
          pacienteJaExiste = true;
          break;
        }
      }

      if (!pacienteJaExiste) {
        await _databaseHelper.inserirPaciente({
          'nome': nome,
          'cpf': cpf,
          'telefone': telefone,
          'email': email,
          'endereco': '',
          'convenio': '',
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Conta criada com sucesso!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DECORAÇÃO
  // ==========================================================

  InputDecoration _decoracao(
    String label,
    IconData icone,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF4A90E2),
          width: 2,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text(
          'Criar Conta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      // ======================================================
      // CORPO
      // ======================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // ==================================================
              // LOGO
              // ==================================================

              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TÍTULO
              // ==================================================

              const Text(
                'Cadastre sua conta',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // NOME
              // ==================================================

              TextFormField(
                controller: _nomeController,
                textCapitalization:
                    TextCapitalization.words,

                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZÀ-ÿ\s]'),
                  ),
                ],

                decoration: _decoracao(
                  'Nome Completo *',
                  Icons.person,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe o nome.';
                  }

                  if (value.trim().length < 3) {
                    return 'Mínimo de 3 caracteres.';
                  }

                  if (value.trim().length > 100) {
                    return 'Máximo de 100 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CPF
              // ==================================================

              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,

                inputFormatters: [
                  cpfMask,
                ],

                decoration: _decoracao(
                  'CPF *',
                  Icons.badge,
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Informe o CPF.';
                  }

                  if (!_cpfValido(value)) {
                    return 'CPF inválido.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // DATA DE NASCIMENTO
              // ==================================================

              TextFormField(
                controller: _dataController,
                keyboardType: TextInputType.number,

                inputFormatters: [
                  dataMask,
                ],

                decoration: InputDecoration(
                  labelText:
                      'Data de Nascimento *',
                  hintText: 'DD/MM/AAAA',
                  prefixIcon: const Icon(
                    Icons.calendar_month,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Informe a data.';
                  }

                  if (!_dataValida(value)) {
                    return 'Data de nascimento inválida.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // E-MAIL
              // ==================================================

              TextFormField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,

                decoration: _decoracao(
                  'E-mail *',
                  Icons.email,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe o e-mail.';
                  }

                  if (!RegExp(
                    r'^[\w\.-]+@[\w\.-]+\.\w+$',
                  ).hasMatch(value.trim())) {
                    return 'E-mail inválido.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // TELEFONE
              // ==================================================

              TextFormField(
                controller: _telefoneController,
                keyboardType:
                    TextInputType.phone,

                inputFormatters: [
                  telefoneMask,
                ],

                decoration: _decoracao(
                  'Telefone *',
                  Icons.phone,
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Informe o telefone.';
                  }

                  if (!_telefoneValido(value)) {
                    return 'Telefone inválido.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // USUÁRIO
              // ==================================================

              TextFormField(
                controller: _usuarioController,

                decoration: _decoracao(
                  'Usuário *',
                  Icons.account_circle,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Informe o usuário.';
                  }

                  if (value.contains(' ')) {
                    return 'O usuário não pode conter espaços.';
                  }

                  if (value.length < 4) {
                    return 'Mínimo de 4 caracteres.';
                  }

                  if (value.length > 20) {
                    return 'Máximo de 20 caracteres.';
                  }

                  if (!RegExp(
                    r'^[a-zA-Z0-9_]+$',
                  ).hasMatch(value)) {
                    return 'Use apenas letras, números e _.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // SENHA
              // ==================================================

              TextFormField(
                controller: _senhaController,

                obscureText: !_mostrarSenha,

                decoration: InputDecoration(
                  labelText: 'Senha *',

                  prefixIcon: const Icon(
                    Icons.lock,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarSenha
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _mostrarSenha =
                            !_mostrarSenha;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Informe a senha.';
                  }

                  if (value.length < 8) {
                    return 'A senha deve ter no mínimo 8 caracteres.';
                  }

                  if (!RegExp(r'[A-Z]')
                      .hasMatch(value)) {
                    return 'A senha deve conter uma letra maiúscula.';
                  }

                  if (!RegExp(r'[a-z]')
                      .hasMatch(value)) {
                    return 'A senha deve conter uma letra minúscula.';
                  }

                  if (!RegExp(r'[0-9]')
                      .hasMatch(value)) {
                    return 'A senha deve conter um número.';
                  }

                  if (!RegExp(
                    r'[!@#$%^&*(),.?":{}|<>]',
                  ).hasMatch(value)) {
                    return 'A senha deve conter um caractere especial.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CONFIRMAR SENHA
              // ==================================================

              TextFormField(
                controller:
                    _confirmarSenhaController,

                obscureText:
                    !_mostrarConfirmarSenha,

                decoration: InputDecoration(
                  labelText:
                      'Confirmar Senha *',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmarSenha
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _mostrarConfirmarSenha =
                            !_mostrarConfirmarSenha;
                      });
                    },
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Confirme a senha.';
                  }

                  if (value !=
                      _senhaController.text) {
                    return 'As senhas não conferem.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // ==================================================
              // TIPO DE USUÁRIO
              // ==================================================

              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipo de Usuário',

                  prefixIcon: const Icon(
                    Icons.person,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'Paciente',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // BOTÃO CADASTRAR
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  onPressed:
                      _cadastrarUsuario,

                  icon: const Icon(
                    Icons.person_add,
                  ),

                  label: const Text(
                    'Cadastrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF4A90E2),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // VOLTAR PARA LOGIN
              // ==================================================

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'Já possui uma conta? Entrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
