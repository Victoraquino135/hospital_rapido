class Paciente {
  int? id;
  String nome;
  String cpf;
  String telefone;
  String email;
  String endereco;
  String convenio;

  Paciente({
    this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    required this.endereco,
    required this.convenio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'convenio': convenio,
    };
  }

  factory Paciente.fromMap(Map<String, dynamic> map) {
    return Paciente(
      id: map['id'],
      nome: map['nome'],
      cpf: map['cpf'],
      telefone: map['telefone'],
      email: map['email'],
      endereco: map['endereco'],
      convenio: map['convenio'],
    );
  }
}