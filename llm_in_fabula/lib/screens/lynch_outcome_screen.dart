import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/player_death_screen.dart';
import 'package:provider/provider.dart';

class LynchOutcomeScreen extends StatefulWidget {
  const LynchOutcomeScreen({super.key});

  @override
  State<LynchOutcomeScreen> createState() => _LynchOutcomeScreenState();
}

class _LynchOutcomeScreenState extends State<LynchOutcomeScreen> {
  bool _showingDeathScreen = false;
  Timer? _deathTimer;

  @override
  void initState() {
    super.initState();

    //Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameState = context.read<GameState>();
      
      // Check if there are victims (players killed during lynch)
      if (gameState.victims.isNotEmpty) {
        _showDeathScreen();
      } else {
        gameState.startTts();
      }
    });
  }

  void _showDeathScreen() {
    setState(() {
      _showingDeathScreen = true;
    });

    _deathTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      
      final gameState = context.read<GameState>();
      // Remove the displayed victim
      if (gameState.victims.isNotEmpty) {
        gameState.victims.removeFirst();
      }
      
      setState(() {
        _showingDeathScreen = false;
      });
      gameState.startTts();
    });
  }

  @override
  void dispose() {
    _deathTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (_, state, _) {
      // Show death screen if victim is available
      if (_showingDeathScreen && state.victims.isNotEmpty) {
        return PlayerDeathScreen(deadPlayerName: state.victims.first.nickname);
      }

      final introduction = state.narratorText ?? "";

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/day_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
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
                          introduction,
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
    });
  }
}
