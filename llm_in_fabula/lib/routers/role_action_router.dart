import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/night_action_end_screen.dart';
import 'package:llm_in_fabula/screens/night_action_prompt_screen.dart';
import 'package:llm_in_fabula/screens/wolf_voting_screen.dart';

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
          onNext: goToVoteScreen,
        );

      case RoleActionStep.action:
        return WolfVotingScreen(
          onNext: goToFinalPage,
        );

      case RoleActionStep.end:
        return NightActionEndScreen();
    }
  }
}