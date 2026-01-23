import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/models/game_theme.dart';
import 'package:llm_in_fabula/screens/role_tutorials_screen.dart';
import 'package:llm_in_fabula/widgets/themed_widgets.dart';
import 'package:provider/provider.dart';
import 'package:llm_in_fabula/models/model.dart';

class RoleDefinition{
  final String name;
  final String asset;

  const RoleDefinition({required this.name, required this.asset});
}

class AdultSettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  final int numPlayers;
  final String settingName;
  final String nickname;
  final String password;

  const AdultSettingsScreen({
    required this.numPlayers, 
    required this.settingName, 
    required this.nickname, 
    required this.password,
    required this.onBack,
    super.key,
  });

  @override
  State<AdultSettingsScreen> createState() => _AdultSettingsScreenState();
}

class _AdultSettingsScreenState extends State<AdultSettingsScreen> {
  
  bool _isLoading = false;

  final List<RoleDefinition> secondaryRoles = [
    RoleDefinition(name: 'seer', asset: 'assets/icons/Seer.png'),
    RoleDefinition(name: 'courtesan', asset: 'assets/icons/Courtesan.png'),
    RoleDefinition(name: 'madman', asset: 'assets/icons/MadMan.png'),
    RoleDefinition(name: 'medium', asset: ''),
    RoleDefinition(name: 'hunter', asset: ''),
    RoleDefinition(name: 'guard', asset: ''),
    RoleDefinition(name: 'jailer', asset: ''),
    RoleDefinition(name: 'copycat', asset: ''),
  ];
  
  // Set per tracciare gli indici dei ruoli secondari selezionati (multi-selezione)
  final Set<int> _selectedSecondaryIndices = {};
  late GameTheme theme;
  
  int _numberOfWolves = 1;
  int _numberOfVillagers = 1;

  //TODO: controllare che non escano numeri di ruoli impossibili
  @override
  void initState() {
    super.initState();
    theme = GameThemes.getTheme(widget.settingName);
    _numberOfWolves = widget.numPlayers ~/ 5;
    _numberOfWolves = _numberOfWolves < 1 ? 1 : _numberOfWolves;
    _numberOfVillagers = widget.numPlayers - _numberOfWolves;
  }

  Map<String ,int> buildRoleMap(){
    final Map<String, int> roleMap = {};

    roleMap['wolf'] = _numberOfWolves;
    roleMap['villager'] = _numberOfVillagers;

    for(final i in _selectedSecondaryIndices){
      if(i < _selectedSecondaryIndices.length){
        final roleName = secondaryRoles[i].name;
        roleMap[roleName] = 1;
      }
    }

    return roleMap;
  }

