import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llm_in_fabula/services/tts.dart';
import 'package:llm_in_fabula/services/websocket_service.dart';
import 'model.dart';
import 'package:llm_in_fabula/services/http_request_handler.dart';
import 'package:llm_in_fabula/constants.dart';
import 'package:llm_in_fabula/models/game_theme.dart';

enum GamePhase {lobby, introduction, roleReveal, discussion, extraVote, lynch, nightIntro, nightActionPrompt, nightReport, roleAction, checkWin, endGame}
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
  int? selectedPlayerId;

  Timer? _ticker;

  final WebsocketService _ws = WebsocketService();

  //Getters
  Game? get game => _game;
  Player? get player => _player;

  /// Get the current game theme based on setting
  GameTheme get theme => GameThemes.getTheme(_game?.setting ?? 'medieval');

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

  void selectPlayer(int playerId) {
    selectedPlayerId = playerId;
    notifyListeners();
  }

  void confirmVote() {
    if (selectedPlayerId == null) return;
    // TODO: Send vote to server
    debugPrint("Voted for player $selectedPlayerId");
    // maybe reset selection after voting?
    // selectedPlayerId = null;
    notifyListeners();
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

    // For testing: automatically advance to the night prompt after the intro
    if (phase == GamePhase.nightIntro) {
      phase = GamePhase.nightActionPrompt;
      notifyListeners();
      return;
    }

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
    _game!.setting = settingName; // Store the setting
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
    phaseStart = DateTime.now().isAfter(start) ? start : DateTime.now();
    this.duration = duration;
    _localPhaseStart = DateTime.now(); // Capture local time when phase starts
    selectedPlayerId = null; // Reset selection on new phase

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

  //diego: added this method to add fake players to the lobby
  void addFakePlayersForTesting(int totalPlayers) {
    if (_game == null) return;

    final List<String> fakeNames = [
      'Sirius', 'Remus', 'Albus', 'Minerva', 'Draco', 'Luna', 'Ginny',
      'Severus', 'Rubeus', 'Harry', 'Ron', 'Hermione', 'Neville'
    ];

    int currentPlayersCount = _game!.players.length;
    int playersToAdd = totalPlayers - currentPlayersCount;

    if (playersToAdd <= 0) return;

    for (int i = 0; i < playersToAdd; i++) {
      final name = (i < fakeNames.length) ? fakeNames[i] : 'Bot ${i + 1}';
      // Usiamo un ID negativo per distinguerli facilmente dai giocatori reali
      final fakePlayer = Player(
        id: -1 - i,
        nickname: name,
        isAdmin: false,
        isDead: false,
      );
      _game!.players.add(fakePlayer);
    }


    notifyListeners();
  }
}
