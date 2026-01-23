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

class _NarratorIntroScreenState extends State<NarratorIntroScreen> {
  @override
  void initState() {
    super.initState();

    //Delay to ensure context and provider are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GameState>().startTts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (_, state, __) {
      final introduction = state.narratorText ?? "";

      return GradientPage(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC2D1D9).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      )),
                  child: SingleChildScrollView(
                    child: Text(
                      introduction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2E3B44),
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/illustrazioni/narratore.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
