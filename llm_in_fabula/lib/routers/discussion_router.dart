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

  @override
  Widget build(BuildContext context) {
    final screenWidget = switch(step){
      DiscussionStep.vote => LynchVotingScreen(
        onNext: goToResultScreen
      ),
      DiscussionStep.result => LynchResultsScreen(),
    };

    return PopScope(
      canPop: false,
      child: screenWidget,
    );
  }
}