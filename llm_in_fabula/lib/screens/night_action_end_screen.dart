import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class NightActionEndScreen extends StatelessWidget {
  const NightActionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Combine narrator text with the default message
        final narratorPart = gameState.mysticText ?? '';
        final defaultMessage = 'You can sleep peacefully... for now. \nClose your eyes.';
        final message = narratorPart.isNotEmpty 
            ? '$narratorPart\n\n$defaultMessage'
            : defaultMessage;
        
        return Scaffold(
          backgroundColor: const Color(0xFF0D141A), // Dark Blue-Gray
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
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
