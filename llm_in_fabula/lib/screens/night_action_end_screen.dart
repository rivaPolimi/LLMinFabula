import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class NightActionEndScreen extends StatefulWidget {
  const NightActionEndScreen({super.key});

  @override
  State<NightActionEndScreen> createState() => _NightActionEndScreenState();
}

class _NightActionEndScreenState extends State<NightActionEndScreen> {
  bool _showNarratorPart = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    
    // Hide narrator part after 10 seconds
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showNarratorPart = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        // Combine narrator text with the default message
        final narratorPart = gameState.mysticText ?? '';
        final defaultMessage = 'You can sleep peacefully... for now. \nClose your eyes.';
        final message = (_showNarratorPart && narratorPart.isNotEmpty)
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
