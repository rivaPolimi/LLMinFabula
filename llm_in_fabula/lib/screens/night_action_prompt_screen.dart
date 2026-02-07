import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/shared_widgets.dart';
import 'package:provider/provider.dart';

class NightActionPromptScreen extends StatefulWidget {
  final void Function() onNext;
  const NightActionPromptScreen({required this.onNext, super.key});

  @override
  State<NightActionPromptScreen> createState() => _NightActionPromptScreenState();
}

class _NightActionPromptScreenState extends State<NightActionPromptScreen> {
  @override
  void initState() {
    super.initState();

    // Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GameState>().startTts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final isInTurn = gameState.player?.originalRoleName == gameState.game?.rolePlaying;
        final roleActionPrompt = gameState.narratorText;

        return Scaffold(
          backgroundColor: const Color(0xFF0D141A), // Dark Blue-Gray
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isInTurn) 
                    TimerBar(),
                  Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                            color: const Color(0xFFC2D1D9).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2,
                            )),
                        child: SingleChildScrollView(
                          child: Text(
                            roleActionPrompt ?? 'zzz... zzz...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF2E3B44),
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (isInTurn && gameState.currentPollId != -1)
                        ElevatedButton(
                          onPressed: () {
                            widget.onNext();
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
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}