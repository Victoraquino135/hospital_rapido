import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'verificar_codigo_screen.dart';
import '../database/database_helper.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() =>
      _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState
    extends State<RecuperarSenhaScreen> {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final TextEditingController identificacaoController =
      TextEditingController();

  // ==========================================================
  // CONTROLE
  // ==========================================================

  bool verificandoDados = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    identificacaoController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ENVIAR CÓDIGO
  // ==========================================================

  Future<void> _enviarCodigo() async {
    final identificacao =
        identificacaoController.text.trim();

    // ========================================================
    // CAMPO VAZIO
    // ========================================================

    if (identificacao.isEmpty) {
      _mostrarMensagem(
        'Digite seu CPF ou e-mail.',
        Colors.red,
      );

      return;
    }

    // ========================================================
    // EVITAR CLIQUES DUPLICADOS
    // ========================================================

    if (verificandoDados) {
      return;
    }

    setState(() {
      verificandoDados = true;
    });

    try {
      // ======================================================
      // ACESSAR BANCO DE DADOS
      // ======================================================

      final databaseHelper = DatabaseHelper.instance;

      final usuarios =
          await databaseHelper.listarUsuarios();

      Map<String, dynamic>? usuarioEncontrado;

      // ======================================================
      // VERIFICAR SE É E-MAIL
      // ======================================================

      if (identificacao.contains('@')) {
        final emailDigitado =
            identificacao.toLowerCase().trim();

        for (final usuario in usuarios) {
          final emailBanco =
              usuario['email']
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  '';

          if (emailBanco == emailDigitado) {
            usuarioEncontrado = usuario;
            break;
          }
        }
      }

      // ======================================================
      // VERIFICAR SE É CPF
      // ======================================================

      else {
        final cpfDigitado =
            identificacao.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        // CPF precisa possuir 11 números
        if (cpfDigitado.length == 11) {
          for (final usuario in usuarios) {
            final cpfBanco =
                usuario['cpf']
                        ?.toString()
                        .replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        ) ??
                    '';

            if (cpfBanco == cpfDigitado) {
              usuarioEncontrado = usuario;
              break;
            }
          }
        }
      }

      // ======================================================
      // USUÁRIO NÃO ENCONTRADO
      // ======================================================

      if (usuarioEncontrado == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          verificandoDados = false;
        });

        _mostrarMensagem(
          'CPF ou e-mail não encontrado.',
          Colors.red,
        );

        return;
      }

      // ======================================================
      // USUÁRIO ENCONTRADO
      // ======================================================

      if (!mounted) {
        return;
      }

      setState(() {
        verificandoDados = false;
      });

      // ======================================================
      // MENSAGEM
      // ======================================================

      _mostrarMensagem(
        'Dados encontrados! Verifique o código.',
        const Color(0xFF4A90E2),
      );

      // Pequeno atraso para o usuário visualizar a mensagem.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      // ======================================================
      // IR PARA VERIFICAR CÓDIGO
      // ======================================================

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCodigoScreen(
            identificacao: identificacao,
          ),
        ),
      );
    } catch (e) {
      // ======================================================
      // ERRO
      // ======================================================

      if (!mounted) {
        return;
      }

      setState(() {
        verificandoDados = false;
      });

      _mostrarMensagem(
        'Erro ao verificar os dados.',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // MENSAGEM
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
  // DECORAÇÃO DO CAMPO
  // ==========================================================

  InputDecoration _decoracaoCampo({
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icone,
        color: const Color(0xFF4A90E2),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.grey,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
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
      backgroundColor:
          const Color(0xFFF5F5F5),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final double largura =
                constraints.maxWidth;

            final double altura =
                constraints.maxHeight;

            // =================================================
            // PC OU CELULAR
            // =================================================

            final bool isDesktop =
                largura >= 800;

            // =================================================
            // LARGURA DO FORMULÁRIO
            // =================================================

            final double larguraFormulario =
                isDesktop
                    ? largura * 0.48
                    : largura - 32;

            final double larguraFinal =
                larguraFormulario.clamp(
              320.0,
              700.0,
            );

            // =================================================
            // TAMANHO DA LOGO
            // =================================================

            final double tamanhoLogo =
                isDesktop ? 150 : 110;

            return SizedBox(
              width: double.infinity,
              height: double.infinity,

              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      isDesktop
                          ? 40
                          : 16,
                  vertical: 20,
                ),

                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        altura - 40,
                  ),

                  child: Center(
                    child: SizedBox(
                      width: larguraFinal,

                      child: Card(
                        elevation:
                            isDesktop
                                ? 8
                                : 5,

                        margin:
                            EdgeInsets.zero,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child: Padding(
                          padding:
                              EdgeInsets
                                  .symmetric(
                            horizontal:
                                isDesktop
                                    ? 55
                                    : 24,
                            vertical:
                                isDesktop
                                    ? 40
                                    : 28,
                          ),

                          child: Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min,

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,

                            children: [

                              // ==================================
                              // LOGO
                              // ==================================

                              Semantics(
                                label:
                                    'Logo do Hospital Rápido',

                                child:
                                    Image.asset(
                                  'assets/images/logo.png',

                                  height:
                                      tamanhoLogo,

                                  fit:
                                      BoxFit.contain,
                                ),
                              ),

                              SizedBox(
                                height:
                                    isDesktop
                                        ? 20
                                        : 14,
                              ),

                              // ==================================
                              // TÍTULO
                              // ==================================

                              Text(
                                'Recuperar sua senha',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 30
                                          : 26,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  color:
                                      const Color(
                                    0xFF333333,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              // ==================================
                              // DESCRIÇÃO
                              // ==================================

                              Text(
                                'Digite seu CPF ou e-mail cadastrado '
                                'para receber um código de recuperação '
                                'pelo WhatsApp.',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 16
                                          : 14,

                                  color:
                                      Colors.grey,

                                  height: 1.4,
                                ),
                              ),

                              SizedBox(
                                height:
                                    isDesktop
                                        ? 35
                                        : 28,
                              ),

                              // ==================================
                              // LABEL
                              // ==================================

                              const Text(
                                'E-mail ou CPF *',

                                style:
                                    TextStyle(
                                  fontSize: 15,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  color:
                                      Color(
                                    0xFF333333,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // ==================================
                              // CAMPO
                              // ==================================

                              TextField(
                                controller:
                                    identificacaoController,

                                keyboardType:
                                    TextInputType
                                        .emailAddress,

                                textInputAction:
                                    TextInputAction
                                        .done,

                                enabled:
                                    !verificandoDados,

                                onSubmitted:
                                    (_) {
                                  _enviarCodigo();
                                },

                                inputFormatters: [
                                  _EmailOuCpfFormatter(),
                                ],

                                decoration:
                                    _decoracaoCampo(
                                  label:
                                      'E-mail ou CPF',

                                  hint:
                                      'ex: paciente@email.com '
                                      'ou 123.456.789-00',

                                  icone:
                                      Icons.person,
                                ),
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              // ==================================
                              // BOTÃO
                              // ==================================

                              SizedBox(
                                width:
                                    double.infinity,

                                height:
                                    isDesktop
                                        ? 60
                                        : 55,

                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      verificandoDados
                                          ? null
                                          : _enviarCodigo,

                                  icon:
                                      verificandoDados
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,
                                                color:
                                                    Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send,
                                            ),

                                  label:
                                      Text(
                                    verificandoDados
                                        ? 'VERIFICANDO...'
                                        : 'ENVIAR CÓDIGO',

                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xFF4A90E2,
                                    ),

                                    foregroundColor:
                                        Colors.white,

                                    disabledBackgroundColor:
                                        Colors.grey,

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
                                ),
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // ==================================
                              // VOLTAR
                              // ==================================

                              TextButton.icon(
                                onPressed:
                                    verificandoDados
                                        ? null
                                        : () {
                                            Navigator.pop(
                                              context,
                                            );
                                          },

                                icon:
                                    const Icon(
                                  Icons.arrow_back,
                                  color:
                                      Color(
                                    0xFF4A90E2,
                                  ),
                                ),

                                label:
                                    const Text(
                                  'Voltar para o Login',

                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF4A90E2,
                                    ),

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
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
// FORMATADOR E-MAIL OU CPF
// ============================================================
//
// Se começar com números, permite CPF e aplica máscara.
//
// Exemplo:
//
// 52998224725
//
// vira:
//
// 529.982.247-25
//
// Se o usuário começar a digitar letras,
// funciona como e-mail normalmente.
// ============================================================

class _EmailOuCpfFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text;

    // ========================================================
    // SE TIVER LETRAS OU @, TRATA COMO E-MAIL
    // ========================================================

    if (RegExp(r'[a-zA-Z@]').hasMatch(texto)) {
      return newValue;
    }

    // ========================================================
    // PEGAR SOMENTE NÚMEROS
    // ========================================================

    final numeros =
        texto.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // ========================================================
    // LIMITE CPF
    // ========================================================

    if (numeros.length > 11) {
      return oldValue;
    }

    // ========================================================
    // FORMATAR CPF
    // ========================================================

    String formatado = numeros;

    if (numeros.length > 3) {
      formatado =
          '${numeros.substring(0, 3)}.'
          '${numeros.substring(3)}';
    }

    if (numeros.length > 6) {
      formatado =
          '${numeros.substring(0, 3)}.'
          '${numeros.substring(3, 6)}.'
          '${numeros.substring(6)}';
    }

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