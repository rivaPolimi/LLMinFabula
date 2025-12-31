import 'package:flutter/material.dart';
import 'package:llm_in_fabula/screens/adult_settings_screen.dart';
import 'package:llm_in_fabula/screens/host_setup_screen.dart';

enum CreateLobbyStep {setup, roles}

class CreateLobbyFlow extends StatefulWidget{
  const CreateLobbyFlow({super.key});

  @override
  State<CreateLobbyFlow> createState() => _CreateLobbyFlowState();
}

class _CreateLobbyFlowState extends State<CreateLobbyFlow> {
  CreateLobbyStep step = CreateLobbyStep.setup;
  
  int numPlayers = 8;
  String settingName = 'classic';
  String nickname = '';
  String password = '';

  void goToRolesSelection({
    required int numPlayers,
    required String settingName,
    required String nickname,
    required String password,
  }) {
    setState(() {
      this.numPlayers = numPlayers;
      this.settingName = settingName;
      this.nickname = nickname;
      this.password = password;
      step = CreateLobbyStep.roles;
    });
  }

  void goBack(){
    setState(() {
      step = CreateLobbyStep.setup;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch(step){
      case CreateLobbyStep.setup:
        return HostSetupScreen(
          onNext: goToRolesSelection,
        );

      case CreateLobbyStep.roles:
        return AdultSettingsScreen(
          numPlayers: numPlayers, 
          settingName: settingName, 
          nickname: nickname, 
          password: password,
          onBack: goBack,
        );
    }
  }
}