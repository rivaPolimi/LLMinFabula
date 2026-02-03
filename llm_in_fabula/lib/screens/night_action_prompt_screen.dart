import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class NightActionPromptScreen extends StatelessWidget {
  const NightActionPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final isWolf = gameState.player?.roleName == 'wolf';

        return Scaffold(
          backgroundColor: const Color(0xFF0D141A), // Dark Blue-Gray
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWolf)
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the wolf voting screen
                      gameState.phase = GamePhase.roleAction;
                      gameState.notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0), // Beige
                      foregroundColor: const Color(0xFF003943), // Dark Teal
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Perform Night Action'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'You sleep peacefully... for now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
