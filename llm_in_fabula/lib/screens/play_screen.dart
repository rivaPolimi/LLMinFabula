import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/role_screen_preview.dart';
import 'package:provider/provider.dart';

// 1.5) PLAY SCREEN (schermata centrale 'play with friends')
// tappando ovunque si va a CreateJoinScreen
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final gameState = context.read<GameState>();
        gameState.goToJoinOrCreate();
      },
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/play_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'LLM in Fabula',
                    style: TextStyle(
                        fontSize: 54,
                        color: Color(0xFFDCC8A0),
                        //fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        fontFamily: 'JollyLodger-Regular'),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'play with friends',
                    style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFFDCC8A0),
                        decoration: TextDecoration.none),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'tap to continue',
                    style: TextStyle(
                        color: Color(0xFFDCC8A0),
                        fontSize: 15,
                        decoration: TextDecoration.none,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            // Aggiungi il pulsante di test qui
            Positioned(
              top: 50,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleScreenPreview(),
                    ),
                  );
                },
                child: const Text('Test Role'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
