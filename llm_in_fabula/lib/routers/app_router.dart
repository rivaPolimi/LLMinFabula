import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/routers/create_lobby_flow.dart';
import 'package:llm_in_fabula/routers/game_router.dart';
import 'package:llm_in_fabula/screens/create_join_screen.dart';
import 'package:llm_in_fabula/screens/join_game_screen.dart';
import 'package:llm_in_fabula/screens/play_screen.dart';
import 'package:provider/provider.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        switch (state.flow) {
          case AppFlow.title:
            return const PlayScreen();

          case AppFlow.joinOrCreate:
            return const CreateJoinScreen();

          case AppFlow.create:
            return const CreateLobbyFlow();

          case AppFlow.join:
            return const JoinGameScreen();

          case AppFlow.inGame:
            return GameRouter(phase: state.phase);
        }
      }
    );
  }
}