import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/routers/role_action_router.dart';
import 'package:llm_in_fabula/screens/create_join_screen.dart';
import 'package:llm_in_fabula/screens/lobby_screen.dart';
import 'package:llm_in_fabula/screens/narrator_intro_screen.dart';
import 'package:llm_in_fabula/screens/role_screen.dart';

class GameRouter extends StatelessWidget {
  final GamePhase phase;

  const GameRouter({required this.phase, super.key});

  @override
  Widget build(BuildContext context) {
    switch(phase){
      case GamePhase.lobby:
        return const LobbyScreen();

      case GamePhase.introduction:
        return const NarratorIntroScreen();

      case GamePhase.roleReveal:
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
        // This screen will show the second narrator text
        return const NarratorIntroScreen();

      case GamePhase.nightReport:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.roleAction:
        return RoleActionRouter();

      case GamePhase.checkWin:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();

      case GamePhase.endGame:
        //TODO: DA IMPLEMENTARE
        return const CreateJoinScreen();
    }  
  }
}
