import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class RoleTutorialsScreen extends StatelessWidget {
  const RoleTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<GameState>().theme;
    final roles = theme.roles.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF003943),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER / EXIT BUTTON ---
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Torna indietro
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDCC8A0), // Beige
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  ),
                  child: const Text('Exit'),
                ),
              ),
              const SizedBox(height: 24),

              // --- LISTA RUOLI ---
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: roles.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
                itemBuilder: (ctx, index) {
                  final roleEntry = roles[index];
                  final role = roleEntry.value;

                  return _buildRoleCard(
                    name: role.name,
                    icon: role.icon,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String name,
    required IconData icon,
  }) {
    // Altezza del contenitore (card)
    const double cardHeight = 80;
    // Dimensione del cerchio icona
    const double circleSize = 80;

    return SizedBox(
      height: circleSize,
      child: Stack(
        alignment: Alignment.centerLeft, // Centra verticalmente gli elementi nello stack
        children: [
          // 1. CARD DI SFONDO
          Container(
            height: cardHeight,

            margin: const EdgeInsets.only(left: 0),

            padding: const EdgeInsets.fromLTRB(90, 8, 16, 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF003943),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. CERCHIO CON ICONA
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1),
              image: const DecorationImage(
                image: AssetImage('assets/images/moon2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: circleSize * 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
