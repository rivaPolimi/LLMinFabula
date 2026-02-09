import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class PlayerDeathScreen extends StatelessWidget {
  final String deadPlayerName;

  const PlayerDeathScreen({super.key, required this.deadPlayerName});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        return Scaffold(
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
                  _buildEliminatedIcon(state),
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
    );
  }

  Widget _buildEliminatedIcon(GameState state) {
    final eliminatedIconDef = state.theme.getEliminatedIconDefinition();
    
    // Use custom icon if available
    if (eliminatedIconDef?.customPath != null) {
      return Image.asset(
        eliminatedIconDef!.customPath!,
        width: 180,
        height: 180,
        color: const Color(0xFFDCC8A0),
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if image fails to load
          debugPrint("Failed to load eliminated icon: $error");
          return Icon(
            state.theme.getEliminatedIcon(),
            size: 180,
            color: const Color(0xFFDCC8A0),
          );
        },
      );
    }
    
    // Use material icon as fallback
    return Icon(
      state.theme.getEliminatedIcon(),
      size: 180,
      color: const Color(0xFFDCC8A0),
    );
  }
}
