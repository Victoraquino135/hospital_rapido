import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class FilaAtendimentoScreen extends StatefulWidget {
  final int idUsuario;

  const FilaAtendimentoScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<FilaAtendimentoScreen> createState() =>
      _FilaAtendimentoScreenState();
}

class _FilaAtendimentoScreenState
    extends State<FilaAtendimentoScreen> {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  bool carregando = true;

  Map<String, dynamic>? paciente;

  List<Map<String, dynamic>> fila = [];

  @override
  void initState() {
    super.initState();
    _carregarFila();
  }

  // ==========================================================
  // CARREGAR FILA DO PACIENTE
  // ==========================================================

  Future<void> _carregarFila() async {
    try {
      setState(() {
        carregando = true;
      });

      // --------------------------------------------------------
      // BUSCAR USUÁRIO LOGADO
      // --------------------------------------------------------

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

        _mostrarMensagem(
          'Usuário logado não encontrado.',
          Colors.red,
        );

        return;
      }

      // --------------------------------------------------------
      // PEGAR CPF DO USUÁRIO
      // --------------------------------------------------------

      final String cpf =
          usuario['cpf']?.toString() ?? '';

      if (cpf.isEmpty) {
        setState(() {
          carregando = false;
        });

        _mostrarMensagem(
          'O usuário não possui CPF cadastrado.',
          Colors.red,
        );

        return;
      }

      // --------------------------------------------------------
      // BUSCAR PACIENTE PELO CPF
      // --------------------------------------------------------

      final pacienteEncontrado =
          await _databaseHelper.buscarPacientePorCpf(
        cpf,
      );

      if (!mounted) {
        return;
      }

      if (pacienteEncontrado == null) {
        setState(() {
          carregando = false;
        });

        _mostrarMensagem(
          'Paciente não encontrado.',
          Colors.red,
        );

        return;
      }

      // --------------------------------------------------------
      // ID DO PACIENTE
      // --------------------------------------------------------

      final dynamic pacienteId =
          pacienteEncontrado['id'];

      if (pacienteId == null) {
        setState(() {
          carregando = false;
        });

        _mostrarMensagem(
          'O paciente não possui ID cadastrado.',
          Colors.red,
        );

        return;
      }

      final int idPaciente = pacienteId is int
          ? pacienteId
          : int.parse(pacienteId.toString());

      // --------------------------------------------------------
      // BUSCAR FILA DO PACIENTE
      // --------------------------------------------------------

      final filaEncontrada =
          await _databaseHelper.listarFilaPaciente(
        idPaciente,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        paciente = pacienteEncontrado;
        fila = filaEncontrada;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
      });

      _mostrarMensagem(
        'Erro ao carregar a fila: $e',
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
  // STATUS
  // ==========================================================

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando atendimento':
        return Colors.orange;

      case 'em atendimento':
        return Colors.blue;

      case 'atendido':
        return Colors.green;

      case 'cancelado':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando atendimento':
        return Icons.access_time;

      case 'em atendimento':
        return Icons.medical_services;

      case 'atendido':
        return Icons.check_circle;

      case 'cancelado':
        return Icons.cancel;

      default:
        return Icons.info;
    }
  }

  // ==========================================================
  // CARD DA FILA
  // ==========================================================

  Widget _cardFila(
    Map<String, dynamic> item,
  ) {
    final String senha =
        item['senha']?.toString() ?? '--';

    final String data =
        item['data']?.toString() ?? '--';

    final String status =
        item['status']?.toString() ?? 'Sem status';

    final Color corStatus =
        _corStatus(status);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --------------------------------------------------
            // SENHA
            // --------------------------------------------------

            const Text(
              'Sua senha',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              senha,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // STATUS
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: corStatus.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconeStatus(status),
                    color: corStatus,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: corStatus,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // DATA
            // --------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF4A90E2),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Data:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Text(data),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TELA
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF4A90E2),
        centerTitle: true,
        title: const Text(
          'Minha Fila',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _carregarFila,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Atualizar fila',
          ),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _carregarFila,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ==================================================
                    // ÍCONE
                    // ==================================================

                    const Icon(
                      Icons.confirmation_number,
                      size: 80,
                      color: Color(0xFF4A90E2),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // TÍTULO
                    // ==================================================

                    const Text(
                      'Acompanhar Atendimento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // PACIENTE
                    // ==================================================

                    if (paciente != null)
                      Text(
                        'Paciente: ${paciente!['nome'] ?? ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // FILA VAZIA
                    // ==================================================

                    if (fila.isEmpty)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(25),
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .hourglass_empty,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              const Text(
                                'Você não está na fila.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'Quando você realizar um '
                                'agendamento, sua senha '
                                'aparecerá aqui.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    _carregarFila,
                                icon: const Icon(
                                  Icons.refresh,
                                ),
                                label: const Text(
                                  'Atualizar',
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ==================================================
                    // FILA
                    // ==================================================

                    if (fila.isNotEmpty)
                      ...fila.map(
                        (item) => _cardFila(item),
                      ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // AVISO
                    // ==================================================

                    if (fila.isNotEmpty)
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color:
                                    Color(0xFF4A90E2),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Atualize a tela para '
                                  'verificar se o status '
                                  'do atendimento foi alterado.',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
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