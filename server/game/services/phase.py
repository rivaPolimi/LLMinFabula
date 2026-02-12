import asyncio
import threading
from ..models import Game
from .timer_manager import schedule_timer
from ..db_utils import retry_on_db_lock_async

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
    except Exception:
        return


async def _on_phase_expire(key: str):
    """
    Called when a phase timer expires.
    """
    try:
        # Parse key: phase:phaseName_gameId
        parts = key.replace('phase:', '').rsplit('_', 1)
        if len(parts) != 2:
            return
        
        phase_name, game_id_str = parts
        game_id = int(game_id_str)
        
        await end_phase(phase_name, game_id)
    except Exception:
        return


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
        return
    except Exception as e:
        return

    # Verify we're in the right phase
    if game.state != phase_name:
        return
    
    from ..engine import GameEngine
    
    # Map phase name to transition
    transitions = {
        "introduction": lambda g: GameEngine.role_reveal(g),
        "roleReveal": lambda g: GameEngine.night_intro(g),
        "nightIntro": lambda g: GameEngine.handle_night(g),
        "nightReport": lambda g: GameEngine.check_win_engine(g, "nightReport"),
        "lynching": lambda g: GameEngine.check_win_engine(g, "lynchOutcome"),
    }
    
    handler = transitions.get(phase_name)
    if handler:
        try:
            await retry_on_db_lock_async(handler, game)
        except Exception:
            return
    else:
        return
