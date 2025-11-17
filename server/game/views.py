import json
import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
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
        num = lobby_configurations.get("num_players")
        set = lobby_configurations.get("setting")
        passw = lobby_configurations.get("password")
        roles_available = lobby_configurations.get("roles_available")
        nick = lobby_configurations.get("nickname")
    
        game = Game.objects.create(
            num_players = num,
            setting = set,
            password = passw,
        )
        game.save()
    
        roles = Role.objects.create(
            game_id = game.id,
            wolf = roles_available.get("wolf"),
            villager = roles_available.get("villager"),
            seer = roles_available.get("seer"),
            madman = roles_available.get("madman"),
            courtesan = roles_available.get("courtesan"),
            medium = roles_available.get("medium"),
            hunter = roles_available.get("hunter"),
            jailer = roles_available.get("jailer"),
            copycat = roles_available.get("copycat"),
            sentry = roles_available.get("sentry"),
        )
        roles.save()
    
        player = Player.objects.create(
            game_id = game.id,
            nickname = nick
        )
        player.save()
    
        return Response({"status": "Lobby created", "game_id": game.id, "player_id": player.id, "is_admin": True}, 
                        status=status.HTTP_201_CREATED)

class JoinGameView(APIView):

    def post(self, request):
        join_configuration = json.loads(request.body)
        nick = join_configuration.get("nickname")
        passw = join_configuration.get("password")

        # Search a not full lobby which matches password or raises 404_NOT_FOUND error
        queryset = Game.objects.filter(is_full=False)
        game = get_object_or_404(queryset, password=passw)

        player = Player.objects.get_or_create(
            nickname=nick, game_id=game.id
        )

        # Update status if lobby becomes full
        if check_full(game.id):
            game.is_full = True
            game.save(update_fields=["is_full"])

        return Response({"game_id": game.id, "player_id": player.id, "is_admin": False}, 
                        status=status.HTTP_200_OK)
    
class StartGameView(APIView):

    def post(self, request):
        start_data = json.loads(request.body)
        game_id = start_data.get("game_id")
        player_id = start_data.get("player_id")

        game = get_object_or_404(Game, id=game_id)
        players_in_lobby = get_players(game)
        roles = get_object_or_404(Role, game_id=game_id)

        # Check that game exists and contains player
        if not players_in_lobby.filter(id=player_id).exists():
            return Response({"error": "Player not in game"}, status=status.HTTP_403_FORBIDDEN)
        
        # Start game
        game.phase = "first_night"
        game.is_full = True # Set lobby to full, in this way no other player can join
        game.save()

        # assign roles
        role_pool = []
        for name, limit in roles.get_fields():
            role_pool.extend([name] * limit)

        players = list(players_in_lobby)
        random.shuffle(players)

        role_pool = role_pool[:len(players)]

        for player, role_name in zip(players, role_pool):
            player.role = role_name
            player.save(update_fields=["role"])

        # Broadcast that game started
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"game_{game_id}_all",
            {"type": "game.started", "message": "Game started", "game_id": game.id}
        )

        # Generates introduction
        gen_introduction(game_id, game.setting)

        return Response({"detail": "Game started"})

