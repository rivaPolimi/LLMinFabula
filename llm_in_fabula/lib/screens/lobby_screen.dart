
import 'package:flutter/material.dart';
import '../shared_widgets.dart';
import 'narrator_intro_screen.dart';
import 'role_tutorials_screen.dart';

class LobbyScreen extends StatelessWidget {
  final List<PlayerAvatarModel> players;

  const LobbyScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/play_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER BUTTON (Roles) ---
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleTutorialsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu, size: 16),
                    label: const Text('Roles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0), // Beige (Inverted)
                      foregroundColor: const Color(0xFF003943), // Dark Teal
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- GRIDVIEW GIOCATORI ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: GridView.builder(
                    itemCount: players.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final p = players[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4B8B9A), // Azzurro/Petrolio
                              border: Border.all(
                                color: const Color(0xFF5D4D33),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF003943), // Dark Teal icon
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: Color(0xFFDCC8A0), // Beige text for visibility
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // --- FOOTER BUTTON (Start Game only) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  height: 48,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NarratorIntroScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0), // Beige (Inverted)
                      foregroundColor: const Color(0xFF003943), // Dark Teal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'start game',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
