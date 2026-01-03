from .redis import redis_client
from models import Game
from engine import GameEngine
from channels.db import database_sync_to_async


async def start_phase_timer(game_id, phase_name: str, duration: int):
    """
    Starts asynchronous timer for phase to expire
    """
    
    key = f"phase:{phase_name}_{game_id}"
    await redis_client.set(key, "1", ex=duration)

def end_phase(key: str, game_id: int):
    game = database_sync_to_async(Game.objects.get(id=game_id))

    phase = game.state
    if phase != key:
        return
    
    if key == "introduction":
        GameEngine.role_reveal(game)
    if key == "role_reveal":
        GameEngine.night_intro(game)
    if key == "night_intro":
        GameEngine.handle_night(game)
    if key == "night_report":
        GameEngine.check_win_engine(game, "night_report")
    if key == "lynch_outcome":
        GameEngine.check_win_engine(game, "lynch_outcome")