class Player {
  final int id;
  final String nickname;
  final bool isAdmin;
  bool isDead = false;
  late final String roleName;
  late final String roleDescription;

  Player({required this.id, required this.nickname, this.isAdmin = false, this.isDead = false});

  int getId(){
    return id;
  }

  bool getIsDead(){
    return isDead;
  }

  void setIsDead(bool value){
    isDead = value;
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return switch(json){
      {'id': int id, 'nickname': String nickname, 'isAdmin': bool isAdmin} => Player(id: id, nickname: nickname, isAdmin: isAdmin),
      _ => throw const FormatException('Failed to load Player'),
    };
  }
}

class Game {
  final int id;
  final List<Player> players;
  String? setting;
  String rolePlaying = 'none';

  Game({required this.id, required this.players, this.setting});

  int getId(){
    return id;
  }

  void addPlayer(Player player){
    if(players.contains(player)){
      throw Exception('Player already in game');
    }
    else{
      players.add(player);
    }
  }

  factory Game.fromJson(Map<String, dynamic> json){
    return switch(json){
      {'id': int id, 'players': List<Player> players,} => Game(id: id, players: players),
      _ => throw const FormatException('Failed to load Game'),
    };
  }
}

class Vote {
  final int voterId;
  final int votedPlayerId;

  Vote({required this.voterId, required this.votedPlayerId});
}