import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import 'recuperar_senha_screen.dart';
import 'criar_conta_screen.dart';
import 'paciente_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================================
  // BANCO DE DADOS
  // ==========================================================

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController usuarioController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  // ==========================================================
  // CONTROLE DA SENHA
  // ==========================================================

  bool mostrarSenha = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SOMENTE NÚMEROS
  // ==========================================================

  String _somenteNumeros(String texto) {
    return texto.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // ==========================================================
  // VERIFICAR SE O LOGIN PARECE CPF
  // ==========================================================

  bool _pareceCpf(String texto) {
    final valor = texto.trim();

    if (valor.isEmpty) {
      return false;
    }

    // Se tiver letras, consideramos que é usuário.
    if (RegExp(r'[a-zA-Z]').hasMatch(valor)) {
      return false;
    }

    // Permite somente números, ponto e hífen.
    if (!RegExp(r'^[0-9.\-]+$').hasMatch(valor)) {
      return false;
    }

    final numeros = _somenteNumeros(valor);

    return numeros.isNotEmpty && numeros.length <= 11;
  }

  // ==========================================================
  // VALIDAR CPF
  // ==========================================================

  bool _cpfValido(String cpf) {
    final numeros = _somenteNumeros(cpf);

    // CPF precisa ter exatamente 11 números.
    if (numeros.length != 11) {
      return false;
    }

    // Não permite CPFs com todos os números iguais.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(numeros)) {
      return false;
    }

    // --------------------------------------------------------
    // PRIMEIRO DÍGITO
    // --------------------------------------------------------

    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += int.parse(numeros[i]) * (10 - i);
    }

    int resto = soma % 11;

    int primeiroDigito = resto < 2 ? 0 : 11 - resto;

    if (primeiroDigito != int.parse(numeros[9])) {
      return false;
    }

    // --------------------------------------------------------
    // SEGUNDO DÍGITO
    // --------------------------------------------------------

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
  // FAZER LOGIN
  // ==========================================================

  Future<void> _fazerLogin() async {
    final String usuario = usuarioController.text.trim();
    final String senha = senhaController.text;

    // --------------------------------------------------------
    // USUÁRIO / CPF
    // --------------------------------------------------------

    if (usuario.isEmpty) {
      _mostrarMensagem(
        'Digite seu usuário ou CPF.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // VERIFICAR SE O LOGIN É CPF
    // --------------------------------------------------------

    final bool loginComCpf = _pareceCpf(usuario);

    String valorLogin = usuario;

    if (loginComCpf) {
      final String cpf = _somenteNumeros(usuario);

      // CPF incompleto.
      if (cpf.length != 11) {
        _mostrarMensagem(
          'Digite um CPF completo com 11 números.',
          Colors.red,
        );

        return;
      }

      // CPF matematicamente inválido.
      if (!_cpfValido(cpf)) {
        _mostrarMensagem(
          'Digite um CPF válido.',
          Colors.red,
        );

        return;
      }

      // O banco recebe o CPF sem máscara.
      valorLogin = cpf;
    }

    // --------------------------------------------------------
    // SENHA
    // --------------------------------------------------------

    if (senha.isEmpty) {
      _mostrarMensagem(
        'Digite sua senha.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // TENTAR LOGIN
    // --------------------------------------------------------

    try {
      final usuarioLogado = await _databaseHelper.login(
        valorLogin,
        senha,
      );

      if (!mounted) {
        return;
      }

      // ------------------------------------------------------
      // LOGIN INVÁLIDO
      // ------------------------------------------------------

      if (usuarioLogado == null) {
        _mostrarMensagem(
          'Usuário/CPF ou senha inválidos.',
          Colors.red,
        );

        return;
      }

      // ------------------------------------------------------
      // PEGAR ID DO USUÁRIO
      // ------------------------------------------------------

      final dynamic idBanco = usuarioLogado['id'];

      if (idBanco == null) {
        _mostrarMensagem(
          'Erro: usuário não possui ID.',
          Colors.red,
        );

        return;
      }

      final int idUsuario = idBanco is int
          ? idBanco
          : int.parse(idBanco.toString());

      // ------------------------------------------------------
      // MVP ATUAL
      // ------------------------------------------------------
      //
      // O Hospital Rápido está trabalhando neste momento
      // somente com o fluxo do PACIENTE.
      //
      // Não teremos mais direcionamento para:
      // - Enfermeiro
      // - Médico
      // - Administrador
      //
      // ------------------------------------------------------

      final String tipo =
          usuarioLogado['tipo']?.toString().trim() ?? '';

      if (tipo.isNotEmpty && tipo != 'Paciente') {
        _mostrarMensagem(
          'Este acesso está disponível somente para pacientes.',
          Colors.orange,
        );

        return;
      }

      // ------------------------------------------------------
      // ENTRAR NO SISTEMA DO PACIENTE
      // ------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PacienteScreen(
            idUsuario: idUsuario,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Erro ao realizar login: $e',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // ESQUECI MINHA SENHA
  // ==========================================================

  void _esqueciMinhaSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecuperarSenhaScreen(),
      ),
    );
  }

  // ==========================================================
  // CRIAR CONTA
  // ==========================================================

  void _abrirCriarConta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CriarContaScreen(),
      ),
    );
  }

  // ==========================================================
  // MOSTRAR MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
    String mensagem,
    Color cor,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cor,
        content: Text(mensagem),
      ),
    );
  }

  // ==========================================================
  // DECORAÇÃO DOS CAMPOS
  // ==========================================================

  InputDecoration _decoracaoCampo({
    required String label,
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icone,
        color: const Color(0xFF4A90E2),
      ),

      suffixIcon: suffixIcon,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.grey,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF4A90E2),
          width: 2,
        ),
      ),

      filled: true,
      fillColor: Colors.white,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double largura = constraints.maxWidth;
            final double altura = constraints.maxHeight;

            final bool isDesktop = largura >= 800;

            // ------------------------------------------------
            // LARGURA DO FORMULÁRIO
            // ------------------------------------------------

            final double larguraFormulario = isDesktop
                ? largura * 0.48
                : largura - 32;

            final double larguraFinal =
                larguraFormulario.clamp(320.0, 700.0);

            // ------------------------------------------------
            // TAMANHO DA LOGO
            // ------------------------------------------------

            final double tamanhoLogo =
                isDesktop ? 150.0 : 110.0;

            // ------------------------------------------------
            // ESPAÇAMENTO
            // ------------------------------------------------

            final double espacamentoSuperior =
                isDesktop ? 25.0 : 10.0;

            return SizedBox(
              width: double.infinity,
              height: double.infinity,

              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 16,
                  vertical: 20,
                ),

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: altura - 40,
                  ),

                  child: Center(
                    child: SizedBox(
                      width: larguraFinal,

                      child: Card(
                        elevation: isDesktop ? 8 : 5,

                        margin: EdgeInsets.zero,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                isDesktop ? 55 : 24,
                            vertical:
                                isDesktop ? 40 : 28,
                          ),

                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,

                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,

                            children: [
                              SizedBox(
                                height:
                                    espacamentoSuperior,
                              ),

                              // =================================
                              // LOGO
                              // =================================

                              Semantics(
                                label:
                                    'Logo do Hospital Rápido',

                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: tamanhoLogo,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              SizedBox(
                                height:
                                    isDesktop ? 18 : 12,
                              ),

                              // =================================
                              // NOME
                              // =================================

                              Text(
                                'Hospital Rápido',

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
                                  fontSize:
                                      isDesktop ? 36 : 30,

                                  fontWeight:
                                      FontWeight.bold,

                                  color:
                                      const Color(
                                    0xFF333333,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              // =================================
                              // DESCRIÇÃO
                              // =================================

                              Text(
                                'Sistema de gerenciamento hospitalar',

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
                                  fontSize:
                                      isDesktop ? 17 : 15,

                                  color: Colors.grey,
                                ),
                              ),

                              SizedBox(
                                height:
                                    isDesktop ? 40 : 30,
                              ),

                              // =================================
                              // USUÁRIO OU CPF
                              // =================================

                              const Text(
                                'Usuário ou CPF',

                                style: TextStyle(
                                  fontSize: 15,

                                  fontWeight:
                                      FontWeight.bold,

                                  color:
                                      Color(0xFF333333),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              TextField(
                                controller:
                                    usuarioController,

                                keyboardType:
                                    TextInputType.text,

                                textInputAction:
                                    TextInputAction.next,

                                inputFormatters: [
                                  _CpfOuUsuarioFormatter(),
                                ],

                                decoration:
                                    _decoracaoCampo(
                                  label:
                                      'Usuário ou CPF',

                                  hint:
                                      'Digite seu usuário ou CPF',

                                  icone:
                                      Icons.person,
                                ),
                              ),

                              const SizedBox(
                                height: 22,
                              ),

                              // =================================
                              // SENHA
                              // =================================

                              const Text(
                                'Senha',

                                style: TextStyle(
                                  fontSize: 15,

                                  fontWeight:
                                      FontWeight.bold,

                                  color:
                                      Color(0xFF333333),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              TextField(
                                controller:
                                    senhaController,

                                obscureText:
                                    !mostrarSenha,

                                textInputAction:
                                    TextInputAction.done,

                                onSubmitted: (_) {
                                  _fazerLogin();
                                },

                                decoration:
                                    _decoracaoCampo(
                                  label: 'Senha',

                                  hint:
                                      'Digite sua senha',

                                  icone:
                                      Icons.lock,

                                  suffixIcon:
                                      IconButton(
                                    tooltip:
                                        mostrarSenha
                                            ? 'Ocultar senha'
                                            : 'Mostrar senha',

                                    icon: Icon(
                                      mostrarSenha
                                          ? Icons.visibility
                                          : Icons
                                              .visibility_off,
                                    ),

                                    onPressed: () {
                                      setState(() {
                                        mostrarSenha =
                                            !mostrarSenha;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              // =================================
                              // ESQUECI MINHA SENHA
                              // =================================

                              Align(
                                alignment:
                                    Alignment.centerRight,

                                child: TextButton(
                                  onPressed:
                                      _esqueciMinhaSenha,

                                  child: const Text(
                                    'Esqueci minha senha',

                                    style: TextStyle(
                                      color:
                                          Color(
                                        0xFF4A90E2,
                                      ),

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              // =================================
                              // ENTRAR
                              // =================================

                              SizedBox(
                                width:
                                    double.infinity,

                                height:
                                    isDesktop ? 60 : 55,

                                child:
                                    ElevatedButton(
                                  onPressed:
                                      _fazerLogin,

                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xFF4A90E2,
                                    ),

                                    foregroundColor:
                                        Colors.white,

                                    elevation: 2,

                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                  ),

                                  child: Text(
                                    'ENTRAR',

                                    style: TextStyle(
                                      fontSize:
                                          isDesktop
                                              ? 19
                                              : 18,

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // =================================
                              // CRIAR CONTA
                              // =================================

                              Wrap(
                                alignment:
                                    WrapAlignment.center,

                                children: [
                                  const Text(
                                    'Ainda não possui uma conta? ',

                                    style: TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap:
                                        _abrirCriarConta,

                                    child: const Text(
                                      'Criar conta',

                                      style:
                                          TextStyle(
                                        color:
                                            Color(
                                          0xFF4A90E2,
                                        ),

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              // =================================
                              // VERSÃO
                              // =================================

                              const Text(
                                'v1.0.0',

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
                                  color:
                                      Colors.grey,

                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// FORMATADOR CPF OU USUÁRIO
// ============================================================
//
// Usuário:
// teste_01
//
// CPF:
// 52998224725
//
// vira automaticamente:
//
// 529.982.247-25
//
// ============================================================

class _CpfOuUsuarioFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String texto = newValue.text;

    // --------------------------------------------------------
    // SE TIVER LETRAS
    // --------------------------------------------------------
    //
    // Trata como usuário e não aplica máscara.
    //

    if (RegExp(r'[a-zA-Z]').hasMatch(texto)) {
      return newValue;
    }

    // --------------------------------------------------------
    // PEGAR SOMENTE NÚMEROS
    // --------------------------------------------------------

    final String numeros =
        texto.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // --------------------------------------------------------
    // LIMITE DE 11 NÚMEROS
    // --------------------------------------------------------

    if (numeros.length > 11) {
      return oldValue;
    }

    // --------------------------------------------------------
    // FORMATAR CPF
    // --------------------------------------------------------

    String formatado = numeros;

    // 123.
    if (numeros.length > 3) {
      formatado =
          '${numeros.substring(0, 3)}.'
          '${numeros.substring(3)}';
    }

    // 123.456.
    if (numeros.length > 6) {
      formatado =
          '${numeros.substring(0, 3)}.'
          '${numeros.substring(3, 6)}.'
          '${numeros.substring(6)}';
    }

    // 123.456.789-01
    if (numeros.length > 9) {
      formatado =
          '${numeros.substring(0, 3)}.'
          '${numeros.substring(3, 6)}.'
          '${numeros.substring(6, 9)}-'
          '${numeros.substring(9)}';
    }

    return TextEditingValue(
      text: formatado,

      selection:
          TextSelection.collapsed(
        offset: formatado.length,
      ),
    );
  }
}