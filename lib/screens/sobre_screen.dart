import 'package:flutter/material.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF4A90E2),

        centerTitle: true,

        title: const Text(

          "Sobre o Sistema",

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

          ),

        ),

      ),



      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),


        child: Column(

          children: [



            const Icon(

              Icons.local_hospital,

              size: 100,

              color: Color(0xFF4A90E2),

            ),




            const SizedBox(height: 15),




            const Text(

              "Hospital Rápido",

              style: TextStyle(

                fontSize: 30,

                fontWeight: FontWeight.bold,

                color: Color(0xFF333333),

              ),

            ),




            const SizedBox(height: 25),




            Card(

              elevation: 4,

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(15),

              ),


              child: const Padding(

                padding: EdgeInsets.all(20),


                child: Column(

                  children: [



                    Text(

                      "Sobre o Projeto",

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                      ),

                    ),



                    SizedBox(height: 15),




                    Text(

                      "O Hospital Rápido é um sistema criado "
                      "para facilitar o gerenciamento hospitalar, "
                      "permitindo organizar pacientes, consultas, "
                      "filas de atendimento e processos internos.",


                      textAlign: TextAlign.center,


                      style: TextStyle(

                        fontSize: 17,

                      ),

                    ),



                  ],

                ),

              ),

            ),





            const SizedBox(height: 20),




            _informacao(

              Icons.code,

              "Tecnologia",

              "Aplicativo desenvolvido utilizando Flutter e Dart.",

            ),




            const SizedBox(height: 15),




            _informacao(

              Icons.accessibility,

              "Acessibilidade",

              "Compatível com recursos de acessibilidade e "
              "melhor experiência para usuários.",

            ),




            const SizedBox(height: 15),





            _informacao(

              Icons.medical_services,

              "Objetivo",

              "Melhorar o controle de atendimento e reduzir "
              "o tempo de espera dos pacientes.",

            ),





            const SizedBox(height: 15),




            _informacao(

              Icons.info,

              "Versão",

              "1.0.0",

            ),




            const SizedBox(height: 30),





            const Text(

              "Hospital Rápido © 2026",

              style: TextStyle(

                color: Colors.grey,

              ),

            ),



          ],

        ),

      ),

    );

  }





  Widget _informacao(

    IconData icone,

    String titulo,

    String texto,

  ) {


    return Card(

      elevation: 3,


      child: ListTile(

        leading: Icon(

          icone,

          color: Color(0xFF4A90E2),

          size: 35,

        ),



        title: Text(

          titulo,

          style: const TextStyle(

            fontWeight: FontWeight.bold,

          ),

        ),



        subtitle: Text(texto),


      ),

    );

  }

}