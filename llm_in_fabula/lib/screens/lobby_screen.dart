import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/role_tutorials_screen.dart';
import 'package:provider/provider.dart';

// 5) Lobby
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _isLoading = false;
  bool _showRoles = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final players = gameState.game?.players ?? [];

        return Stack(
          children: [
            Scaffold(
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
                              setState(() {
                                _showRoles = true;
                              });
                            },
                            icon: const Icon(Icons.menu, size: 16),
                            label: const Text('Roles'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDCC8A0), // Beige
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
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    p.nickname,
                                    style: const TextStyle(
                                      color: Color(0xFFDCC8A0), // Beige text
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
                            onPressed: !_isLoading && gameState.player!.isAdmin &&
                                    gameState.game!.players.length >= 4
                                  ? () {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    gameState.startGameSession();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDCC8A0), // Beige
                              foregroundColor: const Color(0xFF003943), // Dark Teal
                              disabledBackgroundColor:
                                  const Color(0xFFDCC8A0).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'start game',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- LOADING DIALOG ---
            if (_isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE4D2A6)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Starting game...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // --- ROLES OVERLAY ---
            if (_showRoles)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showRoles = false;
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap-through
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 700,
                        ),
                        margin: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            const RoleTutorialsScreen(),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _showRoles = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
