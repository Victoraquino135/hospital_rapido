import 'package:flutter/material.dart';
import 'avaliacao_screen.dart';

class DetalhesConsultaScreen extends StatelessWidget {

  final String medico;
  final String especialidade;
  final String data;
  final String diagnostico;
  final String status;


  const DetalhesConsultaScreen({
    super.key,
    required this.medico,
    required this.especialidade,
    required this.data,
    required this.diagnostico,
    required this.status,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF4A90E2),

        centerTitle: true,

        title: const Text(
          "Detalhes da Consulta",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),


        actions: [

          IconButton(

            icon: const Icon(
              Icons.print,
              color: Colors.white,
            ),


            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(

                const SnackBar(

                  content: Text(
                    "Consulta preparada para impressão",
                  ),

                ),

              );

            },

          ),

        ],

      ),



      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),


        child: Card(

          elevation: 4,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(15),

          ),


          child: Padding(

            padding: const EdgeInsets.all(20),


            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,


              children: [


                Row(

                  children: [

                    const Icon(

                      Icons.medical_services,

                      color: Color(0xFF4A90E2),

                      size: 35,

                    ),


                    const SizedBox(width: 10),


                    Text(

                      medico,

                      style: const TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ],

                ),



                const SizedBox(height: 20),



                _informacao(
                  "Especialidade",
                  especialidade,
                ),


                _informacao(
                  "Data",
                  data,
                ),


                _informacao(
                  "Diagnóstico",
                  diagnostico,
                ),


                _informacao(
                  "Status",
                  status,
                ),



                const Divider(),



                const Text(

                  "Receita:",

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),


                const Text(

                  "- Paracetamol 500mg\n"
                  "- Repouso\n"
                  "- Hidratação",

                ),



                const SizedBox(height: 15),



                const Text(

                  "Exames:",

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),



                const Text(

                  "Nenhum exame solicitado",

                ),



                const SizedBox(height: 15),



                const Text(

                  "Observações:",

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),



                const Text(

                  "Retornar caso os sintomas persistam.",

                ),



                const SizedBox(height: 25),




                SizedBox(

                  width: double.infinity,


                  child: ElevatedButton.icon(

                    onPressed: () {


                      ScaffoldMessenger.of(context).showSnackBar(

                        const SnackBar(

                          content: Text(

                            "Receita preparada para download",

                          ),

                        ),

                      );


                    },


                    icon: const Icon(

                      Icons.download,

                      color: Colors.white,

                    ),


                    label: const Text(

                      "Baixar Receita",

                      style: TextStyle(

                        color: Colors.white,

                      ),

                    ),



                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xFF4A90E2),

                    ),

                  ),

                ),




                const SizedBox(height: 10),





                SizedBox(

                  width: double.infinity,


                  child: ElevatedButton.icon(

                    onPressed: () {


                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (context) => 
                              const AvaliacaoScreen(),

                        ),

                      );


                    },


                    icon: const Icon(

                      Icons.star,

                      color: Colors.white,

                    ),



                    label: const Text(

                      "Avaliar Atendimento",

                      style: TextStyle(

                        color: Colors.white,

                      ),

                    ),



                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xFF4A90E2),

                    ),

                  ),

                ),




                const SizedBox(height: 10),




                SizedBox(

                  width: double.infinity,


                  child: OutlinedButton.icon(

                    onPressed: () {


                      Navigator.pop(context);


                    },


                    icon: const Icon(

                      Icons.arrow_back,

                    ),


                    label: const Text(

                      "Voltar para Histórico",

                    ),

                  ),

                ),



              ],

            ),

          ),

        ),

      ),

    );

  }




  Widget _informacao(String titulo, String valor) {


    return Padding(

      padding: const EdgeInsets.only(bottom: 15),


      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          Text(

            "$titulo:",

            style: const TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 16,

            ),

          ),


          Text(valor),


        ],

      ),

    );

  }

}