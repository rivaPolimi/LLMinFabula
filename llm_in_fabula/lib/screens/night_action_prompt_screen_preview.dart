import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/wolf_voting_screen_preview.dart';

class NightActionPromptScreenPreview extends StatefulWidget {
  const NightActionPromptScreenPreview({super.key});

  @override
  State<NightActionPromptScreenPreview> createState() =>
      _NightActionPromptScreenPreviewState();
}

class _NightActionPromptScreenPreviewState
    extends State<NightActionPromptScreenPreview> {
  bool _isWolf = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D141A), // Dark Blue-Gray
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Night Action Preview'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SwitchListTile(
                title: const Text(
                  'Simulate being a Wolf',
                  style: TextStyle(color: Colors.white),
                ),
                value: _isWolf,
                onChanged: (value) {
                  setState(() {
                    _isWolf = value;
                  });
                },
                activeColor: const Color(0xFFDCC8A0),
              ),
            ),
            const SizedBox(height: 40),
            if (_isWolf)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WolfVotingScreenPreview(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDCC8A0), // Beige
                  foregroundColor: const Color(0xFF003943), // Dark Teal
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Perform Night Action'),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'You sleep peacefully... for now.',
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
