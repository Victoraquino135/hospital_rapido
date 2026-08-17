import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../database/database_helper.dart';

class PerfilPacienteScreen extends StatefulWidget {
  // ID do usuário que está logado
  final int idUsuario;

  const PerfilPacienteScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<PerfilPacienteScreen> createState() =>
      _PerfilPacienteScreenState();
}

class _PerfilPacienteScreenState
    extends State<PerfilPacienteScreen> {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController =
      TextEditingController();

  final TextEditingController _cpfController =
      TextEditingController();

  final TextEditingController _telefoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  bool _carregando = true;
  bool _salvando = false;

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

  @override
  void initState() {
    super.initState();

    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();

    super.dispose();
  }

    // ==========================================================
  // CARREGAR DADOS DO USUÁRIO
  // ==========================================================

  Future<void> _carregarPerfil() async {
    try {
      final usuario =
          await _databaseHelper.buscarUsuarioPorId(
        widget.idUsuario,
      );

      if (!mounted) return;

      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Não foi possível encontrar os dados do usuário.",
            ),
          ),
        );

        setState(() {
          _carregando = false;
        });

        return;
      }

      _nomeController.text =
          usuario['nome']?.toString() ?? '';

      _cpfController.text =
          usuario['cpf']?.toString() ?? '';

      _telefoneController.text =
          usuario['telefone']?.toString() ?? '';

      _emailController.text =
          usuario['email']?.toString() ?? '';

      setState(() {
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Erro ao carregar perfil: $e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // SALVAR ALTERAÇÕES
  // ==========================================================

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _databaseHelper.atualizarUsuario(
        widget.idUsuario,
        {
          'nome': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Perfil atualizado com sucesso!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Erro ao salvar perfil: $e",
          ),
        ),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        centerTitle: true,
        title: const Text(
          "Meu Perfil",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Form(
                key: _formKey,

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF4A90E2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Meu Perfil",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(20),

                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nomeController,
                              textCapitalization:
                                  TextCapitalization.words,

                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-ZÀ-ÿ\s]"),
                                ),
                              ],

                              decoration: InputDecoration(
                                labelText: "Nome Completo",
                                prefixIcon:
                                    const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "Informe o nome.";
                                }

                                if (value.trim().length < 3) {
                                  return "Nome inválido.";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _cpfController,
                              keyboardType:
                                  TextInputType.number,

                              inputFormatters: [
                                cpfMask,
                              ],

                              decoration: InputDecoration(
                                labelText: "CPF",
                                prefixIcon:
                                    const Icon(Icons.badge),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return "Informe o CPF.";
                                }

                                if (value.length != 14) {
                                  return "CPF inválido.";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            TextFormField(
                              controller:
                                  _telefoneController,
                              keyboardType:
                                  TextInputType.phone,

                              inputFormatters: [
                                telefoneMask,
                              ],

                              decoration: InputDecoration(
                                labelText: "Telefone",
                                prefixIcon:
                                    const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return "Informe o telefone.";
                                }

                                if (value.length != 15) {
                                  return "Telefone inválido.";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,

                              decoration: InputDecoration(
                                labelText: "E-mail",
                                prefixIcon:
                                    const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "Informe o e-mail.";
                                }

                                if (!RegExp(
                                  r'^[\w\.-]+@[\w\.-]+\.\w+$',
                                ).hasMatch(
                                  value.trim(),
                                )) {
                                  return "E-mail inválido.";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                                                        SizedBox(
                              width: double.infinity,
                              height: 55,

                              child: ElevatedButton.icon(
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF4A90E2),
                                  foregroundColor:
                                      Colors.white,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                ),

                                icon: _salvando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save,
                                      ),

                                label: Text(
                                  _salvando
                                      ? "Salvando..."
                                      : "Salvar Perfil",

                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                onPressed: _salvando
                                    ? null
                                    : () {
                                        _salvarPerfil();
                                      },
                              ),
                            ),
                          ],
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
 