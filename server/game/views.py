import json
import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import *
from .utils import *
from .narrator import *
#from .serializers import GameSerializer, JoinSerializer
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

class CreateGameView(APIView):

    def post(self, request):
        lobby_configurations = json.loads(request.body)
        num = lobby_configurations.get("max_players")
        set = lobby_configurations.get("setting")
        passw = lobby_configurations.get("password")
        roles_available = lobby_configurations.get("roles_available")
        nick = lobby_configurations.get("nickname")
    
        game = Game.objects.create(
            max_players = num,
            setting = set,
            password = passw,
            available_roles = roles_available,
        )
        game.save()
    
        player = Player.objects.create(
            game_id = game.id,
            nickname = nick
        )
        player.save()

        #TODO: differenza tra admin e non controllata sul client
        return Response({"status": "Lobby created", "game_id": game.id, "player_id": player.id}, 
                        status=status.HTTP_201_CREATED)

class JoinGameView(APIView):

    def post(self, request):
        join_configuration = json.loads(request.body)
        nick = join_configuration.get("nickname")
        passw = join_configuration.get("password")

        # Search a not full lobby which matches password or raises 404_NOT_FOUND error
        queryset = Game.objects.raw(
            'SELECT g.id, g.password ' \
            'FROM Game as g ' \
            'WHERE g.id and g.max_players > (SELECT count(*)' \
            'FROM Player as p' \
            'WHERE p.game_id = g.id)'
        )
        game = get_object_or_404(queryset, password=passw)

        player = Player.objects.get_or_create(
            nickname=nick, game_id=game.id
        )

        return Response({"game_id": game.id, "player_id": player.id, "is_admin": False}, 
                        status=status.HTTP_200_OK)
    
class StartGameView(APIView):

    def post(self, request):
        start_data = json.loads(request.body)
        game_id = start_data.get("game_id")
        player_id = start_data.get("player_id")

        game = get_object_or_404(Game, id=game_id)
        players_in_lobby = get_players(game)

        # Check that game exists and contains player
        if not players_in_lobby.filter(id=player_id).exists():
            return Response({"error": "Player not in game"}, status=status.HTTP_403_FORBIDDEN)

        # assign roles
        role_pool = []
        for name, limit in game.available_roles:
            role_pool.extend([name] * limit)

        players = list(players_in_lobby)
        random.shuffle(players)

        role_pool = role_pool[:len(players)]

        for player, role_name in zip(players, role_pool):
            role = get_object_or_404(Role, name=role_name)
            player.role = role
            player.save(update_fields=["role"])

        # Broadcast that game started
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"game_{game_id}_all",
            {"type": "game.started", "message": "Game started", "game_id": game.id}
        )

        # Generates introduction
        gen_introduction(game_id, game.setting)
        #TODO: FIX RENDERLO COERENTE CON NUOVA FSM
        transition(game.id)

        return Response({"detail": "Game started"})