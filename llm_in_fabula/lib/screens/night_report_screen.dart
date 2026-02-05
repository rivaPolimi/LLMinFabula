import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/player_death_screen.dart';
import 'package:provider/provider.dart';

class NightReportScreen extends StatefulWidget {
  const NightReportScreen({super.key});

  @override
  State<NightReportScreen> createState() => _NightReportScreenState();
}

class _NightReportScreenState extends State<NightReportScreen> {
  bool _showingDeaths = false;
  Timer? _deathTimer;

  @override
  void initState() {
    super.initState();
    _showingDeaths = false;

    // Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameState = context.read<GameState>();
      gameState.startTts(_showDeathSequence);
    });
  }

  void _showDeathSequence() {
    final gameState = context.read<GameState>();
    
    if (gameState.victims.isEmpty) {
      _onDeathSequenceComplete();
      return;
    }

    setState(() {
      _showingDeaths = true;
    });

    _showNextDeath();
  }

  void _showNextDeath() {
    final gameState = context.read<GameState>();
    
    if (gameState.victims.isEmpty) {
      _onDeathSequenceComplete();
      return;
    }

    _deathTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      
      // Remove the first victim from the queue
      gameState.victims.removeFirst();

      if (gameState.victims.isEmpty) {
        _onDeathSequenceComplete();
        return;
      }

      setState(() {});
      _showNextDeath();
    });
  }

  void _onDeathSequenceComplete() {
    _deathTimer?.cancel();
    context.read<GameState>().completeNightReportPhase();
  }

  @override
  void dispose() {
    if (_showingDeaths) {
      _deathTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (_, state, _) {
      final narratorText = state.narratorText ?? "";

      // Show death screen if we're in the death sequence
      if (_showingDeaths && state.victims.isNotEmpty) {
        return PlayerDeathScreen(deadPlayerName: state.victims.first.nickname);
      }

      // Show narrator intro screen
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
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                          color: const Color(0xFFC2D1D9).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2,
                          )),
                      child: SingleChildScrollView(
                        child: Text(
                          narratorText,
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
