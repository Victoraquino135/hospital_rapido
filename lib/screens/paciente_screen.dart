import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'login_screen.dart';
import 'sobre_screen.dart';
import 'agendar_consulta_screen.dart';
import 'minhas_consultas_screen.dart';
import 'fila_atendimento_screen.dart';
import 'perfil_paciente_screen.dart';

class PacienteScreen extends StatefulWidget {
  // ==========================================================
  // ID DO USUÁRIO QUE FEZ LOGIN
  // ==========================================================

  final int idUsuario;

  const PacienteScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<PacienteScreen> createState() =>
      _PacienteScreenState();
}

class _PacienteScreenState extends State<PacienteScreen> {
  // ==========================================================
  // BANCO DE DADOS
  // ==========================================================

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // ==========================================================
  // DADOS DO USUÁRIO
  // ==========================================================

  String nomePaciente = 'Paciente';

  bool carregando = true;

  // ==========================================================
  // PRÓXIMA CONSULTA
  // ==========================================================

  Map<String, dynamic>? proximaConsulta;

  // ==========================================================
  // ID DO PACIENTE
  // ==========================================================

  int? pacienteId;

  // ==========================================================
  // INICIALIZAÇÃO
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _carregarDados();
  }

  // ==========================================================
  // CARREGAR DADOS
  // ==========================================================

  Future<void> _carregarDados() async {
    try {
      // ========================================================
      // BUSCAR USUÁRIO
      // ========================================================

      final usuario =
          await _databaseHelper.buscarUsuarioPorId(
        widget.idUsuario,
      );

      if (!mounted) {
        return;
      }

      if (usuario == null) {
        setState(() {
          carregando = false;
        });

        return;
      }

      // ========================================================
      // NOME DO USUÁRIO
      // ========================================================

      final nome =
          usuario['nome']?.toString().trim();

      if (nome != null && nome.isNotEmpty) {
        nomePaciente = nome;
      }

      // ========================================================
      // BUSCAR PACIENTE PELO CPF
      // ========================================================

      final cpf =
          usuario['cpf']?.toString().trim() ?? '';

      if (cpf.isNotEmpty) {
        final paciente =
            await _databaseHelper.buscarPacientePorCpf(
          cpf,
        );

        if (!mounted) {
          return;
        }

        if (paciente != null) {
          final id = paciente['id'];

          if (id is int) {
            pacienteId = id;
          } else if (id != null) {
            pacienteId =
                int.tryParse(id.toString());
          }

          // ====================================================
          // BUSCAR CONSULTA
          // ====================================================

          if (pacienteId != null) {
            await _buscarProximaConsulta(
              pacienteId!,
            );
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar informações: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // BUSCAR PRÓXIMA CONSULTA
  // ==========================================================

  Future<void> _buscarProximaConsulta(
    int idPaciente,
  ) async {
    try {
      final consultas =
          await _databaseHelper.listarConsultas();

      if (consultas.isEmpty) {
        return;
      }

      // ========================================================
      // FILTRAR CONSULTAS DO PACIENTE
      // ========================================================

      final consultasPaciente =
          consultas.where((consulta) {
        final valor =
            consulta['paciente_id'];

        int? id;

        if (valor is int) {
          id = valor;
        } else if (valor != null) {
          id = int.tryParse(
            valor.toString(),
          );
        }

        if (id != idPaciente) {
          return false;
        }

        final status =
            consulta['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        // Não mostrar consultas canceladas.
        if (status.contains('cancel')) {
          return false;
        }

        return true;
      }).toList();

      if (consultasPaciente.isEmpty) {
        return;
      }

      // ========================================================
      // ORDENAR POR ID
      // ========================================================

      consultasPaciente.sort((a, b) {
        final idA =
            int.tryParse(
                  a['id']?.toString() ?? '',
                ) ??
                0;

        final idB =
            int.tryParse(
                  b['id']?.toString() ?? '',
                ) ??
                0;

        return idA.compareTo(idB);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        proximaConsulta =
            consultasPaciente.first;
      });
    } catch (e) {
      // Não interrompe a tela caso a consulta não possa
      // ser carregada.
      proximaConsulta = null;
    }
  }

  // ==========================================================
  // SAIR DO SISTEMA
  // ==========================================================

  void _sair(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ==========================================================
  // CONFIRMAR SAÍDA
  // ==========================================================

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Sair do sistema',
          ),
          content: const Text(
            'Deseja realmente sair?',
          ),
          actions: [
            // ==================================================
            // CANCELAR
            // ==================================================

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            // ==================================================
            // SAIR
            // ==================================================

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF4A90E2),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                _sair(context);
              },
              child: const Text(
                'Sair',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF4A90E2),
        centerTitle: true,
        title: const Text(
          'Hospital Rápido - Paciente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Sair',
            onPressed: () {
              _confirmarSaida(context);
            },
          ),
        ],
      ),

      // ========================================================
      // CARREGANDO
      // ========================================================

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
              ),
            )

          // =====================================================
          // CONTEÚDO
          // =====================================================

          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // SAUDAÇÃO
                  // ==================================================

                  Text(
                    'Olá, $nomePaciente! 👋',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Confira suas informações e próximos '
                    'atendimentos.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // PRÓXIMA CONSULTA
                  // ==================================================

                  _cardProximaConsulta(
                    context,
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // AÇÕES RÁPIDAS
                  // ==================================================

                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // BOTÕES
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _acaoRapida(
                          context,
                          'Agendar\nConsulta',
                          Icons.calendar_month,
                          AgendarConsultaScreen(
                            idUsuario:
                                widget.idUsuario,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _acaoRapida(
                          context,
                          'Minhas\nConsultas',
                          Icons.description,
                          MinhasConsultasScreen(
                            idUsuario:
                                widget.idUsuario,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _acaoRapida(
                          context,
                          'Meu Perfil\ne Histórico',
                          Icons.person,
                          PerfilPacienteScreen(
                            idUsuario:
                                widget.idUsuario,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // INFORMAÇÃO DO HOSPITAL
                  // ==================================================

                  _cardInformacao(),

                  const SizedBox(height: 25),

                  // ==================================================
                  // SOBRE O SISTEMA
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SobreScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.info_outline,
                      ),
                      label: const Text(
                        'Sobre o Sistema',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xFF4A90E2,
                        ),
                        side:
                            const BorderSide(
                          color: Color(
                            0xFF4A90E2,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // CARD DA PRÓXIMA CONSULTA
  // ==========================================================

  Widget _cardProximaConsulta(
    BuildContext context,
  ) {
    // ==========================================================
    // SEM CONSULTA
    // ==========================================================

    if (proximaConsulta == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            children: [
              // ==================================================
              // ÍCONE
              // ==================================================

              const Icon(
                Icons.calendar_month,
                size: 60,
                color: Color(0xFF4A90E2),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // TÍTULO
              // ==================================================

              const Text(
                'PRÓXIMA CONSULTA',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF4A90E2),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // MENSAGEM
              // ==================================================

              const Text(
                'Você não possui consultas agendadas.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // AGENDAR
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 48,
                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AgendarConsultaScreen(
                          idUsuario:
                              widget.idUsuario,
                        ),
                      ),
                    ).then((_) {
                      _carregarDados();
                    });
                  },
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                  label: const Text(
                    'Agendar Consulta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF4A90E2,
                    ),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // DADOS DA CONSULTA
    // ==========================================================

    final consulta =
        proximaConsulta!;

    final String medico =
        consulta['medico']
                ?.toString() ??
            'Médico não informado';

    final String especialidade =
        consulta['especialidade']
                ?.toString() ??
            'Especialidade não informada';

    final String data =
        consulta['data']
                ?.toString() ??
            'Data não informada';

    final String horario =
        consulta['horario']
                ?.toString() ??
            'Horário não informado';

    final String status =
        consulta['status']
                ?.toString() ??
            'Agendada';

    // ==========================================================
    // CARD COM CONSULTA
    // ==========================================================

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CABEÇALHO
            // ==================================================

            Row(
              children: const [
                Icon(
                  Icons.push_pin,
                  color:
                      Color(0xFF4A90E2),
                ),
                SizedBox(width: 8),
                Text(
                  'PRÓXIMA CONSULTA',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF4A90E2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MÉDICO
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 24,
                  color:
                      Color(0xFF333333),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        medico,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        especialidade,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // DATA E HORÁRIO
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 22,
                  color:
                      Color(0xFF4A90E2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$data às $horario',
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATUS
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.orange.shade50,
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color:
                      Colors.orange,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // BOTÕES
            // ==================================================

            Row(
              children: [
                // ==============================================
                // ACOMPANHAR - PRINCIPAL
                // ==============================================

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FilaAtendimentoScreen(
                            idUsuario:
                                widget.idUsuario,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.monitor_heart,
                      size: 19,
                    ),
                    label: const Text(
                      'Acompanhar',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF4A90E2,
                      ),
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ==============================================
                // DETALHES - SECUNDÁRIO
                // ==============================================

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MinhasConsultasScreen(
                            idUsuario:
                                widget.idUsuario,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.description,
                      size: 19,
                    ),
                    label: const Text(
                      'Detalhes',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF4A90E2,
                      ),
                      side:
                          const BorderSide(
                        color: Color(
                          0xFF4A90E2,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AÇÃO RÁPIDA
  // ==========================================================

  Widget _acaoRapida(
    BuildContext context,
    String texto,
    IconData icone,
    Widget tela,
  ) {
    return SizedBox(
      height: 125,
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => tela,
              ),
            ).then((_) {
              _carregarDados();
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 34,
                  color:
                      const Color(
                    0xFF4A90E2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  texto,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INFORMAÇÃO DO HOSPITAL
  // ==========================================================

  Widget _cardInformacao() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color:
                  Color(0xFF4A90E2),
              size: 28,
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informação do Hospital',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Seu atendimento começa 15 minutos '
                    'antes do horário marcado.',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}







