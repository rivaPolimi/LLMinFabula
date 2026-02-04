import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/screens/create_join_screen.dart';
import 'package:llm_in_fabula/screens/night_action_end_screen.dart';
import 'package:llm_in_fabula/screens/night_action_prompt_screen.dart';
import 'package:llm_in_fabula/screens/wolf_voting_screen.dart';
import 'package:provider/provider.dart';

enum RoleActionStep {prompt, action, end}

class RoleActionRouter extends StatefulWidget{
  const RoleActionRouter({super.key});

  @override
  State<RoleActionRouter> createState() => _RoleActionRouterState();
}

class _RoleActionRouterState extends State<RoleActionRouter> {
  RoleActionStep step = RoleActionStep.prompt;

  void goToVoteScreen(){
    setState(() {
      step = RoleActionStep.action;
    });
  }

  void goToFinalPage(){
    setState(() {
      step = RoleActionStep.end;
    });
  }

  //TODO: cosa succede se premo back dopo aver votato?
  void goBack(){
    setState(() {
      step = RoleActionStep.prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch(step){
      case RoleActionStep.prompt:
        return NightActionPromptScreen(
          onNext: goToVoteScreen
        );

      case RoleActionStep.action:
        if(context.watch<GameState>().game?.rolePlaying == 'wolf'){
          //TODO: aggiungere on back
          return WolfVotingScreen(onNext: goToFinalPage,);
        }
        else{
          //TODO implementare lo screen per gli altri ruoli
          return CreateJoinScreen();
        }

      case RoleActionStep.end:
        return NightActionEndScreen();
    }
  }
}