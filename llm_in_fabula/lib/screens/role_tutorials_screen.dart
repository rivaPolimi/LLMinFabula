
import 'package:flutter/material.dart';

class RoleTutorialsScreen extends StatelessWidget {
  const RoleTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista dei ruoli da mostrare
    final List<Map<String, String>> roles = [
      {
        'name': 'WOLF:',
        'icon': 'assets/icons/wolf.png',
        'desc': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
      {
        'name': 'VILLAGER:',
        'icon': 'assets/icons/Villager.png',
        'desc': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      },
      {
        'name': 'SEER:',
        'icon': 'assets/icons/Seer.png',
        'desc': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      },
      {
        'name': 'MADMAN:',
        'icon': 'assets/icons/MadMan.png',
        'desc': 'ddddddddddddddddddddddddddddddddddddddddddd',
      },
      {
        'name': 'COURTESAN:',
        'icon': 'assets/icons/Courtesan.png',
        'desc': 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      },
    ];

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
                  final role = roles[index];
                  return _buildRoleCard(
                    name: role['name']!,
                    iconAsset: role['icon']!,
                    description: role['desc']!,
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
    required String iconAsset,
    required String description,
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
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // 2. CERCHIO CON ICONA
          // Rimosso Positioned e usato Container diretto per sfruttare alignment: centerLeft
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
              child: Image.asset(
                iconAsset,
                width: circleSize * 0.65,
                height: circleSize * 0.65,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
