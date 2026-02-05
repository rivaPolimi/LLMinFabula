import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

//TODO: DA RIMUOVERE

class EndScreenFake extends StatelessWidget {
  const EndScreenFake({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<GameState>().goToJoinOrCreate();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDCC8A0),
            foregroundColor: const Color(0xFF003943),
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 15,
            ),
          ),
          child: const Text('Back to Menu'),
        ),
      ),
    );
  }
}
