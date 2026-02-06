import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class PlayerDeathScreen extends StatelessWidget {
  final String deadPlayerName;

  const PlayerDeathScreen({super.key, required this.deadPlayerName});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF581C1C), // Dark Red
                  Color(0xFF0D141A), // Dark Blue-Gray
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.8],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.theme.getEliminatedIcon(),
                    size: 180,
                    color: const Color(0xFFDCC8A0),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    deadPlayerName,
                    style: const TextStyle(
                      color: Color(0xFFDCC8A0),
                      fontSize: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
