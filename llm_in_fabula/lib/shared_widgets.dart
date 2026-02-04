import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/model.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';

// WIDGET RIUSABILI

class GradientPage extends StatelessWidget {
  final String? title;
  final Widget child;

  const GradientPage({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) { //SFONDO COMUNE ALLE SCHERMATE (BLU NOTTE IN GRADIENTE)
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: title != null
          ? AppBar(
        title: Text(title!),
        backgroundColor: Colors.transparent,
        elevation: 0,
      )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF021C2C), Color(0xFF06394D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

//STILE DEL PULSANTONE MARRONCINO
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool activatingCondition;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.activatingCondition = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton(
        onPressed: activatingCondition ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE4D2A6),
          foregroundColor: const Color(0xFF08313F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
        ),
        child: Text(label),
      ),
    );
  }
}

class PlayerGrid extends StatelessWidget {
  final List<Player> players;

  const PlayerGrid({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      children: players.map((p) {  //la map di player verrà mandata dal db (qua bisogna vedere)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: !p.isDead
                  ? const Color(0xFF0B3F53) //COLORE SFONDO ICONA GIOCATORE IN BASE SE VIVO/MORTO
                  : Colors.grey.shade700,
              child: Icon(
                !p.isDead ? Icons.person : Icons.close,  //icona giocatore è una X se morto, altrimenti personaggino (prese da icone base flutter)
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.nickname,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// TIMER SUPERIORE DELLE SCHERMATE
class TimerBar extends StatelessWidget {
  const TimerBar({super.key});

  String formatDuration(Duration d){
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        //if (state.duration == null) return const SizedBox.shrink(); //TODO: potrebbe tornare utile ma per ora boh

        final remaining = state.remaining;
        final total = Duration(seconds: state.duration);
        final progress = 1 - (remaining.inSeconds / total.inSeconds);

        return Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              color: remaining.inSeconds < 5 ? Colors.red : const Color.fromRGBO(75, 139, 161, 1),
            ),
          ],
        );
      }
    );
  }
}
