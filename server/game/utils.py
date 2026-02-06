"""
Helper functions for game and lobby management
"""

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import *
from .notifications import notify_player_eliminated, notify_game_end

    
def get_players(game):
    players = Player.objects.filter(game=game)

    #TODO: check if empty and rise exception

    return players

def resolve_night(game: Game):
    """
    Perform all the actions which involves targeting another player.
    Returns the killed player(s) or None if nobody was killed.
    """
    target_player = game.wolf_target
    killed_players = []

    if target_player is None:
        return None

    # Target does not die if he is protected
    if target_player.is_protected:
        return None

    # If courtesan is killed also her protected dies
    if target_player.role.name == "courtesan":
        protected_player = game.courtesan_target
        game.courtesan_target = None
        if not protected_player.role == "wolf":
            kill_player(protected_player)
            killed_players.append(protected_player)

    # If hunter is killed also his target dies
    elif target_player.role.name == "hunter":
        aimed_player = game.hunter_target
        game.hunter_target = None
        kill_player(game, aimed_player)
        killed_players.append(aimed_player)

    kill_player(game, target_player)

    killed_players.append(target_player)

    return killed_players

def kill_player(game: Game, player: Player):
    player.is_dead = True
    player.is_protected = False
    ghost = Role.objects.filter(name = "ghost").first()
    if ghost:
        player.role = ghost
    player.save()

    notify_player_eliminated(game.id, player.id)

def check_win(game):
    """
    Check if somebody as won
    """

    # Madman wins if lynched
    if game.lynch_target and game.lynch_target.role.name == "madman":
        return True, game.lynch_target
    
    wolves = list(game.get_active_players().filter(role__name = "wolf"))
    villagers = list(game.get_active_players().exclude(role__name = "wolf"))

    # Good guys win if no wolf remain
    if not wolves:
        return True, list(game.get_active_players().exclude(role__name = "madman").exclude(role__name = "copycat"))
    
    # Wolves wins if they are equal or more than the good roles
    if len(wolves) >= len(villagers):
        return True, wolves
    
    return False, None

def handle_win(game, winners):
    """
    Send all the players a message with the outcome of the game
    """

    players = Player.objects.filter(game=game)

    for player in players:
        if player in winners:
            notify_game_end(game.id, player.id, "win")
        else:
            notify_game_end(game.id, player.id, "lost")
    clear_game(game)

def clear_game(game):
    """
    Removes the game instance from the DB
    """
    #TODO: se i poll li cancello appena finiti non serve cancellarli qui se no devo cancellarli qui
    Player.objects.filter(game=game).delete()
    Game.objects.filter(id=game.id).delete()
