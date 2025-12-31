import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'role_screen.dart';

// 6) Intro narratore (testo + illustrazione)
class NarratorIntroScreen extends StatelessWidget {
  const NarratorIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    'Good evening, my brave villagers!\n\n'
                        'Tonight the moon rises high over the village. '
                        'Among you, hidden in the shadows, a terrible wolf is ready to strike. '
                        'Listen carefully to my voice and follow the story...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Qui in futuro metti l'immagine del narratore dal tuo assets
            const Icon(Icons.menu_book, size: 72, color: Colors.white),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'continue',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
