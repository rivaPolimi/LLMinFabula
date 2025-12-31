import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';
import 'narrator_intro_screen.dart';

// 5) Lobby
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final players = gameState.game?.players ?? [];

        return GradientPage(
          title: 'LOBBY',
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(child: PlayerGrid(players: players)),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'start the game',
                  activatingCondition: gameState.player!.isAdmin,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NarratorIntroScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
