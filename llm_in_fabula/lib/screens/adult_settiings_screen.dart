import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/lobby_screen.dart';
import 'package:llm_in_fabula/screens/role_tutorials_screen.dart';

import '../shared_widgets.dart';


class AdultSettingsScreen extends StatelessWidget {
  const AdultSettingsScreen({super.key});

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
                            // Naviga alla schermata dei tutorial ruoli
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>  RoleTutorialsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu, size: 16),
                          label: const Text('Roles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003943),
                            foregroundColor: Color(0xFFDCC8A0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 12, color: Color(0xFFDCC8A0)),
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
                    // Ruolo Primario 1
                    RoleButton(
                      size: 80, // Dimensione specifica per i ruoli in alto
                      iconAsset: 'assets/icons/wolf.png',
                      onTap: () => debugPrint("Primary 1 clicked"),
                    ),
                    const SizedBox(width: 24),
                    // Ruolo Primario 2
                    RoleButton(
                      size: 80,
                      iconAsset: 'assets/icons/wolf.png',
                      onTap: () => debugPrint("Primary 2 clicked"),
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
                  // Padding laterale per centrare e dimensionare la griglia
                  padding: const EdgeInsets.symmetric(horizontal: 45),

                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    // Dimensione UNICA per tutti i pulsanti della griglia
                    const double gridBtnSize = 62.0;


                    final List<String> activeRoles = [
                      'assets/icons/wolf.png',       // Ruolo per la casella 0
                      'assets/icons/witch.png',      // Ruolo per la casella 1 (esempio)
                      'assets/icons/seer.png',       // Ruolo per la casella 2 (esempio)
                    ];

                    // LOGICA:
                    // Se l'indice attuale (index) è inferiore al numero di ruoli nella lista,
                    // prendiamo l'icona corrispondente. Altrimenti lasciamo null (vuoto).
                    final String? asset = index < activeRoles.length
                        ? activeRoles[index]
                        : null;

                    return Center(
                      child: RoleButton(
                        size: gridBtnSize,
                        iconAsset: asset,
                        onTap: () => debugPrint("Grid item $index clicked"),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // --- FOOTER BUTTONS (Invariato) ---
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // 1. Genera i dati di prova (8 giocatori)
                      final players = List.generate(
                        8,
                            (i) => PlayerAvatarModel(
                          name: 'Player ${i + 1}',
                          isAlive: true,
                        ),
                      );

                      // 2. Naviga alla LobbyScreen passando i giocatori
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
                    child: const Text('create lobby', style: TextStyle(fontSize: 16, color: Color(0xFFDCC8A0))),
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
// NUOVO WIDGET UNIFICATO: RoleButton
// Sostituisce sia MoonRoleIcon che EmptyRoleCircle
// ---------------------------------------------------------

class RoleButton extends StatelessWidget {
  final double size;
  final String? iconAsset; // Se null, disegna il cerchio vuoto
  final VoidCallback? onTap; // Funzione al click

  const RoleButton({
    super.key,
    required this.size,
    this.iconAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- CONFIGURAZIONE STILI ---
    const borderColor = Color(0xFF5D4D33); // Marrone/Bronzo scuro
    const emptyFillColor = Color(0xFFDCC8A0); // Beige scuro per slot vuoti
    const double borderWidth = 1.7;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // 1. SFONDO (Luna o Colore Piatto)
          if (iconAsset != null) ...[
            // --- CASO PIENO (Luna) ---
            // Usiamo Transform.scale per ingrandire appena l'immagine
            // e farla finire sotto il bordo (evita spazi bianchi)
            Transform.scale(
              scale: 1.25,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/moon.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Icona del personaggio sopra la luna
            Image.asset(
              iconAsset!,
              width: size * 0.55, // L'icona è circa il 55% del cerchio
              height: size * 0.55,
              fit: BoxFit.contain,
            ),
          ] else ...[
            // --- CASO VUOTO (Colore) ---
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: emptyFillColor,
                shape: BoxShape.circle,
              ),
            ),
          ],

          // 2. BORDO (Sempre presente e sopra allo sfondo)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
          ),

          // 3. INTERAZIONE (Effetto Click)
          // Un Material trasparente con InkWell per l'effetto "onda" al tocco
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: onTap ?? () {}, // Gestisce il tap
              splashColor: Colors.white24, // Colore dell'effetto click
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