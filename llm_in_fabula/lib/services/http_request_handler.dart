import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:llm_in_fabula/models/model.dart';
import 'package:llm_in_fabula/models/session.dart';
import 'package:flutter/foundation.dart';
import 'package:llm_in_fabula/constants.dart';

//TODO: Remove debugPrint

Future<GameSession> createGame(int numPlayers, String settingName, String nickname, String password, Map<String, int> roles) async{
  debugPrint('➡️ createGame called');
  debugPrint('Payload: ${json.encode({
    'max_players': numPlayers,
    'setting': settingName,
    'nickname': nickname,
    'password': password,
    'roles_available': roles,
  })}');

  final response = await http.post(
    Uri.parse('${getApiUrl()}/game/create_game/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: json.encode(<String, dynamic> {
      'max_players': numPlayers,
      'setting': settingName,
      'nickname': nickname,
      'password': password,
      'roles_available': roles,
    }),
  );

  debugPrint('⬅️ Response status: ${response.statusCode}');
  debugPrint('⬅️ Response body: ${response.body}');

  if(response.statusCode == 201){
    var decoded = jsonDecode(response.body) as Map<String, dynamic>;
    var player = Player(id: decoded['player_id'], nickname: nickname, isAdmin: true);
    var game = Game(id: decoded['game_id'], players: List.empty(growable: true), setting: settingName);
    game.players.add(player);
    //openWebSocketConnection();
    return GameSession(game: game, player: player);
  }
  else {
    throw Exception('Failed to create game');
  }
}

Future<GameSession> joinGame(String nickname, String password) async{
  debugPrint('➡️ joinGame called');
  debugPrint('Payload: ${json.encode({
    'nickname': nickname,
    'password': password,
  })}');
  
  final response = await http.post(
    Uri.parse('${getApiUrl()}/game/join_game/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: json.encode(<String, dynamic> {
      'password': password,
      'nickname': nickname,
    }),
  );

  debugPrint('⬅️ Response status: ${response.statusCode}');
  debugPrint('⬅️ Response body: ${response.body}');

  if (response.statusCode == 200) {
    var decoded = json.decode(response.body) as Map<String, dynamic>;
    var rawPlayers = decoded['players'];
    List<Player> players = List.empty(growable: true);
    for(final p in rawPlayers){
      //In join enviroment we don't care about isAdmin variable
      players.add(Player(id: p['id'], nickname: p["nickname"], isAdmin: false));
    }
    var game = Game(id: decoded['game_id'], players: players);
    var player = Player(id: decoded['player_id'], nickname: nickname, isAdmin: false);
    //openWebSocketConnection();
    return GameSession(game: game, player: player);
  } 
  else {
    throw Exception('Failed to join Game');  
  }
}

//List<dynamic> is not a subtype of List<Player>

Future<bool> startGame(Game game, Player player) async{
  final response = await http.post(
    Uri.parse('${getApiUrl()}/game/start_game/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: json.encode(<String, dynamic> {
      'game_id': game.id,
      'player_id': player.id,
    }),
  );
  debugPrint(response.statusCode.toString());
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}