import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class AgendarConsultaScreen extends StatefulWidget {
  // ==========================================================
  // ID DO USUÁRIO LOGADO
  // ==========================================================

  final int idUsuario;

  const AgendarConsultaScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<AgendarConsultaScreen> createState() =>
      _AgendarConsultaScreenState();
}

class _AgendarConsultaScreenState
    extends State<AgendarConsultaScreen> {
  // ==========================================================
  // BANCO DE DADOS
  // ==========================================================

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  // ==========================================================
  // FORMULÁRIO
  // ==========================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // ==========================================================
  // DADOS DO PACIENTE
  // ==========================================================

  Map<String, dynamic>? pacienteLogado;

  bool carregandoPaciente = true;

  // ==========================================================
  // CAMPOS
  // ==========================================================

  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;

  String? especialidadeSelecionada;
  String? medicoSelecionado;

  // ==========================================================
  // LISTA DE ESPECIALIDADES
  // ==========================================================

  final List<String> especialidades = [
    'Clínica Geral',
    'Cardiologia',
    'Pediatria',
    'Ortopedia',
    'Dermatologia',
    'Ginecologia',
  ];

  // ==========================================================
  // MÉDICOS POR ESPECIALIDADE
  // ==========================================================

  final Map<String, List<String>> medicosPorEspecialidade = {
    'Clínica Geral': [
      'Dr. Carlos Silva',
      'Dra. Ana Souza',
    ],
    'Cardiologia': [
      'Dr. João Oliveira',
      'Dra. Mariana Costa',
    ],
    'Pediatria': [
      'Dra. Fernanda Lima',
      'Dr. Rafael Santos',
    ],
    'Ortopedia': [
      'Dr. Marcelo Almeida',
      'Dra. Juliana Martins',
    ],
    'Dermatologia': [
      'Dra. Camila Rocha',
      'Dr. Bruno Ferreira',
    ],
    'Ginecologia': [
      'Dra. Patrícia Mendes',
      'Dra. Larissa Gomes',
    ],
  };

  // ==========================================================
  // INICIALIZAÇÃO
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _carregarPaciente();
  }

  // ==========================================================
  // CARREGAR PACIENTE LOGADO
  // ==========================================================

  Future<void> _carregarPaciente() async {
    try {
      final usuario =
          await _databaseHelper.buscarUsuarioPorId(
        widget.idUsuario,
      );

      if (!mounted) {
        return;
      }

      if (usuario == null) {
        setState(() {
          carregandoPaciente = false;
        });

        _mostrarMensagem(
          'Não foi possível encontrar o usuário logado.',
          Colors.red,
        );

        return;
      }

      final String cpfUsuario =
          usuario['cpf']?.toString() ?? '';

      if (cpfUsuario.isEmpty) {
        setState(() {
          carregandoPaciente = false;
        });

        _mostrarMensagem(
          'O usuário logado não possui CPF cadastrado.',
          Colors.red,
        );

        return;
      }

      final paciente =
          await _databaseHelper.buscarPacientePorCpf(
        cpfUsuario,
      );

      if (!mounted) {
        return;
      }

      if (paciente == null) {
        setState(() {
          carregandoPaciente = false;
        });

        _mostrarMensagem(
          'Paciente não encontrado no cadastro.',
          Colors.red,
        );

        return;
      }

      setState(() {
        pacienteLogado = paciente;
        carregandoPaciente = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregandoPaciente = false;
      });

      _mostrarMensagem(
        'Erro ao carregar os dados do paciente: $e',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // SELECIONAR DATA
  // ==========================================================

  Future<void> _selecionarData() async {
    final DateTime hoje = DateTime.now();

    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(
        hoje.year + 1,
        hoje.month,
        hoje.day,
      ),
      helpText: 'Selecione a data da consulta',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      locale: const Locale('pt', 'BR'),
    );

    if (data == null || !mounted) {
      return;
    }

    setState(() {
      dataSelecionada = data;
    });
  }

  // ==========================================================
  // SELECIONAR HORÁRIO
  // ==========================================================

  Future<void> _selecionarHorario() async {
    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime:
          horarioSelecionado ?? TimeOfDay.now(),
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (horario == null || !mounted) {
      return;
    }

    setState(() {
      horarioSelecionado = horario;
    });
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '';
    }

    final String dia =
        data.day.toString().padLeft(2, '0');

    final String mes =
        data.month.toString().padLeft(2, '0');

    final String ano =
        data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // FORMATAR HORÁRIO
  // ==========================================================

  String _formatarHorario(TimeOfDay? horario) {
    if (horario == null) {
      return '';
    }

    final String hora =
        horario.hour.toString().padLeft(2, '0');

    final String minuto =
        horario.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
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
  // AGENDAR CONSULTA
  // ==========================================================

  Future<void> _agendarConsulta() async {
    if (pacienteLogado == null) {
      _mostrarMensagem(
        'Os dados do paciente ainda não foram carregados.',
        Colors.red,
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (dataSelecionada == null) {
      _mostrarMensagem(
        'Selecione a data da consulta.',
        Colors.red,
      );

      return;
    }

    if (horarioSelecionado == null) {
      _mostrarMensagem(
        'Selecione o horário da consulta.',
        Colors.red,
      );

      return;
    }

    if (especialidadeSelecionada == null) {
      _mostrarMensagem(
        'Selecione uma especialidade.',
        Colors.red,
      );

      return;
    }

    if (medicoSelecionado == null) {
      _mostrarMensagem(
        'Selecione um médico.',
        Colors.red,
      );

      return;
    }

    try {
      final String data =
          _formatarData(dataSelecionada);

      final String horario =
          _formatarHorario(horarioSelecionado);

      final String nome =
          pacienteLogado!['nome']?.toString() ?? '';

      final String cpf =
          pacienteLogado!['cpf']?.toString() ?? '';

      final dynamic pacienteId =
          pacienteLogado!['id'];

      if (pacienteId == null) {
        _mostrarMensagem(
          'Erro: o paciente não possui ID no banco.',
          Colors.red,
        );

        return;
      }

      final int id = pacienteId is int
          ? pacienteId
          : int.parse(
              pacienteId.toString(),
            );

      // ========================================================
      // CONFIRMAÇÃO
      // ========================================================

      final bool? confirmar =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Confirmar Agendamento',
            ),
            content: Text(
              'Paciente: $nome\n'
              'CPF: $cpf\n\n'
              'Data: $data\n'
              'Horário: $horario\n'
              'Especialidade: '
              '$especialidadeSelecionada\n'
              'Médico: '
              '$medicoSelecionado\n\n'
              'Deseja confirmar este agendamento?',
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
                  'Cancelar',
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child: const Text(
                  'Confirmar',
                ),
              ),
            ],
          );
        },
      );

      if (confirmar != true) {
        return;
      }

      await _salvarAgendamento(
        id,
        pacienteLogado!,
        data,
        horario,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Erro ao agendar consulta: $e',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // SALVAR AGENDAMENTO
  // ==========================================================

  Future<void> _salvarAgendamento(
    int pacienteId,
    Map<String, dynamic> paciente,
    String data,
    String horario,
  ) async {
    try {
      // ========================================================
      // GERAR SENHA
      // ========================================================

      final String senha =
          await _databaseHelper.gerarSenha();

      // ========================================================
      // SALVAR CONSULTA
      // ========================================================

      final dynamic consultaId =
          await _databaseHelper.inserirConsulta({
        'paciente_id': pacienteId,
        'data': data,
        'horario': horario,
        'especialidade':
            especialidadeSelecionada!,
        'medico':
            medicoSelecionado!,
        'observacoes':
            'Paciente: ${paciente['nome']}\n'
            'CPF: ${paciente['cpf']}',
        'status': 'Agendada',
      });

      // ========================================================
      // REGISTRAR SENHA
      // ========================================================
      //
      // Mantemos o registro da senha no banco.
      // A tela de fila foi retirada do MVP.
      //

      await _databaseHelper.inserirSenhaFila({
        'paciente_id': pacienteId,
        'senha': senha,
        'data': data,
        'status': 'Aguardando atendimento',
      });

      if (!mounted) {
        return;
      }

      _mostrarSenha(
        senha,
        consultaId,
        paciente,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Erro ao salvar agendamento: $e',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // MOSTRAR CONFIRMAÇÃO
  // ==========================================================

  void _mostrarSenha(
    String senha,
    dynamic consultaId,
    Map<String, dynamic> paciente,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (senhaContext) {
        return AlertDialog(
          title: const Text(
            'Agendamento realizado!',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 70,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                'Sua senha de atendimento é:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                senha,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Consulta nº $consultaId',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Paciente: ${paciente['nome']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Seu agendamento foi realizado '
                'com sucesso.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(senhaContext);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Concluir',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DECORAÇÃO DOS CAMPOS
  // ==========================================================

  InputDecoration _decoracao(
    String label,
    IconData icone, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
  // CAMPO DROPDOWN
  // ==========================================================

  Widget _campoSelecao({
    required String label,
    required IconData icone,
    required String? valor,
    required List<String> itens,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: valor,
      decoration: _decoracao(
        label,
        icone,
        hint: hint,
      ),
      isExpanded: true,
      items: itens.map(
        (String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        },
      ).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Selecione uma opção.';
        }

        return null;
      },
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
          'Agendar Consulta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: carregandoPaciente
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ==================================================
                    // ÍCONE
                    // ==================================================

                    const Icon(
                      Icons.calendar_month,
                      size: 80,
                      color: Color(0xFF4A90E2),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // TÍTULO
                    // ==================================================

                    const Text(
                      'Agendar uma Consulta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Os dados do paciente são '
                      'preenchidos automaticamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // PACIENTE
                    // ==================================================

                    TextFormField(
                      initialValue:
                          pacienteLogado?['nome']
                                  ?.toString() ??
                              '',
                      readOnly: true,
                      decoration: _decoracao(
                        'Paciente',
                        Icons.person,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // CPF
                    // ==================================================

                    TextFormField(
                      initialValue:
                          pacienteLogado?['cpf']
                                  ?.toString() ??
                              '',
                      readOnly: true,
                      decoration: _decoracao(
                        'CPF',
                        Icons.badge,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // DATA
                    // ==================================================

                    InkWell(
                      onTap: _selecionarData,
                      child: InputDecorator(
                        decoration: _decoracao(
                          'Data da consulta',
                          Icons.calendar_today,
                          hint: 'Selecione a data',
                        ),
                        child: Text(
                          dataSelecionada == null
                              ? 'Selecione a data'
                              : _formatarData(
                                  dataSelecionada,
                                ),
                          style: TextStyle(
                            fontSize: 16,
                            color: dataSelecionada == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // HORÁRIO
                    // ==================================================

                    InkWell(
                      onTap: _selecionarHorario,
                      child: InputDecorator(
                        decoration: _decoracao(
                          'Horário',
                          Icons.access_time,
                          hint: 'Selecione o horário',
                        ),
                        child: Text(
                          horarioSelecionado == null
                              ? 'Selecione o horário'
                              : _formatarHorario(
                                  horarioSelecionado,
                                ),
                          style: TextStyle(
                            fontSize: 16,
                            color: horarioSelecionado == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // ESPECIALIDADE
                    // ==================================================

                    _campoSelecao(
                      label: 'Especialidade',
                      icone: Icons.medical_services,
                      valor: especialidadeSelecionada,
                      itens: especialidades,
                      hint: 'Selecione a especialidade',
                      onChanged: (valor) {
                        setState(() {
                          especialidadeSelecionada =
                              valor;

                          medicoSelecionado = null;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // MÉDICO
                    // ==================================================

                    _campoSelecao(
                      label: 'Médico responsável',
                      icone: Icons.person_outline,
                      valor: medicoSelecionado,
                      itens: especialidadeSelecionada == null
                          ? <String>[]
                          : medicosPorEspecialidade[
                                  especialidadeSelecionada] ??
                              <String>[],
                      hint: especialidadeSelecionada == null
                          ? 'Selecione primeiro a especialidade'
                          : 'Selecione o médico',
                      onChanged: (valor) {
                        if (especialidadeSelecionada ==
                            null) {
                          return;
                        }

                        setState(() {
                          medicoSelecionado = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // BOTÃO AGENDAR
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _agendarConsulta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle,
                        ),
                        label: const Text(
                          'Agendar Consulta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // AVISO
                    // ==================================================

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(15),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.confirmation_number,
                              color: Color(0xFF4A90E2),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Após confirmar o '
                                'agendamento, uma senha '
                                'será gerada automaticamente '
                                'para o atendimento.',
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







