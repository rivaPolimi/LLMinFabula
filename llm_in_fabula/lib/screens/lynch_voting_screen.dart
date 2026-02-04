import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';

class LynchVotingScreen extends StatefulWidget {
  const LynchVotingScreen({super.key});
    
  @override
  State<LynchVotingScreen> createState() => _LynchVotingScreenState();
}

class _LynchVotingScreenState extends State<LynchVotingScreen> {
  int? _selectedPlayerId;

  @override
  void initState(){
    super.initState();
    _selectedPlayerId = null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, gameState, _) {

      final players = gameState.game!.players;

      return GradientPage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                TimerBar(),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    itemCount: players.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isSelected = player.id == _selectedPlayerId;

                      if (player.isDead) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/bara.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFF9E9D89),
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }

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
                                color: const Color(0xFF4B8B9A),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE4D2A6)
                                      : const Color(0xFF5D4D33),
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF003943),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFFDCC8A0),
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
                            gameState.confirmVote(_selectedPlayerId!);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0),
                      foregroundColor: const Color(0xFF003943),
                      disabledBackgroundColor:
                          const Color(0xFFDCC8A0).withValues(alpha: .5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'confirm your vote',
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
