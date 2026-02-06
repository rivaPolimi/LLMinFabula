import 'package:flutter/material.dart';
import 'package:llm_in_fabula/widgets/themed_widgets.dart';

class PlayerDeathScreenPreview extends StatelessWidget {
  const PlayerDeathScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const deadPlayerName = 'Sara';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
              ThemedPlayerStatusIcon(isDead: true, isWolf: false, size: 180,),
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
}
