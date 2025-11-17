"""
Helper functions for game and lobby management
"""

from .models import *
from django.shortcuts import get_object_or_404

def check_full(game_id):
    players = Player.objects.filter(game_id=game_id)
    game = get_object_or_404(Game, id=game_id)
    capacity = game.num_players

    if len(players) >= capacity:
        return True
    else:
        return False
    
def get_players(game):
    players = Player.objects.filter(game_id=game.id)

    #TODO: check if empty and rise exception

    return players