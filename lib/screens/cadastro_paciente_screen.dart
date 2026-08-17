import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../database/database_helper.dart';

class CadastroPacienteScreen extends StatefulWidget {
  const CadastroPacienteScreen({super.key});

  @override
  State<CadastroPacienteScreen> createState() =>
      _CadastroPacienteScreenState();
}

class _CadastroPacienteScreenState
    extends State<CadastroPacienteScreen> {

  final _formKey = GlobalKey<FormState>();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final TextEditingController _nomeController =
      TextEditingController();

  final TextEditingController _cpfController =
      TextEditingController();

  final TextEditingController _telefoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _enderecoController =
      TextEditingController();

  final TextEditingController _convenioController =
      TextEditingController();

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {
      "#": RegExp(r'[0-9]'),
    },
  );

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {
      "#": RegExp(r'[0-9]'),
    },
  );

  @override
  void dispose() {

    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _convenioController.dispose();

    super.dispose();
  }

    Future<void> _salvarPaciente() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {

      await _databaseHelper.inserirPaciente({

        "nome": _nomeController.text.trim(),
        "cpf": _cpfController.text.trim(),
        "telefone": _telefoneController.text.trim(),
        "email": _emailController.text.trim(),
        "endereco": _enderecoController.text.trim(),
        "convenio": _convenioController.text.trim(),

      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Paciente cadastrado com sucesso!",
          ),

          backgroundColor: Colors.green,

        ),

      );

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(
            "Erro ao salvar paciente: $e",
          ),

          backgroundColor: Colors.red,

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

          "Cadastro de Paciente",

          style: TextStyle(

            color: Colors.white,
            fontWeight: FontWeight.bold,

          ),

        ),

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              TextFormField(

                controller: _nomeController,

                textCapitalization: TextCapitalization.words,

                inputFormatters: [

                  FilteringTextInputFormatter.allow(

                    RegExp(r"[a-zA-ZÀ-ÿ\s]"),

                  ),

                ],

                decoration: InputDecoration(

                  labelText: "Nome Completo",

                  prefixIcon: const Icon(Icons.person),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {

                    return "Informe o nome do paciente";

                  }

                  if (value.trim().length < 3) {

                    return "Nome muito curto";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 15),

                            TextFormField(

                controller: _cpfController,

                keyboardType: TextInputType.number,

                inputFormatters: [

                  cpfMask,

                ],

                decoration: InputDecoration(

                  labelText: "CPF",

                  prefixIcon: const Icon(Icons.badge),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.isEmpty) {

                    return "Informe o CPF";

                  }

                  if (value.length != 14) {

                    return "CPF inválido";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 15),

              TextFormField(

                controller: _telefoneController,

                keyboardType: TextInputType.phone,

                inputFormatters: [

                  telefoneMask,

                ],

                decoration: InputDecoration(

                  labelText: "Telefone",

                  prefixIcon: const Icon(Icons.phone),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.isEmpty) {

                    return "Informe o telefone";

                  }

                  if (value.length < 15) {

                    return "Telefone inválido";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 15),

              TextFormField(

                controller: _emailController,

                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(

                  labelText: "E-mail",

                  prefixIcon: const Icon(Icons.email),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {

                    return "Informe o e-mail";

                  }

                  if (!RegExp(
                    r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                  ).hasMatch(value.trim())) {

                    return "E-mail inválido";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 15),

                            TextFormField(

                controller: _enderecoController,

                textCapitalization: TextCapitalization.words,

                decoration: InputDecoration(

                  labelText: "Endereço",

                  prefixIcon: const Icon(Icons.home),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {

                    return "Informe o endereço";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 15),

              TextFormField(

                controller: _convenioController,

                textCapitalization: TextCapitalization.words,

                decoration: InputDecoration(

                  labelText: "Convênio",

                  prefixIcon: const Icon(Icons.local_hospital),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {

                    return "Informe o convênio";

                  }

                  return null;

                },

              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,

                height: 55,

                child: ElevatedButton.icon(

                  onPressed: _salvarPaciente,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF4A90E2),

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(10),

                    ),

                  ),

                  icon: const Icon(Icons.save),

                  label: const Text(

                    "Salvar Paciente",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                    ),

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