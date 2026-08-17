import 'package:flutter/material.dart';

class AvaliacaoScreen extends StatefulWidget {
  const AvaliacaoScreen({super.key});

  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}


class _AvaliacaoScreenState extends State<AvaliacaoScreen> {

  int estrelas = 0;

  final TextEditingController comentarioController =
      TextEditingController();


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF4A90E2),

        centerTitle: true,

        title: const Text(
          "Avaliar Atendimento",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            const Text(
              "Como foi seu atendimento?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 20),



            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: List.generate(5, (index) {


                return IconButton(

                  onPressed: () {

                    setState(() {

                      estrelas = index + 1;

                    });

                  },


                  icon: Icon(

                    Icons.star,

                    size: 40,

                    color: index < estrelas
                        ? Colors.amber
                        : Colors.grey,

                  ),

                );

              }),

            ),



            const SizedBox(height: 20),



            TextField(

              controller: comentarioController,

              maxLines: 5,

              decoration: InputDecoration(

                labelText: "Comentário",

                border: OutlineInputBorder(

                  borderRadius:
                      BorderRadius.circular(10),

                ),

              ),

            ),



            const SizedBox(height: 20),



            SizedBox(

              width: double.infinity,


              child: ElevatedButton(

                onPressed: () {


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content: Text(
                        "Avaliação enviada com sucesso!",
                      ),

                    ),

                  );


                },


                style: ElevatedButton.styleFrom(

                  backgroundColor:
                      const Color(0xFF4A90E2),

                ),


                child: const Text(

                  "Enviar Avaliação",

                  style: TextStyle(

                    color: Colors.white,

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}