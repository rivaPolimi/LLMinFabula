from .redis import redis_client
from ..models import Game
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
    
    from ..engine import GameEngine

    if key == "introduction":
        GameEngine.role_reveal(game)
    if key == "roleReveal":
        GameEngine.night_intro(game)
    if key == "nightIntro":
        GameEngine.handle_night(game)
    if key == "nightReport":
        GameEngine.check_win_engine(game, "nightReport")
    if key == "lynchOutcome":
        GameEngine.check_win_engine(game, "lynchOutcome")