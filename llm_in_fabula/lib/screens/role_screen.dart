import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';

// 7) Schermata del ruolo
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // per ora fisso, poi collegherai a ruoli reali dalla logica
    return Consumer<GameState>(
      builder: (_, state, _) {
        final roleName = state.player!.roleName;
        final roleDescription = state.player!.roleDescription;
        final roleImage; //TODO: settare icona ruolo

        return GradientPage(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const TimerBar(),
                const SizedBox(height: 16),
                const Text(
                  'YOUR ROLE',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 64,
                  backgroundColor: const Color(0xFFE4D2A6),
                  //TODO: bisogna mettere l'icona del ruolo giusto
                  child: Icon(Icons.pets,
                      size: 72, color: const Color(0xFF08313F)),
                ),
                const SizedBox(height: 16),
                Text(
                  roleName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      //TODO: mettere role description quando ci sarà
                      roleDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    );
  }
}
