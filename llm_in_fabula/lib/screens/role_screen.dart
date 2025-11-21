import 'package:flutter/material.dart';
import '../shared_widgets.dart';

// 7) Schermata del ruolo
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // per ora fisso, poi collegherai a ruoli reali dalla logica
    return GradientPage(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'YOUR ROLE',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 64,
              backgroundColor: const Color(0xFFE4D2A6),
              child: Icon(Icons.pets,
                  size: 72, color: const Color(0xFF08313F)),
            ),
            const SizedBox(height: 16),
            const Text(
              'WOLF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'During the night, you secretly choose a victim together '
                      'with the other wolves. During the day, pretend to be '
                      'a normal villager and try to confuse the others.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'I got it',
              onPressed: () {
                // qui potresti andare alla schermata "notte" / "dibattito"
              },
            ),
          ],
        ),
      ),
    );
  }
}
