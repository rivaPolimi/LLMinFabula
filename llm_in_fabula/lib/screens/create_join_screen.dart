import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'host_setup_screen.dart';

// 3) Create / Join lobby
class CreateJoinScreen extends StatelessWidget {
  const CreateJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      //title: 'LLM in Fabula',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, //evita che la colonna riempia l’intero schermo
          children: [
            SizedBox(
              width: 220,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20, color:  Color(0xFFDCC8A0)),
                  backgroundColor: const Color(0xFFDCC8A0),
                  foregroundColor: const Color(0xFF003943)
                ),
                child: const Text('create a lobby'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HostSetupScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: 220,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 20, color: Color(0xFFDCC8A0)),
                    backgroundColor: const Color(0xFFDCC8A0),
                    foregroundColor: const Color(0xFF003943)
                ),
                child: const Text('join a lobby'),
                onPressed: () {

                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
