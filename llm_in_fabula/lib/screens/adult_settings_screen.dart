
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
  // Set per tracciare gli indici dei ruoli secondari selezionati (multi-selezione)
  final Set<int> _selectedSecondaryIndices = {};
  
  int _numberOfWolves = 1;
  int _numberOfVillagers = 1;

  void _toggleSecondarySelection(int index) {
    setState(() {
      if (_selectedSecondaryIndices.contains(index)) {
        _selectedSecondaryIndices.remove(index);
      } else {
        _selectedSecondaryIndices.add(index);
      }
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
                // --- HEADER  ---
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                    style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ruolo Primario 1 (ID: 0) - WOLVES
                    Column(
                      children: [
                        const RoleButton(
                          size: 80,
                          iconAsset: 'assets/icons/wolf.png',
                          isSelected: false,
                          onTap: null, // Non selezionabile
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B8B9A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_numberOfWolves',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Ruolo Primario 2 (ID: 1) - VILLAGERS
                    Column(
                      children: [
                        const RoleButton(
                          size: 80,
                          iconAsset: 'assets/icons/Villager.png',
                          isSelected: false,
                          onTap: null, // Non selezionabile
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B8B9A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_numberOfVillagers',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // --- SECONDARY ROLES GRID ---
                const Text(
                  'Choose secondary roles',
                  style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
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
                    const double gridBtnSize = 90.0;

                    final List<String> activeRoles = [
                      'assets/icons/Seer.png',
                      'assets/icons/Courtesan.png',
                      //'assets/icons/Courtesan.png',
                      'assets/icons/MadMan.png',
                      //'assets/icons/seer.png',
                    ];

                    final String? asset = index < activeRoles.length
                        ? activeRoles[index]
                        : null;

                    return Center(
                      child: RoleButton(
                        size: gridBtnSize,
                        iconAsset: asset,
                        isSelected: _selectedSecondaryIndices.contains(index),
                        // Se non c'è asset, onTap è null e quindi non è selezionabile
                        onTap: asset != null ? () => _toggleSecondarySelection(index) : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // --- WOLF COUNTER ---
                Column(
                  children: [
                    Text(
                      'Number Of Wolves: $_numberOfWolves',
                      style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 160,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF003943),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black/*.withOpacity(0.1)*/,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                onTap: () {
                                  if (_numberOfWolves > 1) {
                                    setState(() {
                                      _numberOfWolves--;
                                    });
                                  }
                                },
                                child: const Center(
                                  child: Icon(Icons.remove, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1.5,
                            color: Colors.white70,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                onTap: () {
                                  setState(() {
                                    _numberOfWolves++;
                                  });
                                },
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- VILLAGER COUNTER ---
                Column(
                  children: [
                    Text(
                      'Number Of Villagers: $_numberOfVillagers',
                      style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 160,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF003943),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black/*.withOpacity(0.1)*/,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                onTap: () {
                                  if (_numberOfVillagers > 1) {
                                    setState(() {
                                      _numberOfVillagers--;
                                    });
                                  }
                                },
                                child: const Center(
                                  child: Icon(Icons.remove, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1.5,
                            color: Colors.white70,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                onTap: () {
                                  setState(() {
                                    _numberOfVillagers++;
                                  });
                                },
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              width: size * 0.75,
              height: size * 0.75,
              fit: BoxFit.contain,
            ),

          // LIVELLO 3: Effetto Click
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(

              onTap: onTap,
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
