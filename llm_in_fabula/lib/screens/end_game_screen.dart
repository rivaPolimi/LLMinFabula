import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/play_screen.dart';
import 'package:provider/provider.dart';

class EndGameScreen extends StatelessWidget {
  const EndGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final narratorText = state.narratorText ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFFC9B486), // Tan background from image
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                children: [
                  // Text container
                  Expanded(
                    flex: 5, // Give more space to the text
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0D9C9).withValues(alpha: 0.9), // Light beige from image
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          narratorText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF2E3B44),
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Narrator Image
                  Expanded(
                    flex: 4, // Less space for the narrator
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/illustrazioni/narratore.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // End Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        //Close websocket and leaves the lobby
                        state.disconnect();
                        state.goToTitle();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const PlayScreen()),
                          (Route<dynamic> route) => false, // Remove all previous routes
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003943),
                        foregroundColor: const Color(0xFFDCC8A0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 60)
                      ),
                      child: const Text(
                        'END',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
}
