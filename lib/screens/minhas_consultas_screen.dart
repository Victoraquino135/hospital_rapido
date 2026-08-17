import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class MinhasConsultasScreen extends StatefulWidget {
  final int idUsuario;

  const MinhasConsultasScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<MinhasConsultasScreen> createState() =>
      _MinhasConsultasScreenState();
}

class _MinhasConsultasScreenState
    extends State<MinhasConsultasScreen> {

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  List<Map<String, dynamic>> _consultas = [];

  bool _carregando = true;

  String? _erro;

  // ==========================================================
  // INICIAR
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _carregarConsultas();
  }

  // ==========================================================
  // DEIXAR CPF SOMENTE COM NÚMEROS
  // ==========================================================

  String _somenteNumeros(String valor) {
    return valor.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  // ==========================================================
  // CARREGAR CONSULTAS DO PACIENTE
  // ==========================================================

  Future<void> _carregarConsultas() async {

    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {

      // ======================================================
      // BUSCAR USUÁRIO QUE ESTÁ LOGADO
      // ======================================================

      final usuario =
          await _databaseHelper.buscarUsuarioPorId(
        widget.idUsuario,
      );

      if (usuario == null) {

        if (!mounted) return;

        setState(() {
          _erro = 'Usuário não encontrado.';
          _carregando = false;
        });

        return;
      }

      // ======================================================
      // PEGAR CPF DO USUÁRIO
      // ======================================================

      final cpfUsuario =
          _somenteNumeros(
        usuario['cpf']?.toString() ?? '',
      );

      if (cpfUsuario.isEmpty) {

        if (!mounted) return;

        setState(() {
          _erro =
              'CPF do usuário não encontrado.';
          _carregando = false;
        });

        return;
      }

      // ======================================================
      // BUSCAR PACIENTE PELO CPF
      // ======================================================

      final pacientes =
          await _databaseHelper.listarPacientes();

      Map<String, dynamic>? pacienteEncontrado;

      for (final paciente in pacientes) {

        final cpfPaciente =
            _somenteNumeros(
          paciente['cpf']?.toString() ?? '',
        );

        if (cpfPaciente == cpfUsuario) {

          pacienteEncontrado = paciente;

          break;
        }
      }

      // ======================================================
      // PACIENTE NÃO ENCONTRADO
      // ======================================================

      if (pacienteEncontrado == null) {

        if (!mounted) return;

        setState(() {
          _consultas = [];
          _erro =
              'Paciente não encontrado para este usuário.';
          _carregando = false;
        });

        return;
      }

      // ======================================================
      // ID DO PACIENTE
      // ======================================================

      final pacienteId =
          pacienteEncontrado['id'];

      // ======================================================
      // BUSCAR TODAS AS CONSULTAS
      // ======================================================

      final todasConsultas =
          await _databaseHelper.listarConsultas();

      // ======================================================
      // PEGAR SOMENTE AS CONSULTAS DESTE PACIENTE
      // ======================================================

      final consultasPaciente =
          todasConsultas.where((consulta) {

        return consulta['paciente_id'].toString() ==
            pacienteId.toString();

      }).toList();

      // ======================================================
      // ATUALIZAR TELA
      // ======================================================

      if (!mounted) return;

      setState(() {

        _consultas = consultasPaciente;

        _carregando = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _erro =
            'Erro ao carregar consultas: $e';

        _carregando = false;

      });
    }
  }


  // ==========================================================
  // CANCELAR CONSULTA
  // ==========================================================

  Future<void> _cancelarConsulta(
    int id,
  ) async {

    // ========================================================
    // CONFIRMAR CANCELAMENTO
    // ========================================================

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          title: const Text(
            'Cancelar consulta',
          ),

          content: const Text(
            'Deseja realmente cancelar esta consulta?',
          ),

          actions: [

            TextButton(
              onPressed: () {

                Navigator.pop(
                  dialogContext,
                  false,
                );

              },
              child: const Text(
                'Não',
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {

                Navigator.pop(
                  dialogContext,
                  true,
                );

              },

              child: const Text(
                'Sim, cancelar',
              ),
            ),
          ],
        );
      },
    );

    // Usuário escolheu não cancelar
    if (confirmar != true) {
      return;
    }

    try {

      // ======================================================
      // ALTERAR STATUS NO BANCO
      // ======================================================

      await _databaseHelper.atualizarConsulta(
        id,
        {
          'status': 'Cancelada',
        },
      );

      // ======================================================
      // RECARREGAR CONSULTAS
      // ======================================================

      await _carregarConsultas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Consulta cancelada com sucesso!',
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Erro ao cancelar consulta: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // TELA
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF4A90E2),

        centerTitle: true,

        title: const Text(
          'Minhas Consultas',

          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================
  // CORPO DA TELA
  // ==========================================================

  Widget _buildBody() {

    // ========================================================
    // CARREGANDO
    // ========================================================

    if (_carregando) {

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ========================================================
    // ERRO
    // ========================================================

    if (_erro != null) {

      return Center(

        child: Padding(

          padding:
              const EdgeInsets.all(20),

          child: Text(
            _erro!,

            textAlign:
                TextAlign.center,

            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // ========================================================
    // NENHUMA CONSULTA
    // ========================================================

    if (_consultas.isEmpty) {

      return const Center(

        child: Padding(

          padding:
              EdgeInsets.all(20),

          child: Text(
            'Você não possui consultas agendadas.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ========================================================
    // LISTA
    // ========================================================

    return RefreshIndicator(

      onRefresh:
          _carregarConsultas,

      child: ListView(

        padding:
            const EdgeInsets.all(20),

        children: [

          const Text(
            'Consultas agendadas',

            style: TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ..._consultas.map(
            _buildConsultaCard,
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // CARTÃO DA CONSULTA
  // ==========================================================

  Widget _buildConsultaCard(
    Map<String, dynamic> consulta,
  ) {

    final id =
        int.tryParse(
          consulta['id']?.toString() ?? '',
        ) ??
        0;

    final medico =
        consulta['medico']?.toString() ??
            'Não informado';

    final especialidade =
        consulta['especialidade']?.toString() ??
            'Não informada';

    final data =
        consulta['data']?.toString() ??
            'Não informada';

    final horario =
        consulta['horario']?.toString() ??
            'Não informado';

    final status =
        consulta['status']?.toString() ??
            'Agendada';

    final cancelada =
        status.toLowerCase() ==
            'cancelada';

    return Card(

      elevation: 3,

      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      child: Padding(

        padding:
            const EdgeInsets.all(15),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // MÉDICO
            // ==================================================

            Row(

              children: [

                const Icon(
                  Icons.medical_services,

                  color:
                      Color(0xFF4A90E2),
                ),

                const SizedBox(width: 10),

                Expanded(

                  child: Text(
                    medico,

                    style:
                        const TextStyle(

                      fontSize: 20,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ESPECIALIDADE
            // ==================================================

            Text(
              'Especialidade: $especialidade',

              style:
                  const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // DATA
            // ==================================================

            Text(
              'Data: $data',

              style:
                  const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // HORÁRIO
            // ==================================================

            Text(
              'Horário: $horario',

              style:
                  const TextStyle(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // STATUS
            // ==================================================

            Text(
              'Status: $status',

              style: TextStyle(

                fontSize: 17,

                color: cancelada
                    ? Colors.red
                    : Colors.green,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            // ==================================================
            // BOTÃO CANCELAR
            // ==================================================

            if (!cancelada) ...[

              const SizedBox(height: 20),

              SizedBox(

                width:
                    double.infinity,

                child:
                    ElevatedButton(

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.red,

                    foregroundColor:
                        Colors.white,
                  ),

                  onPressed: () {

                    _cancelarConsulta(
                      id,
                    );

                  },

                  child: const Text(
                    'Cancelar Consulta',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}