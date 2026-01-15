import logging
import asyncio
from ..models import Game
from channels.db import database_sync_to_async
from .timer_manager import schedule_timer

logger = logging.getLogger("redis_events")


def start_phase_timer(game_id: int, phase_name: str, duration: int):
    """
    Schedule a phase timer using asyncio.
    """
    key = f"phase:{phase_name}_{game_id}"
    
    # Schedule the timer
    async def schedule():
        await schedule_timer(key, duration, _on_phase_expire)
    
    # Run in a thread-safe way
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.create_task(schedule())
        else:
            loop.run_until_complete(schedule())
    except Exception as e:
        logger.error("Error scheduling phase timer: %s", e)
    
    logger.info("Starting phase timer: game_id=%s phase=%s duration=%ss", game_id, phase_name, duration, extra={'game_id': game_id, 'phase': phase_name})


async def _on_phase_expire(key: str):
    """
    Called when a phase timer expires.
    """
    try:
        # Parse key: phase:phaseName_gameId
        parts = key.replace('phase:', '').rsplit('_', 1)
        if len(parts) != 2:
            logger.error("Invalid phase key format: %s", key)
            return
        
        phase_name, game_id_str = parts
        game_id = int(game_id_str)
        
        logger.info("Phase timer expired: game_id=%s phase=%s", game_id, phase_name, extra={'game_id': game_id, 'phase': phase_name})
        
        await end_phase(phase_name, game_id)
    except Exception as e:
        logger.exception("Error handling phase expiry for key %s: %s", key, e)


async def end_phase(phase_name: str, game_id: int):
    """
    Handle phase transition.
    """
    try:
        game = await database_sync_to_async(Game.objects.get)(id=game_id)
    except Game.DoesNotExist:
        logger.error("Game not found: game_id=%s", game_id)
        return

    # Verify we're in the right phase
    if game.state != phase_name:
        logger.info("Ignoring phase expiry: game_id=%s expected=%s actual=%s", game_id, phase_name, game.state)
        return
    
    from ..engine import GameEngine
    
    # Map phase name to transition
    transitions = {
        "introduction": lambda g: GameEngine.role_reveal(g),
        "roleReveal": lambda g: GameEngine.night_intro(g),
        "nightIntro": lambda g: GameEngine.handle_night(g),
        "nightReport": lambda g: GameEngine.check_win_engine(g, "nightReport"),
        "lynchOutcome": lambda g: GameEngine.check_win_engine(g, "lynchOutcome"),
    }
    
    handler = transitions.get(phase_name)
    if handler:
        logger.info("Executing phase transition: phase=%s (game_id=%s)", phase_name, game_id, extra={'game_id': game_id, 'phase': phase_name})
        await database_sync_to_async(handler)(game)
    else:
        logger.warning("No handler for phase: %s", phase_name)
