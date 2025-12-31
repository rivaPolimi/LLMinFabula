import 'package:flutter/material.dart';
import 'package:llm_in_fabula/services/websocket_service.dart';
import 'model.dart';
import 'package:llm_in_fabula/services/narrator_service.dart';

enum GamePhase {lobby, introduction, roleDiscovery,}
enum AppFlow {title, joinOrCreate, join, create, inGame,}

class GameState extends ChangeNotifier{
  Game? _game;
  Player? _player;

  GamePhase phase = GamePhase.lobby;
  AppFlow flow = AppFlow.title;


  final WebsocketService _ws = WebsocketService();

  Game? get game => _game;
  Player? get player => _player;

  GameState(){
    _ws.stream.listen(_handleWsEvent);
  }

  //Manage the transitions till the lobby
  void goToJoinOrCreate(){
    flow = AppFlow.joinOrCreate;
    notifyListeners();
  }

  void goToJoin(){
    flow = AppFlow.join;
    notifyListeners();
  }

  void goToCreate(){
    flow = AppFlow.create;
    notifyListeners();
  }

  void goToGamePhase(){
    flow = AppFlow.inGame;
    notifyListeners();
  }

  //Manage game transitions

  

  //Manage HTTP requests
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
    _openWebSocket();
    notifyListeners();
  }

  Future<void> joinGameAndSetSession(String nickname, String password) async {
    final session = await joinGame(nickname, password);

    _game = session.game;
    _player = session.player;
    _openWebSocket();
    notifyListeners();
  }

  //Manage websocket
  void _openWebSocket(){
    if(game == null || player == null) return;

    final url = 'wss://llminfabula.onrender.com/ws/game/${game!.id}/${player!.id}/';
    _ws.openWebSocketConnection(url);
    debugPrint("Connection opened");
  }

  void sendMessage(Map<String, dynamic> data){
    _ws.send(data);
  }

  void disconnect() {
    _ws.close();
  }

  void _handleWsEvent(Map<String, dynamic> event){
    debugPrint("Handling event");
    switch (event['type']) {
      case 'player_joined':
        _onPlayerJoined(event['player_id'], event['nickname'], event['is_dead']);
        break;
    }
  }

  //Manage websocket events
  void _onPlayerJoined(int playerId, String nickname, bool isDead){
    //Check that the received player is not already registered in the game state
    for(final p in game!.players){
      if(p.id == playerId) return;
    }

    var player = Player(id: playerId, nickname: nickname, isDead: isDead);
    game!.players.add(player);

    notifyListeners();
  }


}