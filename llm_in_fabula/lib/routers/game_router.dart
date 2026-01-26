import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/create_join_screen.dart';
import 'package:llm_in_fabula/screens/lobby_screen.dart';
import 'package:llm_in_fabula/screens/narrator_intro_screen.dart';
import 'package:llm_in_fabula/screens/role_screen.dart';
import 'package:llm_in_fabula/screens/wolf_voting_screen.dart';
import 'package:provider/provider.dart';

class GameRouter extends StatelessWidget {
  final GamePhase phase;

  const GameRouter({required this.phase, super.key});

  @override
  Widget build(BuildContext context) {
    switch(phase){
      case GamePhase.lobby:
        return const LobbyScreen();

      case GamePhase.introduction:
        //TODO: forse dovrei passare l'introduzione qui
        return const NarratorIntroScreen();

      case GamePhase.roleReveal:
        //TODO: come passo il ruolo?
        return const RoleScreen();

      case GamePhase.discussion:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.extraVote:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.lynch:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.nightIntro:
        //TODO: DA IMPLEMENTARE
        return const NarratorIntroScreen();

      case GamePhase.nightReport:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.roleAction:
        final role = context.watch<GameState>().player?.roleName;
        if (role == 'wolf') {
          return const WolfVotingScreen();
        }
        //TODO: DA IMPLEMENTARE PER ALTRI RUOLI. DIPENDE ANCHE DA COME SI VUOLE GESTIRE LA COSA, SE UNO ALLA VOLTA COME NEL GIOCO VERO O TUTTO INSIEME (POTREBBE DARE PROBLEMI...)
        return const CreateJoinScreen();

      case GamePhase.checkWin:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.endGame:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();
    }  
  }
}