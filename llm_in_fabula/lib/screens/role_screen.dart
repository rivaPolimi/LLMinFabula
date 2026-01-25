import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/widgets/themed_widgets.dart';
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
        
        final remaining = state.remaining;
        final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

        return GradientPage(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
            child: Column(
              children: [
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'YOUR ROLE',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 4),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/moon2.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: ThemedRoleIcon(
                      baseRole: state.player!.roleName,
                      size: 150,
                      color: const Color(0xFF08313F)
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  roleName.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFDCC8A0),
                    fontSize: 48,
                    fontFamily: 'JollyLodger-Regular',
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E9D89),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        roleDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF282828), height: 1.5, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
