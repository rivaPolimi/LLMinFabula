import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llm_in_fabula/services/tts.dart';
import 'package:llm_in_fabula/services/websocket_service.dart';
import 'model.dart';
import 'package:llm_in_fabula/services/http_request_handler.dart';
import 'package:llm_in_fabula/constants.dart';

enum GamePhase {lobby, introduction, roleReveal, discussion, extraVote, lynch, nightIntro, nightReport, roleAction, checkWin, endGame}
enum AppFlow {title, joinOrCreate, join, create, inGame,}

class GameState extends ChangeNotifier{
  Game? _game;
  Player? _player;

  AppFlow flow = AppFlow.title;

  GamePhase phase = GamePhase.lobby;
  late DateTime phaseStart;
  late int duration;
  DateTime? _localPhaseStart; // Track when we received the phase locally

  Tts tts = Tts();
  String? narratorText;

  Timer? _ticker;

  final WebsocketService _ws = WebsocketService();

  //Getters
  Game? get game => _game;
  Player? get player => _player;
  Duration get remaining {
    // Use local time to calculate elapsed, avoiding clock skew issues
    if (_localPhaseStart == null) return Duration(seconds: duration);
    
    final elapsed = DateTime.now().difference(_localPhaseStart!);
    final remaining = Duration(seconds: duration) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  GameState(){
    _ws.stream.listen(_handleWsEvent);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  //Timer handlers
  void _startTicker(){
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_){
      notifyListeners();
    });
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

  //Manage TextToSpeech
  void _configureTts() async{
    tts.configureTts();
  }

  void startTts(){
    if(narratorText == null) return;

    tts.speakText(
      narratorText!,
      onComplete: _onTtsCompleted,
    );
  }

  void _onTtsCompleted(){
    debugPrint("FINISHED TALKING");
    _ws.send({
      "type": "narration_finished",
      "phase": phase.name,
    });
  }

  void _stopTts(){
    //Stops current tts instance if it is running
    if(tts.state == TtsState.stopped) return;
    tts.stopSpeaking();
  }

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
    _configureTts();
    notifyListeners();
  }

  Future<void> joinGameAndSetSession(String nickname, String password) async {
    final session = await joinGame(nickname, password);

    _game = session.game;
    _player = session.player;
    _openWebSocket();
    _configureTts();
    notifyListeners();
  }

  void startGameSession() async {
    await startGame(game!, player!);
  }

  //Manage websocket
  void _openWebSocket(){
    if(game == null || player == null) return;

    final url = '${getWsUrl()}/game/${game!.id}/${player!.id}/';
    _ws.openWebSocketConnection(url).then((_) {
      debugPrint("✅ WebSocket ready to send messages");
    });
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

      case 'game_phase':
        final startedAt = DateTime.parse(event['started_at']);
        _onUpdatePhase(event['phase'], startedAt, event['duration']);
        break;

      case 'narrator':
        _onNarratorStoryReceived(event['phase'], event['text']);
        break;

      case 'role_reveal':
        _onRoleReveal(event['name'], event['description']);
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

  void _onUpdatePhase(String phase, DateTime start, int duration){
    debugPrint("🟢 Final rule of thumb");
    debugPrint("Phase: $phase");
    debugPrint("Start: $start");
    debugPrint("Duration: $duration");
    this.phase = GamePhase.values.byName(phase);
    phaseStart = start;
    this.duration = duration;
    _localPhaseStart = DateTime.now(); // Capture local time when phase starts

    _stopTts();
    _startTicker();
    notifyListeners();
  }

  void _onNarratorStoryReceived(String phase, String text){
    debugPrint("NarratorPhase: $phase");
    debugPrint("This phase: ${this.phase}");
    debugPrint("Story: $text");

    narratorText = text;
    
    notifyListeners();
  }

  //TODO: non sto usando game_id e original_name
  void _onRoleReveal(String roleName, String roleDescription){
    debugPrint("Rolename: {$roleName}");
    player!.roleName = roleName;
    player!.roleDescription = roleDescription;

    notifyListeners();
  }
}