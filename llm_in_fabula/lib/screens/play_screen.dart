import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'create_join_screen.dart';

// 1) Splash con logo
/*
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PlayScreen()), // QUI CAMBIATO
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LLM in Fabula',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              PrimaryButton(label: 'play with friends', onPressed: (){}),
              SizedBox(height: 8),
              Text(
                'tap to continue',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

// 1.5) PLAY SCREEN (schermata centrale 'play with friends')
// tappando ovunque si va a CreateJoinScreen
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateJoinScreen()),
        );
      },
      child: GradientPage(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'LLM in Fabula',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'play with friends',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'tap to continue',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*// 2) Home: solo un bottone "play with friends"
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: Center(
        child: PrimaryButton(
          label: 'play with friends',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateJoinScreen()),
            );
          },
        ),
      ),
    );
  }
}*/