  void _toggleSecondarySelection(int index) {
    setState(() {
      if (_selectedSecondaryIndices.contains(index)) {
        _selectedSecondaryIndices.remove(index);
      } else {
        _selectedSecondaryIndices.add(index);
      }
    });
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
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
                        RoleButton(
                          size: 80,
                          roleKey: 'wolf',
                          isSelected: false,
                          onTap: null, // Non selezionabile
                          theme: theme,
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
                        RoleButton(
                          size: 80,
                          roleKey: 'villager',
                          isSelected: false,
                          onTap: null, // Non selezionabile
                          theme: theme,
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
                  itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    const double gridBtnSize = 90.0;

                    // Get roles from the selected theme setting
                    final theme = GameThemes.getTheme(widget.settingName);
                    final List<String> activeRoles = theme.roles.keys.toList();

                    final String? roleKey = index < activeRoles.length
                        ? activeRoles[index]
                        : null;

                    return Center(
                      child: RoleButton(
                        size: gridBtnSize,
                        roleKey: roleKey,
                        theme: theme,
                        isSelected: _selectedSecondaryIndices.contains(index),
                        // Se non c'è ruolo, onTap è null e quindi non è selezionabile
                        onTap: roleKey != null ? () => _toggleSecondarySelection(index) : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // --- WOLF COUNTER ---
                Column(
                  children: [
                    Text(
                      'Number Of ${theme.getRoleName('wolf')}: $_numberOfWolves',
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
                      'Number Of ${theme.getRoleName('villager')}: $_numberOfVillagers',
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
                    // All'interno di adult_settings_screen.dart, nel pulsante "create lobby"

                    // In adult_settings_screen.dart

// ... (dentro il pulsante per creare la lobby)

                    onPressed: _isLoading
                        ? null
                        : () async {
                      final gameState = context.read<GameState>();
                      // TODO: rimuovi final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      setState(() {
                        _isLoading = true;
                      });

                      _showLoadingDialog(context);

                      try {
                        //Queries the server to create the game, then set game and player in the state
                        await gameState.createGameAndSetSession(
                            widget.numPlayers,
                            widget.settingName.toLowerCase(),
                            widget.nickname,
                            widget.password,
                            buildRoleMap()
                        );

                        if(!context.mounted) return;

                        _hideLoadingDialog(context);

                        gameState.goToGamePhase();
                      } catch (e, stackTrace) {
                        //TODO: provvisorio, togliere e gestire meglio eccezioni
                        debugPrint('Create game error: $e');
                        debugPrintStack(stackTrace: stackTrace);

                        if(!mounted) return;

                        _hideLoadingDialog(context);

                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if(mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },

                    /*onPressed: _isLoading
                        ? null
                        : () async {
                      // Imposta lo stato di caricamento e mostra il dialog
                      setState(() => _isLoading = true);
                      _showLoadingDialog(context);

                      final gameState = context.read<GameState>();
                      final roles = buildRoleMap();

                      try {
                        // --- ESEGUI LE OPERAZIONI ASINCRONE ---
                        // 1. Crea la partita (questo metodo cambierà la schermata)
                        await gameState.createGameAndSetSession(
                          widget.numPlayers,
                          widget.settingName,
                          widget.nickname,
                          widget.password,
                          roles,
                        );

                        // 2. Aggiungi i giocatori finti. Questa chiamata ora avviene
                        //    mentre il cambio di schermata è già in corso.
                        if (gameState.game != null) {
                          gameState.addFakePlayersForTesting(widget.numPlayers);
                        }

                        // !!! NON METTERE CODICE QUI DOPO L'AWAIT !!!
                        // A questo punto, questo widget sta per essere distrutto.
                        // Non chiamare _hideLoadingDialog o setState.

                      } catch (e) {
                        // Se c'è un errore PRIMA del cambio di schermata,
                        // allora dobbiamo nascondere il dialog e riabilitare il pulsante.
                        debugPrint("Errore durante la creazione della partita: $e");

                        if (mounted) {
                          _hideLoadingDialog(context); // Nascondi il caricamento SOLO IN CASO DI ERRORE
                          setState(() => _isLoading = false); // Riabilita il pulsante

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating game: ${e.toString()}')),
                          );
                        }
                      }
                      // !!! RIMUOVI IL BLOCCO 'finally' DA QUI !!!
                    },*/


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
                    onPressed: () => widget.onBack(),
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
  final String? roleKey;
  final VoidCallback? onTap;
  final bool isSelected;
  final GameTheme? theme;

  const RoleButton({
    super.key,
    required this.size,
    this.roleKey,
    this.theme,
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
      image: roleKey != null
          ? const DecorationImage(
        image: AssetImage('assets/images/moon2.png'),
        fit: BoxFit.cover,
      )
          : null,
      // Colore di riempimento se non c'è ruolo
      color: roleKey == null ? emptyFillColor : null,
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

          // LIVELLO 2: Icona Personaggio (Themed)
          if (roleKey != null)
            ThemedRoleIcon(
              baseRole: roleKey!,
              size: size * 0.75,
              themeOverride: theme,
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
