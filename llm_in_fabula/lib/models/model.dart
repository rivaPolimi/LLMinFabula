enum Phase {lobby, inGame}

class Player {
  final int id;
  final String nickname;
  final bool isAdmin;
  //TODO: serve ruolo?

  const Player({required this.id, required this.nickname, required this.isAdmin});

  int getId(){
    return id;
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
  Phase gamePhase = Phase.lobby;

  Game({required this.id, required this.players});

  int getId(){
    return id;
  }

  void addPlayer(Player player){
    if (gamePhase != Phase.lobby){
      throw Exception('Game already started');
    }
    else if(players.contains(player)){
      throw Exception('Player already in game');
    }
    else{
      players.add(player);
    }
  }

  void startGame(Phase nextPhase){
    if(nextPhase != gamePhase){
      gamePhase = nextPhase;
    }
    else {
      throw Exception('Game already in this phase');
    }
  }

  factory Game.fromJson(Map<String, dynamic> json){
    return switch(json){
      {'id': int id, 'players': List<Player> players,} => Game(id: id, players: players),
      _ => throw const FormatException('Failed to load Game'),
    };
  }
}