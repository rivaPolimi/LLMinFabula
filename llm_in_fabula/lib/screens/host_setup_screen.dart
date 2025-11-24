import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adult_settings_screen.dart';
// Rimosso import inutilizzato shared_widgets.dart
// Rimosso import inutilizzato lobby_screen.dart

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

                  // GRIGLIA RUOLI
                  SizedBox(
                    height: 200,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 8,
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

class _RoleIcon extends StatelessWidget {
  final String fgAsset;

  const _RoleIcon({
    required this.fgAsset,
  });

  @override
  Widget build(BuildContext context) {
    const double circleDiameter = 120;
    const double iconScale = 0.6;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.biggest.shortestSide;
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