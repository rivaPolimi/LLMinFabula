import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

class JoinGameScreen extends StatefulWidget{
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen>{

  final _formKey = GlobalKey<FormState>();
  bool _isFormFilled = false;
  bool _isLoading = false;

  final PageController _pageController = PageController(viewportFraction: 0.6);

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _nicknameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_checkFormFilled);
    _passwordController.addListener(_checkFormFilled);
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

  void _checkFormFilled(){
    setState(() {
      _isFormFilled =
        _nicknameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    });
  }

  void onJoinPressed(){

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
                      'GUEST',
                      style: TextStyle(
                        color: Color(0xFF003943),
                        letterSpacing: 2,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                    style: TextStyle(color: Color.fromRGBO(9, 41, 52, 1),),
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
                    'Insert a PASSWORD',
                    style: TextStyle(color: Color(0xFF003943), fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: Color.fromRGBO(9, 41, 52, 1),),
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
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BOTTONE "join"
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_isFormFilled
                      ? null
                      : () async {
                        if (!_formKey.currentState!.validate()) return;

                        final gameState = context.read<GameState>();
                        final messenger = ScaffoldMessenger.of(context);

                        setState(() {
                          _isLoading = true;
                        });

                        _showLoadingDialog(context);
                        
                        try {
                          //Queries the server to create the game, then set game and player in the state
                          await gameState.joinGameAndSetSession(
                            _nicknameController.text, 
                            _passwordController.text, 
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003943),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'join',
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
                        context.read<GameState>().goToJoinOrCreate();
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