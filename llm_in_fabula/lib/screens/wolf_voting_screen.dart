import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';
import 'package:llm_in_fabula/models/model.dart';

class WolfVotingScreen extends StatefulWidget {
  const WolfVotingScreen({super.key});

  @override
  State<WolfVotingScreen> createState() => _WolfVotingScreenState();
}

class _WolfVotingScreenState extends State<WolfVotingScreen> {
  int? _selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, gameState, _) {
      final remaining = gameState.remaining;
      final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

      // Filter out non-votable players
      final currentPlayer = gameState.player!;
      final votablePlayers = gameState.game!.players.where((p) {
        // Can't vote for yourself, dead players, or other wolves.
        // This assumes roleName is available for all players if you are a wolf.
        return !p.isDead &&
            p.id != currentPlayer.id &&
            p.roleName != 'wolf';
      }).toList();

      return GradientPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    itemCount: votablePlayers.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final player = votablePlayers[index];
                      final isSelected = player.id == _selectedPlayerId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlayerId = player.id;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4B8B9A), // Teal color
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE4D2A6) // Highlight color
                                      : const Color(0xFF5D4D33), // Default border
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF003943), // Darker Teal icon
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFFDCC8A0), // Beige text
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 48,
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _selectedPlayerId == null
                        ? null
                        : () {
                            // Handle vote confirmation logic here
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0), // Beige
                      foregroundColor: const Color(0xFF003943), // Dark Teal
                      disabledBackgroundColor:
                          const Color(0xFFDCC8A0).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'confirm your victim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
