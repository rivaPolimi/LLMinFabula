import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared_widgets.dart';
import 'lobby_screen.dart';

// 4) Host: setup partita (numero giocatori, ruoli, password, nickname)
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
    // QUI facciamo lo sfondo completamente beige come nel mockup
    return Scaffold(
      backgroundColor: const Color(0xFFC9B486), // beige di sfondo
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            width: 320, // larghezza fissa tipo "card" centrale
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
                      color: Colors.black54,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Insert the NUMBER OF PLAYERS',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // DROPDOWN in stile "campo input"
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
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // le 4 icone dei ruoli
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _RoleIcon(icon: Icons.pets, label: 'Wolf'),
                    _RoleIcon(icon: Icons.visibility, label: 'Seer'),
                    _RoleIcon(icon: Icons.healing, label: 'Doctor'),
                    _RoleIcon(icon: Icons.people, label: 'Villager'),
                  ],
                ),

                const SizedBox(height: 24),

                // NICKNAME SOPRA
                const Text(
                  'Choose your NICKNAME',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
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

                // PASSWORD SOTTO + TASTO COPIA
                const Text(
                  'Create a PASSWORD',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
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

                // BOTTONE "next" blu scuro
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // per ora creiamo finta lista giocatori
                      final players = List.generate(
                        _players,
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
                    child: const Text('next'),
                  ),
                ),

                const SizedBox(height: 12),

                // BOTTONE "back" beige
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
    );
  }
}

class _RoleIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoleIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30, // PRIMA 22, ora solo più grande
          backgroundColor: const Color(0xFFE4D2A6), // come avevi tu
          child: Icon(
            icon,
            color: const Color(0xFF08313F),
            size: 28, // un po' più grande per riempire il cerchio
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 11),
        ),
      ],
    );
  }
}
