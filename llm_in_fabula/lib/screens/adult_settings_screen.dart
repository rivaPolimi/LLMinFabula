

import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/lobby_screen.dart';
import 'package:llm_in_fabula/screens/role_tutorials_screen.dart';
import '../shared_widgets.dart';

class AdultSettingsScreen extends StatefulWidget {
  const AdultSettingsScreen({super.key});

  @override
  State<AdultSettingsScreen> createState() => _AdultSettingsScreenState();
}

class _AdultSettingsScreenState extends State<AdultSettingsScreen> {
  // Variabile per tracciare quale slot è selezionato.
  // -1: Nessuno
  // 0: Primo ruolo primario (sx)
  // 1: Secondo ruolo primario (dx)
  // 2+: Ruoli nella griglia
  int _selectedSlotId = -1;

  void _handleSelection(int id) {
    setState(() {
      _selectedSlotId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9B486),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER (Invariato) ---
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.black54,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
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
                            backgroundColor: const Color(0xFF003943),
                            foregroundColor: const Color(0xFFDCC8A0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(
                                fontSize: 12, color: Color(0xFFDCC8A0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- PRIMARY ROLES ---
                const Center(
                  child: Text(
                    'Primary roles',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ruolo Primario 1 (ID: 0)
                    RoleButton(
                      size: 80,
                      iconAsset: 'assets/icons/wolf.png',
                      isSelected: _selectedSlotId == 0,
                      onTap: () => _handleSelection(0),
                    ),
                    const SizedBox(width: 24),
                    // Ruolo Primario 2 (ID: 1)
                    RoleButton(
                      size: 80,
                      iconAsset: 'assets/icons/wolf.png',
                      isSelected: _selectedSlotId == 1,
                      onTap: () => _handleSelection(1),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // --- SECONDARY ROLES GRID ---
                const Text(
                  'Choose secondary roles',
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    const double gridBtnSize = 62.0;

                    // Calcoliamo un ID univoco per la griglia partendo da 2
                    final int currentSlotId = index + 2;

                    final List<String> activeRoles = [
                      'assets/icons/wolf.png',
                      'assets/icons/witch.png',
                      'assets/icons/seer.png',
                    ];

                    final String? asset = index < activeRoles.length
                        ? activeRoles[index]
                        : null;

                    return Center(
                      child: RoleButton(
                        size: gridBtnSize,
                        iconAsset: asset,
                        isSelected: _selectedSlotId == currentSlotId,
                        onTap: () => _handleSelection(currentSlotId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // --- FOOTER BUTTONS ---
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final players = List.generate(
                        8,
                            (i) => PlayerAvatarModel(
                          name: 'Player ${i + 1}',
                          isAlive: true,
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LobbyScreen(players: players),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003943),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('create lobby',
                        style:
                        TextStyle(fontSize: 16, color: Color(0xFFDCC8A0))),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0),
                      foregroundColor: const Color(0xFF003943),
                      side: const BorderSide(color: Color(0xFF003943), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('back', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// WIDGET ROLE BUTTON (Versione Pulita con DecorationImage)
// ---------------------------------------------------------

class RoleButton extends StatelessWidget {
  final double size;
  final String? iconAsset;
  final VoidCallback? onTap;
  final bool isSelected;

  const RoleButton({
    super.key,
    required this.size,
    this.iconAsset,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. CONFIGURAZIONE STILI
    final borderColor = isSelected
        ? const Color(0xFF003943) // Colore SELEZIONATO
        : const Color(0xFF5D4D33); // Colore NORMALE

    final double borderWidth = isSelected ? 4.0 : 1.0;
    const emptyFillColor = Color(0xFFDCC8A0);

    // 2. CONFIGURAZIONE DECORAZIONE
    // Usa l'immagine ritagliata come sfondo
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      // Immagine di sfondo
      image: iconAsset != null
          ? const DecorationImage(
        image: AssetImage('assets/images/moon2.png'),
        fit: BoxFit.cover,
      )
          : null,
      // Colore di riempimento se non c'è immagine
      color: iconAsset == null ? emptyFillColor : null,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // LIVELLO 1: Cerchio Sfondo + Bordo
          Container(
            width: size,
            height: size,
            decoration: decoration,
          ),

          // LIVELLO 2: Icona Personaggio
          if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: size * 0.55,
              height: size * 0.55,
              fit: BoxFit.contain,
            ),

          // LIVELLO 3: Effetto Click
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: onTap ?? () {},
              splashColor: Colors.white24,
              child: SizedBox(
                width: size,
                height: size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}