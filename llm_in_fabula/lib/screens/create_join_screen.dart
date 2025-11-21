import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'host_setup_screen.dart';

// 3) Create / Join lobby
class CreateJoinScreen extends StatelessWidget {
  const CreateJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      title: 'LLM in Fabula',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, //evita che la colonna riempia l’intero schermo
          children: [
            PrimaryButton(
              label: 'create a lobby',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'join a lobby',
              onPressed: () {
                // QUI ADESSO NON FA NIENTE, VA IMPLEMENTATO ANCORA IL JOIN ALLA LOBBY
              },
            ),
          ],
        ),
      ),
    );
  }
}
