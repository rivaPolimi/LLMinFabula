import logging
import asyncio
import threading
from ..models import Game
from .timer_manager import schedule_timer
from ..db_utils import retry_on_db_lock_async

logger = logging.getLogger("redis_events")

# Global reference to the background event loop
_event_loop: asyncio.AbstractEventLoop | None = None
_loop_lock = threading.Lock()


def _get_or_create_event_loop() -> asyncio.AbstractEventLoop:
    """Get the running event loop or create a background one."""
    global _event_loop
    
    try:
        # Try to get the currently running loop
        return asyncio.get_running_loop()
    except RuntimeError:
        # No running loop, use/create background loop
        with _loop_lock:
            if _event_loop is None or _event_loop.is_closed():
                _event_loop = asyncio.new_event_loop()
                
                # Start running the loop in a background thread
                def run_loop():
                    asyncio.set_event_loop(_event_loop)
                    _event_loop.run_forever()
                
                thread = threading.Thread(target=run_loop, daemon=True, name="asyncio-event-loop")
                thread.start()
                logger.info("Started background asyncio event loop thread")
            
            return _event_loop


def start_phase_timer(game_id: int, phase_name: str, duration: int):
    """
    Schedule a phase timer using asyncio.
    Safe to call from sync or async contexts (including thread pools).
    """
    key = f"phase:{phase_name}_{game_id}"
    
    async def schedule():
        await schedule_timer(key, duration, _on_phase_expire)
    
    try:
        loop = _get_or_create_event_loop()
        asyncio.run_coroutine_threadsafe(schedule(), loop)
    except Exception as e:
        logger.error("Error scheduling phase timer: %s", e)
        return
    
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
    Handle phase transition with retry logic for database locks.
    """
    try:
        # Retry fetching the game if database is locked
        def get_game():
            return Game.objects.get(id=game_id)
        
        game = await retry_on_db_lock_async(get_game)
    except Game.DoesNotExist:
        logger.error("Game not found: game_id=%s", game_id)
        return
    except Exception as e:
        logger.exception("Error fetching game: %s", e)
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
        try:
            await retry_on_db_lock_async(handler, game)
        except Exception as e:
            logger.exception("Error executing phase handler: %s", e)
    else:
        logger.warning("No handler for phase: %s", phase_name)
