


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adult_settings_screen.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  int _players = 8;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9B486),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFC9B486),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'HOST',
                      style: TextStyle(
                        color: Color(0xFF003943),
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Insert the NUMBER OF PLAYERS',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCC8A0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _players,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFDCC8A0),
                        items: [6, 7, 8, 9, 10, 11, 12, 16, 20]
                            .map(
                              (n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                              '$n',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _players = v);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Select the SETTING for the game',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // GRIGLIA RUOLI (Aggiornata con RoleButton)
                  SizedBox(
                    height: 200,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.65,
                      children: [
                        Center(
                          child: RoleButton(
                            size: 90,
                            iconAsset: 'assets/icons/babyWolf.png',
                            onTap: () {}, // Click vuoto
                          ),
                        ),
                        Center(
                          child: RoleButton(
                            size: 90,
                            iconAsset: 'assets/icons/wolf.png',
                            onTap: () {},
                          ),
                        ),
                        Center(
                          child: RoleButton(
                            size: 90,
                            iconAsset: 'assets/icons/vampire.png',
                            onTap: () {},
                          ),
                        ),
                        Center(
                          child: RoleButton(
                            size: 90,
                            iconAsset: 'assets/icons/zombie.png',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // NICKNAME
                  const Text(
                    'Choose your NICKNAME',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Color(0xFFDCC8A0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PASSWORD
                  const Text(
                    'Create a PASSWORD',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Color(0xFFDCC8A0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Copy password',
                        onPressed: () {
                          final text = _passwordController.text;
                          if (text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, color: Colors.black87),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BOTTONE "next"
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdultSettingsScreen(),
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
                      child: const Text(
                        'next',
                        style: TextStyle(color: Color(0xFFDCC8A0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BOTTONE "back"
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFDCC8A0),
                        foregroundColor: const Color(0xFF003943),
                        side: const BorderSide(color: Color(0xFF003943)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('back'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// NUOVO WIDGET UNIFICATO: RoleButton
// (Copiato da AdultSettingsScreen per coerenza)
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