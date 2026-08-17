import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // ==========================================================
  // BANCO DE DADOS
  // ==========================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final caminho = join(
      await getDatabasesPath(),
      'hospital_rapido.db',
    );

    return await openDatabase(
      caminho,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ==========================================================
  // CRIAR TABELAS
  // ==========================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // ========================================================
    // PACIENTES
    // ========================================================

    await db.execute('''
      CREATE TABLE pacientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cpf TEXT NOT NULL,
        telefone TEXT NOT NULL,
        email TEXT,
        endereco TEXT,
        convenio TEXT
      )
    ''');

    // ========================================================
    // USUÁRIOS
    // ========================================================

    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cpf TEXT NOT NULL UNIQUE,
        data_nascimento TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefone TEXT NOT NULL,
        usuario TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');

    // ========================================================
    // CONSULTAS
    // ========================================================

    await db.execute('''
      CREATE TABLE consultas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER,
        data TEXT,
        horario TEXT,
        especialidade TEXT,
        medico TEXT,
        observacoes TEXT,
        status TEXT
      )
    ''');

    // ========================================================
    // FILA DE ATENDIMENTO
    // ========================================================

    await db.execute('''
      CREATE TABLE fila_atendimento(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER,
        senha TEXT,
        data TEXT,
        status TEXT
      )
    ''');
  }

  // ==========================================================
  // ATUALIZAÇÃO DO BANCO
  // ==========================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE consultas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paciente_id INTEGER,
          data TEXT,
          horario TEXT,
          especialidade TEXT,
          medico TEXT,
          observacoes TEXT,
          status TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE fila_atendimento(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paciente_id INTEGER,
          senha TEXT,
          data TEXT,
          status TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE usuarios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          cpf TEXT NOT NULL UNIQUE,
          data_nascimento TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          telefone TEXT NOT NULL,
          usuario TEXT NOT NULL UNIQUE,
          senha TEXT NOT NULL,
          tipo TEXT NOT NULL
        )
      ''');
    }
  }

  // ==========================================================
  // PACIENTES
  // ==========================================================

  Future<int> inserirPaciente(
    Map<String, dynamic> paciente,
  ) async {
    final db = await database;

    return await db.insert(
      'pacientes',
      paciente,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> listarPacientes() async {
    final db = await database;

    return await db.query(
      'pacientes',
      orderBy: 'id DESC',
    );
  }

  // ==========================================================
  // BUSCAR PACIENTE PELO CPF
  // ==========================================================

  Future<Map<String, dynamic>?> buscarPacientePorCpf(
    String cpf,
  ) async {
    final db = await database;

    final cpfLimpo = cpf.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final pacientes = await db.query(
      'pacientes',
    );

    for (final paciente in pacientes) {
      final cpfBanco =
          (paciente['cpf']?.toString() ?? '')
              .replaceAll(RegExp(r'[^0-9]'), '');

      if (cpfBanco == cpfLimpo) {
        return paciente;
      }
    }

    return null;
  }

  // ==========================================================
  // ATUALIZAR PACIENTE
  // ==========================================================

  Future<int> atualizarPaciente(
    int id,
    Map<String, dynamic> paciente,
  ) async {
    final db = await database;

    return await db.update(
      'pacientes',
      paciente,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================
  // EXCLUIR PACIENTE
  // ==========================================================

  Future<int> excluirPaciente(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'pacientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================
  // USUÁRIOS
  // ==========================================================

  Future<int> inserirUsuario(
    Map<String, dynamic> usuario,
  ) async {
    final db = await database;

    return await db.insert(
      'usuarios',
      usuario,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    final db = await database;

    return await db.query(
      'usuarios',
      orderBy: 'nome ASC',
    );
  }

  // ==========================================================
  // BUSCAR USUÁRIO PELO ID
  // ==========================================================

  Future<Map<String, dynamic>?> buscarUsuarioPorId(
    int id,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isNotEmpty) {
      return resultado.first;
    }

    return null;
  }

  // ==========================================================
  // BUSCAR USUÁRIO PELO CPF
  // ==========================================================

  Future<Map<String, dynamic>?> buscarUsuarioPorCpf(
    String cpf,
  ) async {
    final db = await database;

    final cpfLimpo = cpf.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final usuarios = await db.query(
      'usuarios',
    );

    for (final usuario in usuarios) {
      final cpfBanco =
          (usuario['cpf']?.toString() ?? '')
              .replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

      if (cpfBanco == cpfLimpo) {
        return usuario;
      }
    }

    return null;
  }

  // ==========================================================
  // BUSCAR USUÁRIO PELO E-MAIL
  // ==========================================================

  Future<Map<String, dynamic>?> buscarUsuarioPorEmail(
    String email,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );

    if (resultado.isNotEmpty) {
      return resultado.first;
    }

    return null;
  }

  // ==========================================================
  // BUSCAR USUÁRIO PELO CPF OU E-MAIL
  // ==========================================================

  Future<Map<String, dynamic>?> buscarUsuarioPorIdentificacao(
    String identificacao,
  ) async {
    final valor = identificacao.trim();

    // --------------------------------------------------------
    // TENTAR PELO E-MAIL
    // --------------------------------------------------------

    if (valor.contains('@')) {
      return await buscarUsuarioPorEmail(valor);
    }

    // --------------------------------------------------------
    // TENTAR PELO CPF
    // --------------------------------------------------------

    return await buscarUsuarioPorCpf(valor);
  }

  // ==========================================================
  // ALTERAR SENHA
  // ==========================================================
  //
  // Este método é utilizado pela tela:
  //
  // nova_senha_screen.dart
  //
  // Ele altera a senha de um usuário identificado pelo
  // CPF ou e-mail.
  //
  // ==========================================================

  Future<bool> alterarSenha(
    String identificacao,
    String novaSenha,
  ) async {
    final db = await database;

    final valor = identificacao.trim();

    // --------------------------------------------------------
    // ALTERAR PELO E-MAIL
    // --------------------------------------------------------

    if (valor.contains('@')) {
      final resultado = await db.update(
        'usuarios',
        {
          'senha': novaSenha,
        },
        where: 'email = ?',
        whereArgs: [valor],
      );

      return resultado > 0;
    }

    // --------------------------------------------------------
    // ALTERAR PELO CPF
    // --------------------------------------------------------

    final cpfLimpo = valor.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final usuarios = await db.query(
      'usuarios',
    );

    for (final usuario in usuarios) {
      final cpfBanco =
          (usuario['cpf']?.toString() ?? '')
              .replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

      if (cpfBanco == cpfLimpo) {
        final id = usuario['id'];

        final resultado = await db.update(
          'usuarios',
          {
            'senha': novaSenha,
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        return resultado > 0;
      }
    }

    return false;
  }

  // ==========================================================
  // ATUALIZAR USUÁRIO
  // ==========================================================

  Future<int> atualizarUsuario(
    int id,
    Map<String, dynamic> usuario,
  ) async {
    final db = await database;

    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================
  // VERIFICAR CPF
  // ==========================================================

  Future<bool> cpfExiste(
    String cpf,
  ) async {
    final db = await database;

    final cpfLimpo = cpf.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final usuarios = await db.query(
      'usuarios',
    );

    for (final usuario in usuarios) {
      final cpfBanco =
          (usuario['cpf']?.toString() ?? '')
              .replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

      if (cpfBanco == cpfLimpo) {
        return true;
      }
    }

    return false;
  }

  // ==========================================================
  // VERIFICAR E-MAIL
  // ==========================================================

  Future<bool> emailExiste(
    String email,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }

  // ==========================================================
  // VERIFICAR USUÁRIO
  // ==========================================================

  Future<bool> usuarioExiste(
    String usuario,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario.trim()],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<Map<String, dynamic>?> login(
    String usuarioOuCpf,
    String senha,
  ) async {
    final db = await database;

    final valorDigitado = usuarioOuCpf.trim();

    final cpfDigitado = valorDigitado.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final senhaDigitada = senha;

    final usuarios = await db.query(
      'usuarios',
    );

    for (final usuario in usuarios) {
      final usuarioBanco =
          (usuario['usuario']?.toString() ?? '').trim();

      final cpfBanco =
          (usuario['cpf']?.toString() ?? '')
              .replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

      final senhaBanco =
          usuario['senha']?.toString() ?? '';

      final loginPorUsuario =
          usuarioBanco == valorDigitado;

      final loginPorCpf =
          cpfDigitado.length == 11 &&
          cpfBanco.isNotEmpty &&
          cpfBanco == cpfDigitado;

      final senhaCorreta =
          senhaBanco == senhaDigitada;

      if ((loginPorUsuario || loginPorCpf) &&
          senhaCorreta) {
        return usuario;
      }
    }

    return null;
  }

  // ==========================================================
  // CONSULTAS
  // ==========================================================

  Future<int> inserirConsulta(
    Map<String, dynamic> consulta,
  ) async {
    final db = await database;

    return await db.insert(
      'consultas',
      consulta,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================
  // LISTAR CONSULTAS
  // ==========================================================

  Future<List<Map<String, dynamic>>> listarConsultas() async {
    final db = await database;

    return await db.query(
      'consultas',
      orderBy: 'id DESC',
    );
  }

  // ==========================================================
  // BUSCAR PRÓXIMA CONSULTA DO PACIENTE
  // ==========================================================

  Future<Map<String, dynamic>?> buscarProximaConsulta(
    int pacienteId,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'consultas',
      where: 'paciente_id = ? AND status = ?',
      whereArgs: [
        pacienteId,
        'Agendada',
      ],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (resultado.isNotEmpty) {
      return resultado.first;
    }

    return null;
  }

  // ==========================================================
  // ATUALIZAR CONSULTA
  // ==========================================================

  Future<int> atualizarConsulta(
    int id,
    Map<String, dynamic> consulta,
  ) async {
    final db = await database;

    return await db.update(
      'consultas',
      consulta,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================
  // EXCLUIR CONSULTA
  // ==========================================================

  Future<int> excluirConsulta(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'consultas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================
  // FILA DE ATENDIMENTO
  // ==========================================================

  Future<int> inserirSenhaFila(
    Map<String, dynamic> fila,
  ) async {
    final db = await database;

    return await db.insert(
      'fila_atendimento',
      fila,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================
  // LISTAR FILA COM DADOS DO PACIENTE
  // ==========================================================

  Future<List<Map<String, dynamic>>> listarFila() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        fila_atendimento.id,
        fila_atendimento.paciente_id,
        fila_atendimento.senha,
        fila_atendimento.data,
        fila_atendimento.status,

        pacientes.nome,
        pacientes.cpf,
        pacientes.telefone,
        pacientes.email

      FROM fila_atendimento

      INNER JOIN pacientes
        ON fila_atendimento.paciente_id = pacientes.id

      ORDER BY fila_atendimento.id ASC
    ''');
  }

  // ==========================================================
  // BUSCAR FILA DE UM PACIENTE
  // ==========================================================

  Future<List<Map<String, dynamic>>> listarFilaPaciente(
    int pacienteId,
  ) async {
    final db = await database;

    return await db.query(
      'fila_atendimento',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'id ASC',
    );
  }

  // ==========================================================
  // GERAR NOVA SENHA
  // ==========================================================

  Future<String> gerarSenha() async {
    final db = await database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM fila_atendimento',
    );

    final numero =
        (resultado.first['total'] as int) + 1;

    return 'A${numero.toString().padLeft(3, '0')}';
  }

  // ==========================================================
  // ATUALIZAR STATUS DA FILA
  // ==========================================================

  Future<int> atualizarStatusFila(
    int id,
    String status,
  ) async {
    final db = await database;

    return await db.update(
      'fila_atendimento',
      {
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
