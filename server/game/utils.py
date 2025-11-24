"""
Helper functions for game and lobby management
"""

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.db.models import Q
from .models import *

    
def get_players(game):
    players = Player.objects.filter(game_id=game.id)

    #TODO: check if empty and rise exception

    return players

def check_win(game):
    """
    Check if somebody as won
    """

    # Madman wins if lynched
    if game.lynch_target.role.name == "madman":
        return True, game.lynch_target
    
    wolves = game.get_active_players().filter(role__name = "wolf")
    villagers = game.get_active_players().filter(~Q(role__name = "wolf"))

    # Good guys win if no wolf remain
    if not wolves:
        return True, game.get_active_players().filter(~Q(role__name = "madman") | ~Q(role__name = "copycat"))
    
    # Wolves wins if they are equal or more than the good roles
    if len(wolves) >= len(villagers):
        return True, wolves
    
    return False, None

def handle_win(game, winners):
    """
    Send all the players a message with the outcome of the game
    """

    players = Player.objects.filter(game_id = game.id)
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
