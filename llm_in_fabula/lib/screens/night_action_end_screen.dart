import 'package:flutter/material.dart';

class NightActionEndScreen extends StatelessWidget {
  const NightActionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D141A), // Dark Blue-Gray
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'You can sleep peacefully... for now. \nClose your eyes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
