import json
import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404, render
from django.db.models import Count, F, Q
from django.core.paginator import Paginator
from .notifications import notify_game_started, notify_wolves
from .engine import GameEngine
from .models import Game, Player, Role, Setting, RedisEventLog
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
        queryset = (
            Game.objects
                .annotate(player_count=Count('players'))
                .filter(max_players__gt=F('player_count'))
        )
        game = get_object_or_404(queryset, password=passw)

        player = Player.objects.create(
            nickname=nick, game=game
        )
        #TODO: come tengo aggiornata la lista di players nella lobby?
        return Response({"game_id": game.id, "player_id": player.id, "players": list(game.get_active_players().values('id', 'nickname', 'is_dead'))},
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
        for name, limit in game.available_roles.items():
            role_pool.extend([name] * limit)

        players = list(players_in_lobby)
        random.shuffle(players)

        role_pool = role_pool[:len(players)]

        for player, role_name in zip(players, role_pool):
            role = get_object_or_404(Role, name=role_name)
            player.role = role
            player.role_name = role_name
            player.save()

        # Broadcast that game started
        notify_game_started(game.id)

        GameEngine.start_game(game)      

        return Response({"detail": "Game started"}, status=status.HTTP_200_OK)


import logging
from django.shortcuts import render
from django.core.paginator import Paginator
from .models import RedisEventLog

logger = logging.getLogger('redis_events')

def redis_logs_view(request):
    """View to display Redis event logs with filtering and search."""
    
    # Get all logs
    logs = RedisEventLog.objects.all().order_by('-timestamp')
    
    # Get unique values for filter dropdowns
    levels = logs.values_list('level', flat=True).distinct().order_by('level')
    phases = logs.values_list('phase', flat=True).distinct().exclude(phase__isnull=True).exclude(phase='')
    
    # Apply filters
    current_filters = {}
    
    if request.GET.get('level'):
        level = request.GET.get('level')
        logs = logs.filter(level=level)
        current_filters['level'] = level
    
    if request.GET.get('game_id'):
        game_id = request.GET.get('game_id')
        logs = logs.filter(game_id=game_id)
        current_filters['game_id'] = game_id
    
    if request.GET.get('phase'):
        phase = request.GET.get('phase')
        logs = logs.filter(phase=phase)
        current_filters['phase'] = phase
    
    if request.GET.get('search'):
        search = request.GET.get('search')
        logs = logs.filter(message__icontains=search)
        current_filters['search'] = search
    
    total_count = logs.count()
    
    # Pagination
    paginator = Paginator(logs, 50)
    page_number = request.GET.get('page', 1)
    page_obj = paginator.get_page(page_number)
    
    # Debug logging
    print(f"[DEBUG] Total logs in database: {RedisEventLog.objects.count()}")
    print(f"[DEBUG] Filtered logs: {total_count}")
    print(f"[DEBUG] Page object: {page_obj}")
    #logger.info(f"Redis logs view accessed - Total logs: {RedisEventLog.objects.count()}, Filtered: {total_count}")
    
    return render(request, 'game/redis_logs.html', {
        'page_obj': page_obj,
        'total_count': total_count,
        'levels': levels,
        'phases': phases,
        'current_filters': current_filters,
    })