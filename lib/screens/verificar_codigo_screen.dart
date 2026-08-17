import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class VerificarCodigoScreen extends StatefulWidget {
  final String identificacao;

  const VerificarCodigoScreen({
    super.key,
    required this.identificacao,
  });

  @override
  State<VerificarCodigoScreen> createState() =>
      _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState
    extends State<VerificarCodigoScreen> {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final TextEditingController codigoController =
      TextEditingController();

  // ==========================================================
  // CÓDIGO TEMPORÁRIO
  // ==========================================================
  //
  // Por enquanto estamos usando um código de teste.
  //
  // Mais para frente ele será gerado automaticamente
  // pelo sistema e enviado pelo WhatsApp.
  //

  final String codigoTeste = '123456';

  // ==========================================================
  // CONTROLE
  // ==========================================================

  bool verificando = false;
  bool reenviando = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  // ==========================================================
  // VERIFICAR CÓDIGO
  // ==========================================================

  Future<void> _verificarCodigo() async {
    final codigo = codigoController.text.trim();

    // --------------------------------------------------------
    // CAMPO VAZIO
    // --------------------------------------------------------

    if (codigo.isEmpty) {
      _mostrarMensagem(
        'Digite o código de verificação.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // TAMANHO
    // --------------------------------------------------------

    if (codigo.length != 6) {
      _mostrarMensagem(
        'O código deve possuir 6 números.',
        Colors.red,
      );

      return;
    }

    // --------------------------------------------------------
    // EVITAR CLIQUES DUPLICADOS
    // --------------------------------------------------------

    if (verificando) {
      return;
    }

    setState(() {
      verificando = true;
    });

    // Pequeno atraso apenas para simular a verificação.
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    // --------------------------------------------------------
    // VERIFICAR CÓDIGO
    // --------------------------------------------------------

    if (codigo == codigoTeste) {
      setState(() {
        verificando = false;
      });

      _mostrarMensagem(
        'Código verificado com sucesso!',
        Colors.green,
      );

      // ------------------------------------------------------
      // PRÓXIMA ETAPA
      // ------------------------------------------------------
      //
      // Amanhã vamos criar:
      //
      // NovaSenhaScreen
      //
      // e passar a identificação do usuário para ela.
      //
      // Por enquanto não vamos navegar para uma tela
      // que ainda não existe.
      //
    } else {
      setState(() {
        verificando = false;
      });

      _mostrarMensagem(
        'Código incorreto. Tente novamente.',
        Colors.red,
      );

      codigoController.clear();
    }
  }

  // ==========================================================
  // REENVIAR CÓDIGO
  // ==========================================================

  Future<void> _reenviarCodigo() async {
    if (reenviando) {
      return;
    }

    setState(() {
      reenviando = true;
    });

    // --------------------------------------------------------
    // SIMULAÇÃO
    // --------------------------------------------------------
    //
    // Futuramente:
    //
    // Backend
    //    ↓
    // Banco de dados
    //    ↓
    // WhatsApp
    //
    // --------------------------------------------------------

    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      reenviando = false;
    });

    _mostrarMensagem(
      'Um novo código foi solicitado.',
      const Color(0xFF4A90E2),
    );
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

  InputDecoration _decoracaoCampo() {
    return InputDecoration(
      labelText: 'Código de verificação',
      hintText: 'Digite os 6 números',

      prefixIcon: const Icon(
        Icons.lock_outline,
        color: Color(0xFF4A90E2),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
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

            // ------------------------------------------------
            // PC OU CELULAR
            // ------------------------------------------------

            final bool isDesktop =
                largura >= 800;

            // ------------------------------------------------
            // LARGURA
            // ------------------------------------------------

            final double larguraFormulario =
                isDesktop
                    ? largura * 0.48
                    : largura - 32;

            final double larguraFinal =
                larguraFormulario.clamp(
              320.0,
              700.0,
            );

            // ------------------------------------------------
            // LOGO
            // ------------------------------------------------

            final double tamanhoLogo =
                isDesktop ? 150 : 110;

            return SizedBox(
              width: double.infinity,
              height: double.infinity,

              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      isDesktop ? 40 : 16,
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
                            isDesktop ? 8 : 5,

                        margin:
                            EdgeInsets.zero,

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
                                'Verificar código',

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
                                'Enviamos um código de 6 dígitos '
                                'para o WhatsApp cadastrado.',

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
                              // CAMPO
                              // ==================================

                              const Text(
                                'Código de verificação *',

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
                                    codigoController,

                                keyboardType:
                                    TextInputType
                                        .number,

                                textInputAction:
                                    TextInputAction
                                        .done,

                                maxLength: 6,

                                textAlign:
                                    TextAlign.center,

                                style:
                                    const TextStyle(
                                  fontSize: 22,

                                  fontWeight:
                                      FontWeight.bold,

                                  letterSpacing: 5,
                                ),

                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                    6,
                                  ),
                                ],

                                onSubmitted: (_) {
                                  _verificarCodigo();
                                },

                                decoration:
                                    _decoracaoCampo()
                                        .copyWith(
                                  counterText: '',
                                ),
                              ),

                              const SizedBox(
                                height: 25,
                              ),

                              // ==================================
                              // VERIFICAR
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
                                      verificando
                                          ? null
                                          : _verificarCodigo,

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
                                      verificando
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
                                              'VERIFICAR',

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
                              // REENVIAR
                              // ==================================

                              Text(
                                'Não recebeu o código?',

                                textAlign:
                                    TextAlign.center,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,

                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              TextButton(
                                onPressed:
                                    reenviando
                                        ? null
                                        : _reenviarCodigo,

                                child:
                                    reenviando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth:
                                                  2,
                                            ),
                                          )
                                        : const Text(
                                            'Reenviar código',

                                            style:
                                                TextStyle(
                                              color:
                                                  Color(
                                                0xFF4A90E2,
                                              ),

                                              fontWeight:
                                                  FontWeight
                                                      .bold,

                                              fontSize: 15,
                                            ),
                                          ),
                              ),

                              const SizedBox(
                                height: 10,
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
                                  'Voltar para o Login',

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