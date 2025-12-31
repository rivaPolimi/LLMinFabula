import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'narrator_intro_screen.dart';
import 'package:llm_in_fabula/models/model.dart';

// 5) Lobby
class LobbyScreen extends StatelessWidget {
  final List<Player> players;

  const LobbyScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
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
}
