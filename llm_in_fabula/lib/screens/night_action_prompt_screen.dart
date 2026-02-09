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
  String? _lastNarratorText;

  @override
  void initState() {
    super.initState();

    // Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameState = context.read<GameState>();
      _lastNarratorText = gameState.narratorText;
      gameState.startTts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Check if narratorText has changed
        if (gameState.narratorText != _lastNarratorText && gameState.narratorText != null) {
          _lastNarratorText = gameState.narratorText;
          // Start TTS for the new text
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              gameState.startTts();
            }
          });
        }

        final isInTurn = gameState.player?.originalRoleName == gameState.game?.rolePlaying;
        final roleActionPrompt = gameState.narratorText;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/play_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    if (isInTurn)
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: TimerBar(),
                      ),
                    SizedBox(height: 50,),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
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
                    SizedBox(height: 50,),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GestureDetector(
                        onTap: isInTurn && gameState.currentPollId != -1
                            ? () {
                                widget.onNext();
                              }
                            : null,
                        child: Text(
                          isInTurn && gameState.currentPollId != -1
                              ? 'tap to continue'
                              : 'You sleep peacefully... for now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isInTurn && gameState.currentPollId != -1
                                ? const Color(0xFFDCC8A0)
                                : Colors.white70,
                            fontSize: isInTurn && gameState.currentPollId != -1 ? 18 : 16,
                            fontStyle: isInTurn && gameState.currentPollId != -1
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/illustrazioni/narratore.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}