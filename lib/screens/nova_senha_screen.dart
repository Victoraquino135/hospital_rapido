import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class NovaSenhaScreen extends StatefulWidget {
  final String identificacao;

  const NovaSenhaScreen({
    super.key,
    required this.identificacao,
  });

  @override
  State<NovaSenhaScreen> createState() => _NovaSenhaScreenState();
}

class _NovaSenhaScreenState extends State<NovaSenhaScreen> {
  // ==========================================================
  // DATABASE
  // ==========================================================

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _senhaController =
      TextEditingController();

  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  // ==========================================================
  // CONTROLE DE SENHA
  // ==========================================================

  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;
  bool _salvando = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ALTERAR SENHA
  // ==========================================================

  Future<void> _alterarSenha() async {
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    // --------------------------------------------------------
    // SENHA VAZIA
    // --------------------------------------------------------

    if (senha.isEmpty) {
      _mostrarMensagem(
        'Digite uma nova senha.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // TAMANHO
    // --------------------------------------------------------

    if (senha.length < 8) {
      _mostrarMensagem(
        'A senha deve ter no mínimo 8 caracteres.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // LETRA MAIÚSCULA
    // --------------------------------------------------------

    if (!RegExp(r'[A-Z]').hasMatch(senha)) {
      _mostrarMensagem(
        'A senha deve conter uma letra maiúscula.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // LETRA MINÚSCULA
    // --------------------------------------------------------

    if (!RegExp(r'[a-z]').hasMatch(senha)) {
      _mostrarMensagem(
        'A senha deve conter uma letra minúscula.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // NÚMERO
    // --------------------------------------------------------

    if (!RegExp(r'[0-9]').hasMatch(senha)) {
      _mostrarMensagem(
        'A senha deve conter um número.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // CARACTERE ESPECIAL
    // --------------------------------------------------------

    if (!RegExp(
      r'[!@#$%^&*(),.?":{}|<>]',
    ).hasMatch(senha)) {
      _mostrarMensagem(
        'A senha deve conter um caractere especial.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // CONFIRMAR SENHA
    // --------------------------------------------------------

    if (confirmarSenha.isEmpty) {
      _mostrarMensagem(
        'Confirme sua nova senha.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // SENHAS DIFERENTES
    // --------------------------------------------------------

    if (senha != confirmarSenha) {
      _mostrarMensagem(
        'As senhas não conferem.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // EVITAR CLIQUES DUPLICADOS
    // --------------------------------------------------------

    if (_salvando) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      // ======================================================
      // ALTERAR SENHA NO BANCO
      // ======================================================

      final sucesso = await _databaseHelper.alterarSenha(
        widget.identificacao,
        senha,
      );

      if (!mounted) {
        return;
      }

      if (sucesso) {
        setState(() {
          _salvando = false;
        });

        _mostrarMensagem(
          'Senha alterada com sucesso!',
          Colors.green,
        );

        // Pequeno atraso para o usuário visualizar
        // a mensagem antes de voltar para o login.

        await Future.delayed(
          const Duration(milliseconds: 800),
        );

        if (!mounted) {
          return;
        }

        // Volta para a tela anterior, que será
        // a tela de recuperação/login.

        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      } else {
        setState(() {
          _salvando = false;
        });

        _mostrarMensagem(
          'Não foi possível alterar a senha.',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });

      _mostrarMensagem(
        'Erro ao alterar a senha: $e',
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
  // DECORAÇÃO
  // ==========================================================

  InputDecoration _decoracaoCampo({
    required String label,
    required String hint,
    required IconData icone,
    required bool mostrarSenha,
    required VoidCallback onPressed,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icone,
        color: const Color(0xFF4A90E2),
      ),

      suffixIcon: IconButton(
        onPressed: onPressed,
        icon: Icon(
          mostrarSenha
              ? Icons.visibility_off
              : Icons.visibility,
        ),
      ),

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
          builder: (
            context,
            constraints,
          ) {
            final double largura =
                constraints.maxWidth;

            final double altura =
                constraints.maxHeight;

            final bool isDesktop =
                largura >= 800;

            final double larguraFormulario =
                isDesktop
                    ? largura * 0.48
                    : largura - 32;

            final double larguraFinal =
                larguraFormulario.clamp(
              320.0,
              700.0,
            );

            final double tamanhoLogo =
                isDesktop ? 150 : 110;

            return SizedBox(
              width: double.infinity,
              height: double.infinity,

              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding: EdgeInsets.symmetric(
                  horizontal:
                      isDesktop ? 40 : 16,
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
                        elevation:
                            isDesktop ? 8 : 5,

                        margin: EdgeInsets.zero,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(
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
                                MainAxisSize.min,

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
                                'Criar nova senha',

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
                                  fontSize:
                                      isDesktop
                                          ? 30
                                          : 26,

                                  fontWeight:
                                      FontWeight.bold,

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
                                'Digite uma nova senha para '
                                'acessar sua conta novamente.',

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
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
                              // NOVA SENHA
                              // ==================================

                              const Text(
                                'Nova senha *',

                                style:
                                    TextStyle(
                                  fontSize: 15,

                                  fontWeight:
                                      FontWeight.bold,

                                  color:
                                      Color(
                                    0xFF333333,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              TextField(
                                controller:
                                    _senhaController,

                                obscureText:
                                    !_mostrarSenha,

                                textInputAction:
                                    TextInputAction
                                        .next,

                                decoration:
                                    _decoracaoCampo(
                                  label:
                                      'Nova senha',

                                  hint:
                                      'Digite sua nova senha',

                                  icone:
                                      Icons.lock,

                                  mostrarSenha:
                                      _mostrarSenha,

                                  onPressed: () {
                                    setState(() {
                                      _mostrarSenha =
                                          !_mostrarSenha;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              const Text(
                                'Mínimo de 8 caracteres, com '
                                'maiúscula, minúscula, número '
                                'e caractere especial.',

                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // ==================================
                              // CONFIRMAR SENHA
                              // ==================================

                              const Text(
                                'Confirmar nova senha *',

                                style:
                                    TextStyle(
                                  fontSize: 15,

                                  fontWeight:
                                      FontWeight.bold,

                                  color:
                                      Color(
                                    0xFF333333,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              TextField(
                                controller:
                                    _confirmarSenhaController,

                                obscureText:
                                    !_mostrarConfirmarSenha,

                                textInputAction:
                                    TextInputAction
                                        .done,

                                onSubmitted: (_) {
                                  _alterarSenha();
                                },

                                decoration:
                                    _decoracaoCampo(
                                  label:
                                      'Confirmar senha',

                                  hint:
                                      'Digite novamente a senha',

                                  icone:
                                      Icons
                                          .lock_outline,

                                  mostrarSenha:
                                      _mostrarConfirmarSenha,

                                  onPressed: () {
                                    setState(() {
                                      _mostrarConfirmarSenha =
                                          !_mostrarConfirmarSenha;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(
                                height: 30,
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
                                    ElevatedButton(
                                  onPressed:
                                      _salvando
                                          ? null
                                          : _alterarSenha,

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

                                  child:
                                      _salvando
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,
                                                color:
                                                    Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'ALTERAR SENHA',

                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    17,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
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
                                onPressed: () {
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
                                  'Voltar',

                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF4A90E2,
                                    ),

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight.bold,
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