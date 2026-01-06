import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';

// 6) Intro narratore (testo + illustrazione)
class NarratorIntroScreen extends StatefulWidget {
  const NarratorIntroScreen({super.key});

  @override
  State<NarratorIntroScreen> createState() => _NarratorIntroScreenState();
}

class _NarratorIntroScreenState extends State<NarratorIntroScreen>{
  @override
  void initState(){
    super.initState();

    //Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(!mounted) return;
      context.read<GameState>().startTts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final introduction = state.narratorText ?? "";
        
        return GradientPage(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        introduction,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Qui in futuro metti l'immagine del narratore dal tuo assets
                const Icon(Icons.menu_book, size: 72, color: Colors.white),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

}
