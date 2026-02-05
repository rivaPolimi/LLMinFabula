import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/lynch_results_screen.dart';
import 'package:llm_in_fabula/screens/lynch_voting_screen.dart';

enum DiscussionStep {vote, result}

class DiscussionRouter extends StatefulWidget{
  const DiscussionRouter({super.key});

  @override
  State<DiscussionRouter> createState() => _DiscussionRouterState();
}

class _DiscussionRouterState extends State<DiscussionRouter> {
  DiscussionStep step = DiscussionStep.vote;

  void goToResultScreen(){
    setState(() {
      step = DiscussionStep.result;
    });
  }

  //TODO: cosa succede se premo back dopo aver votato?
  void goBack(){}

  @override
  Widget build(BuildContext context) {
    switch(step){
      case DiscussionStep.vote:
        return LynchVotingScreen(
          onNext: goToResultScreen
        );

      case DiscussionStep.result:
        return LynchResultsScreen();
    }
  }
}