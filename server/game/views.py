import json
import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .notifications import notify_game_started
from .engine import GameEngine
from .models import Game, Player, Role, Setting
from .narrator import Narrator
from .utils import get_players
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

@method_decorator(csrf_exempt, name='dispatch')
class CreateGameView(APIView):

    def post(self, request):
        lobby_configurations = json.loads(request.body)
        num = lobby_configurations.get("max_players")
        set = lobby_configurations.get("setting")
        passw = lobby_configurations.get("password")
        roles_available = lobby_configurations.get("roles_available")
        nick = lobby_configurations.get("nickname")
    
        setting = get_object_or_404(Setting, name=set)

        game = Game.objects.create(
            max_players = num,
            setting = setting,
            password = passw,
            available_roles = roles_available,
        )
        game.save()
    
        player = Player.objects.create(
            game = game,
            nickname = nick
        )
        player.save()

        #TODO: differenza tra admin e non va controllata sul client
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
            nickname=nick, game=game
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
            player.role_name = role_name
            player.save(update_fields=["role"])

        # Broadcast that game started
        notify_game_started(game.id)

        # Generates introduction
        Narrator.gen_introduction(game_id, game.setting)
        GameEngine.start_game(game)      

        return Response({"detail": "Game started"})