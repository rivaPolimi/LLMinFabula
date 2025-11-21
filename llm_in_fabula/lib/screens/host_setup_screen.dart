import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mockup1/screens/adult_settiings_screen.dart';
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
            /*margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            width: 320, // larghezza fissa tipo "card" centrale*/

            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            width: double.infinity, // occupa quasi tutta la larghezza


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
                      color: const Color(0xFF003943),
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Insert the NUMBER OF PLAYERS',
                  style: TextStyle(color: const Color(0xFF003943), fontSize: 12),
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
                  style: TextStyle(color: const Color(0xFF003943), fontSize: 12),
                ),
                const SizedBox(height: 12),

                // le 4 icone dei ruoli
                // le 4 icone dei ruoli
                //PER ORA LSCIAMO UNA GRID, VISTO CHE I RUOLI SONO 4 FISSI
                //SE NE VANNO AGGIUNTI ALTRI O SI MODIFICA LA GRID (SE SONO FISSI) O METTO UN WRAPPED
                SizedBox(
                  height: 200,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 8,
                    //childAspectRatio: 2.2,
                    childAspectRatio: 1.65,
                    children: const [
                      _RoleIcon(fgAsset: 'assets/icons/babyWolf.png'),
                      _RoleIcon(fgAsset: 'assets/icons/wolf.png'),
                      _RoleIcon(fgAsset: 'assets/icons/vampire.png'),
                      _RoleIcon(fgAsset: 'assets/icons/zombie.png'),
                    ],
                  ),
                ),








                const SizedBox(height: 24),

                // NICKNAME SOPRA
                const Text(
                  'Choose your NICKNAME',
                  style: TextStyle(color: const Color(0xFF003943), fontSize: 12),
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
                  style: TextStyle(color: const Color(0xFF003943), fontSize: 12),
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
                          builder: (_) => AdultSettingsScreen(/*players: players*/),
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
                    child: const Text('next', style: TextStyle(color: const Color(0xFFDCC8A0)), ),
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
  final String fgAsset;

  // diametro "desiderato" del cerchio, in pixel logici
  final double circleDiameter;

  // quanto è grande l'icona rispetto al cerchio (0–1)
  final double iconScale;

  const _RoleIcon({
    super.key,
    required this.fgAsset,
    this.circleDiameter = 120, // MODIFICA QUESTO PER AVERE CERCHI PIÙ GRANDI / PICCOLI
    this.iconScale = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // quanto massimo può essere grande la cosa dentro la cella
        final maxSize = constraints.biggest.shortestSide;

        // il cerchio sarà il minimo tra quello che vuoi e lo spazio disponibile
        final circleSize = circleDiameter <= maxSize ? circleDiameter : maxSize;

        final charSize = circleSize * iconScale;

        return Center(
          child: SizedBox(
            width: circleSize,
            height: circleSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/moon.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Image.asset(
                  fgAsset,
                  width: charSize,
                  height: charSize,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        );


      },
    );
  }
}
