import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:llm_in_fabula/services/tts.dart';
import 'package:llm_in_fabula/services/websocket_service.dart';
import 'model.dart';
import 'package:llm_in_fabula/services/http_request_handler.dart';
import 'package:llm_in_fabula/constants.dart';
import 'package:llm_in_fabula/models/game_theme.dart';

enum GamePhase {lobby, introduction, roleReveal, discussion, lynching, nightIntro, nightReport, roleAction, endGame}
enum AppFlow {title, joinOrCreate, join, create, inGame,}

class GameState extends ChangeNotifier{
  Game? _game;
  Player? _player;

  // Recent victims
  Queue<Player> victims = Queue<Player>();

  // Votes
  Map<int, int> tally = {};

  AppFlow flow = AppFlow.title;

  GamePhase phase = GamePhase.lobby;
  late DateTime phaseStart;
  late int duration;
  DateTime? _localPhaseStart; // Track when we received the phase locally

  int? currentPollId = -1;

  Tts tts = Tts();
  String? narratorText;
  String? mysticText; // Medium or Seer revelations

  Timer? _ticker;

  final WebsocketService _ws = WebsocketService();

  //Getters
  Game? get game => _game;
  Player? get player => _player;

  /// Get the current game theme based on setting
  GameTheme get theme => GameThemes.getTheme(_game?.setting ?? 'classic');

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

  // Server interaction functions
  void confirmVote(int selectedPlayerId) {
    debugPrint("Voted for player $selectedPlayerId");
    // Send vote to server
    _ws.send({
      "type": "vote",
      "poll_id": currentPollId,
      "target": selectedPlayerId,
    });

    // Reset active poll after voting
    currentPollId = -1;
    // maybe reset selection after voting?
    // selectedPlayerId = null;
    notifyListeners();
  }

  void completeNightReportPhase(){
    _onTtsCompleted();
  }

  //Manage the transitions till the lobby
  void goToTitle(){
    flow = AppFlow.title;
    notifyListeners();
  }

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

  //Manage TextToSpeech
  void _configureTts() async{
    tts.configureTts();
  }

  void startTts([VoidCallback? onComplete]) {
    if(narratorText == null) return;

    final callback = onComplete ?? _onTtsCompleted;
    
    tts.speakText(
      narratorText!,
      onComplete: callback,
    );
  }

  void _onTtsCompleted(){
    debugPrint("FINISHED TALKING");

    if (player!.isAdmin) {
      _ws.send({
        "type": "narration_finished",
        "phase": phase.name,
      });
    }
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

  void resetGameState() {
    // Stop any ongoing TTS
    _stopTts();
    
    // Cancel timers
    _ticker?.cancel();
    
    // Disconnect websocket if still connected
    _ws.close();
    
    // Clear game data
    _game = null;
    _player = null;
    
    // Clear victims and votes
    victims.clear();
    tally.clear();
    
    // Reset phase and flow
    phase = GamePhase.lobby;
    flow = AppFlow.title;
    _localPhaseStart = null;
    
    // Clear poll
    currentPollId = -1;
    
    // Clear narrator and mystic text
    narratorText = null;
    mysticText = null;
    
    debugPrint("🔄 Game state has been reset");
    notifyListeners();
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
        _onRoleReveal(event['name'], event['description'], event['original_name']);
        break;

      case 'wolves_list':
        _onWolvesList(event['wolves']);
        break;
      
      case 'role_turn':
        _onRoleTurnChange(event['role']);
        break;

      case 'poll_begin':
        final startedAt = DateTime.parse(event['started_at']);
        _onPollBegin(event['poll_id'], event['duration'], startedAt);
        break;

      case 'night_victims':
        _onNightVictimReceived(event['victims_id']);
        break;

      case 'lynch_result':
        _onLynchVictimReceived(event['target_id']);
        break;

      case 'death':
        _onDeath();
        break;

      case 'tally':
        final tallyRaw = event['tally'] as Map<String, dynamic>;

        // Convert to a map with int keys
        final tally = tallyRaw.map((key, value) => 
          MapEntry(int.parse(key), value as int)
        );
        _onTallyUpdate(tally);
        break;

      case 'action_outcome':
        _onActionOutcome(event['target_name'], event['outcome']);
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

  // Sign all wolf allies
  void _onWolvesList(List<dynamic> wolvesId){
    debugPrint("Received wolves: $wolvesId");
    final integerIds = wolvesId.cast<int>();
    for (var id in integerIds) {
      final p = game!.getPlayerById(id);
      if(p != null){
        p.isWolf = true;
      }
    }
  }

  void _onUpdatePhase(String phase, DateTime start, int duration){
    debugPrint("🟢 Final rule of thumb");
    debugPrint("Phase: $phase");
    debugPrint("Start: $start");
    debugPrint("Duration: $duration");
    this.phase = GamePhase.values.byName(phase);
    if (duration > 0){
      phaseStart = DateTime.now().isAfter(start) ? start : DateTime.now();
      this.duration = duration;
      _localPhaseStart = DateTime.now(); // Capture local time when phase starts

      _startTicker();
    }

    _stopTts();
    notifyListeners();
  }

  void _onNarratorStoryReceived(String phase, String text){
    debugPrint("NarratorPhase: $phase");
    debugPrint("This phase: ${this.phase}");
    debugPrint("Story: $text");

    narratorText = text;

    notifyListeners();
  }

  void _onRoleReveal(String roleName, String roleDescription, String originalRoleName){
    debugPrint("Rolename: {$roleName}");
    player!.roleName = roleName;
    player!.roleDescription = roleDescription;
    player!.originalRoleName = originalRoleName;

    notifyListeners();
  }

  void _onRoleTurnChange(String roleName){
    game!.rolePlaying = roleName;
    notifyListeners();
  }

  void _onPollBegin(int id, int duration, DateTime start){
    currentPollId = id;
    phaseStart = DateTime.now().isAfter(start) ? start : DateTime.now();
    this.duration = duration;
    _localPhaseStart = DateTime.now();

    _startTicker();
    notifyListeners();
  }

  void _onNightVictimReceived(List<dynamic> victimsId){
    final integerIds = victimsId.cast<int>();
    for (var id in integerIds) {
      final p = game!.getPlayerById(id);
      if(p != null){
        p.isDead = true;
        victims.addFirst(p);
      }
    }
  }

  void _onLynchVictimReceived(int id){
    final p = game!.getPlayerById(id);
    if (p != null){
      p.isDead = true;
      victims.add(p);
    }
  }

  void _onDeath(){
    player!.isDead = true;
  }

  void _onTallyUpdate(Map<int, int> tally){
    // Check that the incoming tally is the most recent version
    for (var key in tally.keys) {
      if(!this.tally.containsKey(key) || this.tally[key]! < tally[key]!){
        this.tally = tally;
        break;
      }
    }

    notifyListeners();
  }

  void _onActionOutcome(String name, String outcome) {
    mysticText = '$name is a $outcome';
  }

  //TODO: RIMUOVI
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
      // Assign a default role to prevent initialization errors
      fakePlayer.roleName = 'villager';
      fakePlayer.roleDescription = 'A simple villager.';
      _game!.players.add(fakePlayer);
    }


    notifyListeners();
  }
}
