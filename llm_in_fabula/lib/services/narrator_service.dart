import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:llm_in_fabula/models/model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


Future<List<dynamic>> createGame(int numPlayers, String settingName, String nickname, String password, Map<String, int> roles) async{
  final response = await http.post(
    Uri.parse('https://llminfabula.onrender.com/api/game/create_game'),
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

  if(response.statusCode == 201){
    var decoded = jsonDecode(response.body) as Map<String, dynamic>;
    var game = Game(id: decoded['game_id'], players: List.empty());
    var player = Player(id: decoded['player_id'], nickname: nickname, isAdmin: true);
    return <dynamic>[game, player];
  }
  else {
    throw Exception('Failed to create game');
  }
}

Future<List<dynamic>> joinGame(String nickname, String password) async{
  final response = await http.post(
    Uri.parse('https://llminfabula.onrender.com/api/game/join_game'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: json.encode(<String, dynamic> {
      'password': password,
      'nickname': nickname,
    }),
  );

  if (response.statusCode == 200) {
    var decoded = json.decode(response.body) as Map<String, dynamic>;
    var game = Game(id: decoded['game_id'], players: decoded['players']);
    var player = Player(id: decoded['player_id'], nickname: nickname, isAdmin: false);
    return <dynamic>[game, player];
  } 
  else {
    throw Exception('Failed to join Game');  
  }
}

//Future<bool> startGame(Game game, Player player) async{
//  final response = await http.post(
//    Uri.parse('https://llminfabula.onrender.com/api/game/start_game'),
//    headers: <String, String>{
//      'Content-Type': 'application/json; charset=UTF-8',
//    },
//    body: json.encode(<String, dynamic> {
//      
//    }),
//  );
//}