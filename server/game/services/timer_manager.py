"""
In-memory timer manager using asyncio.
Replaces Redis keyspace notifications with a simple background task.
"""
import asyncio
import logging
from typing import Callable, Coroutine

logger = logging.getLogger("redis_events")

# Global registry of pending timers
_timers: dict[str, asyncio.Task] = {}
_timers_lock: asyncio.Lock | None = None


async def _get_lock():
    """Get or create the timers lock."""
    global _timers_lock
    if _timers_lock is None:
        _timers_lock = asyncio.Lock()
    return _timers_lock


async def schedule_timer(
    key: str,
    delay_seconds: int,
    callback: Callable[[str], Coroutine],
) -> None:
    """
    Schedule a callback to run after delay_seconds.
    
    Args:
        key: Unique identifier for the timer (e.g., "phase:nightIntro_1")
        delay_seconds: How long to wait before firing
        callback: Async function to call with (key) as argument
    """
    lock = await _get_lock()
    async with lock:
        # Cancel any existing timer with this key
        if key in _timers:
            _timers[key].cancel()
            logger.info("Cancelled existing timer: %s", key)
    
    async def timer_task():
        try:
            await asyncio.sleep(delay_seconds)
            logger.info("Timer fired: %s (after %ss)", key, delay_seconds)
            await callback(key)
        except asyncio.CancelledError:
            logger.info("Timer cancelled: %s", key)
        finally:
            lock = await _get_lock()
            async with lock:
                _timers.pop(key, None)
    
    task = asyncio.create_task(timer_task())
    async with lock:
        _timers[key] = task
    
    logger.info("Scheduled timer: %s expires in %ss", key, delay_seconds)


def cancel_timer(key: str) -> None:
    """Cancel a timer by key."""
    import asyncio
    
    def _cancel():
        async def async_cancel():
            async with _timers_lock:
                if key in _timers:
                    _timers[key].cancel()
                    logger.info("Cancelled timer: %s", key)
        
        try:
            asyncio.run_coroutine_threadsafe(_cancel(), asyncio.get_event_loop())
        except Exception as e:
            logger.error("Error cancelling timer %s: %s", key, e)
    
    _cancel()


def get_active_timers():
    """Return all active timers with their remaining time."""
    # This is for monitoring/debugging
    return {key: "active" for key in _timers.keys()}


async def cleanup_timers():
    """Cleanup all timers (called on shutdown)."""
    async with _timers_lock:
        for task in _timers.values():
            task.cancel()
        _timers.clear()
    logger.info("Cleaned up all timers")
