"""
Helper functions for game and lobby management
"""

from .models import *
    
def get_players(game):
    players = Player.objects.filter(game_id=game.id)

    #TODO: check if empty and rise exception

    return players