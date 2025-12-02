"""
Helper functions for game and lobby management
"""

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.db.models import Q
from .models import *

    
def get_players(game):
    players = Player.objects.filter(game=game)

    #TODO: check if empty and rise exception

    return players

def send_poll(game, poll):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game.id}_{poll.role}",
        {"type": "poll", "poll_id": poll.id, "duration": poll.duration}
    )
    pass

def kill_player(game, player):
    channel_layer = get_channel_layer()

    player.is_dead = True
    player.protected = False
    ghost = Role.objects.filter(name = "ghost")
    player.role = ghost
    player.save()

    async_to_sync(channel_layer.group_send)(
        f"game_{game.id}_{player.id}",
        {"type": "player.eliminated", "message": "You've been killed",},
    )

def check_win(game):
    """
    Check if somebody as won
    """

    # Madman wins if lynched
    if game.lynch_target.role.name == "madman":
        return True, game.lynch_target
    
    wolves = game.get_active_players().filter(role__name = "wolf")
    villagers = game.get_active_players().exclude(role__name = "wolf")

    # Good guys win if no wolf remain
    if not wolves:
        return True, game.get_active_players().exclude(role__name = "madman").exclude(role__name = "copycat")
    
    # Wolves wins if they are equal or more than the good roles
    if len(wolves) >= len(villagers):
        return True, wolves
    
    return False, None

def handle_win(game, winners):
    """
    Send all the players a message with the outcome of the game
    """

    players = Player.objects.filter(game=game)
    channel_layer = get_channel_layer()
    for player in players:
        if player in winners:
            async_to_sync(channel_layer.group_send)(
                f"game_{game.id}_{player.id}",
                {"type": "game.ended", "outcome": "win",},
            )
        else:
            async_to_sync(channel_layer.group_send)(
                f"game_{game.id}_{player.id}",
                {"type": "game.ended", "outcome": "lost",},
            )
    clear_game(game)

def clear_game(game):
    """
    Removes the game instance from the DB
    """
    #TODO: se i poll li cancello appena finiti non serve cancellarli qui se no devo cancellarli qui
    Player.objects.filter(game=game).delete()
    Game.objects.filter(id=game.id).delete()
