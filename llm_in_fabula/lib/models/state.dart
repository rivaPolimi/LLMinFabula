import 'package:flutter/material.dart';
import 'model.dart';
import 'package:llm_in_fabula/services/narrator_service.dart';

class GameState extends ChangeNotifier{
  Game? _game;
  Player? _player;

  Game? get game => _game;
  Player? get player => _player;

  Future<void> createGameAndSetSession(int numPlayers, String settingName, String nickname, String password, Map<String, int> roles) async{
    final session = await createGame(
      numPlayers,
      settingName,
      nickname,
      password,
      roles,
    );
    
    _game = session.game;
    _player = session.player;
    notifyListeners();
  }

  Future<void> joinGameAndSetSession(String nickname, String password) async {
    final session = await joinGame(nickname, password);

    _game = session.game;
    _player = session.player;
    notifyListeners();
  }
}