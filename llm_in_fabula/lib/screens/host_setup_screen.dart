
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

  // Indice del ruolo selezionato (inizializzato a 0 per mostrare il primo)
  int _selectedSettingIndex = 0;

  //Form key necessaria per validare l'input dell'utente
  final _formKey = GlobalKey<FormState>();

  bool _isFormFilled = false;

  final PageController _pageController = PageController(viewportFraction: 0.6);

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  // Lista dei ruoli disponibili
  final List<String> _roles = [
    'assets/icons/babyWolf.png',
    'assets/icons/wolf.png',
    'assets/icons/vampire.png',
    'assets/icons/zombie.png',
  ];

  // Lista dei nomi dei ruoli (corrispondente a _roles)
  final List<String> _settingNames = [
    'Children',
    'Classic',
    'Vampire',
    'Zombie',
  ];

  void _checkFormFilled(){
    setState(() {
      _isFormFilled =
        _nicknameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nicknameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    _nicknameController.addListener(_checkFormFilled);
    _passwordController.addListener(_checkFormFilled);
  }

  void onNextPressed(){
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdultSettingsScreen(
            settingName: _settingNames[_selectedSettingIndex], 
            numPlayers: _players, 
            nickname: _nicknameController.text,
            password: _passwordController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9B486),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFC9B486),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'HOST',
                      style: TextStyle(
                        color: Color(0xFF003943),
                        letterSpacing: 2,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Insert the NUMBER OF PLAYERS',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 18),
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

                  const SizedBox(height: 18),
                  const Text(
                    'Select the SETTING for the game',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 18),
                  ),
                  const SizedBox(height: 3),

                  // LISTA RUOLI ORIZZONTALE (PageView)
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _roles.length,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedSettingIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final isSelected = _selectedSettingIndex == index;
                        // Scale animation for selected item effect
                        return AnimatedScale(
                          scale: isSelected ? 1.0 : 0.8,
                          duration: const Duration(milliseconds: 300),
                          child: Center(
                            child: RoleButton(
                              size: 200,
                              iconAsset: _roles[index],
                              isSelected: isSelected,
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // NOME DEL RUOLO SELEZIONATO
                  Center(
                    child: Text(
                      _settingNames[_selectedSettingIndex],
                      style: const TextStyle(
                        color: Color(0xFF003943),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // NICKNAME
                  const Text(
                    'Choose your NICKNAME',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
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
                    validator: (value) {
                      if(value == null || value.trim().isEmpty){
                        return 'Nickname is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // PASSWORD
                  const Text(
                    'Create a PASSWORD',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                          validator: (value) {
                            if(value == null || value.trim().isEmpty){
                              return 'Password is required';
                            }
                            return null;
                          },
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
                      onPressed: _isFormFilled ? onNextPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003943),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'next',
                        style: TextStyle(color: Color(0xFFDCC8A0), fontSize: 20),
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
                      child: const Text('back', style: TextStyle(color: Color(0xFF003943), fontSize: 20)),

                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// WIDGET ROLE BUTTON PERFETTO
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
    // 1. STILI
    final borderColor = isSelected
        ? const Color(0xFF003943) // Blu scuro se selezionato
        : const Color(0xFF5D4D33); // Marrone se normale

    final double borderWidth = isSelected ? 4.0 : 1.0;
    const emptyFillColor = Color(0xFFDCC8A0);

    // 2. CONFIGURAZIONE DECORAZIONE (Qui avviene la magia)
    final decoration = BoxDecoration(
      shape: BoxShape.circle,

      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),

      image: iconAsset != null
          ? const DecorationImage(
        image: AssetImage('assets/images/moon2.png'),
        fit: BoxFit.cover,
      )
          : null,
      // SE NON C'È L'ASSET: Usa il colore solido beige
      color: iconAsset == null ? emptyFillColor : null,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // LIVELLO 1: Sfondo (Luna o Colore) + Bordo UNIFICATI
          Container(
            width: size,
            height: size,
            decoration: decoration, // Usa la decorazione definita sopra
          ),

          // LIVELLO 2: Icona Personaggio (Lupo, ecc.)
          // Disegnata sopra lo sfondo
          if (iconAsset != null)
            Image.asset(
              iconAsset!,
              width: size * 0.55,
              height: size * 0.55,
              fit: BoxFit.contain,
            ),

          // LIVELLO 3: Interazione (Ripple Effect)
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
