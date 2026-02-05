import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/routers/discussion_router.dart';
import 'package:llm_in_fabula/routers/role_action_router.dart';
import 'package:llm_in_fabula/screens/end_screen_fake.dart';
import 'package:llm_in_fabula/screens/lobby_screen.dart';
import 'package:llm_in_fabula/screens/lynch_outcome_screen.dart';
import 'package:llm_in_fabula/screens/narrator_intro_screen.dart';
import 'package:llm_in_fabula/screens/night_report_screen.dart';
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
        return const DiscussionRouter();

      case GamePhase.lynching:
        return const LynchOutcomeScreen();

      case GamePhase.nightIntro:
        // This screen will show the second narrator text
        return const NarratorIntroScreen();

      case GamePhase.nightReport:
        return const NightReportScreen();

      case GamePhase.roleAction:
        return RoleActionRouter();

      case GamePhase.endGame:
        //TODO: DA IMPLEMENTARE
        return EndScreenFake();
    }  
  }
}
