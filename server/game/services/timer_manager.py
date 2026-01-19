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
_callbacks: dict[str, Callable[[str], Coroutine]] = {}


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
        _callbacks[key] = callback
    
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
                _callbacks.pop(key, None)
    
    task = asyncio.create_task(timer_task())
    async with lock:
        _timers[key] = task
    
    logger.info("Scheduled timer: %s expires in %ss", key, delay_seconds)

def cancel_timer(key: str) -> bool:
    """
    Cancel a timer by key.
    Returns True if timer was cancelled, False if not found or error occurred.
    Uses the task's own event loop, so it works across threads.
    """
    try:
        task = _timers.get(key)
        callback = _callbacks.get(key)

        if not task:
            logger.warning("Timer not found for cancellation: %s", key)
            # Still try to fire callback if present
            if callback:
                loop = asyncio.get_event_loop()
                asyncio.run_coroutine_threadsafe(callback(key), loop)
                return True
            return False

        loop = task.get_loop()
        if loop.is_closed():
            logger.warning("Event loop is closed, cannot cancel timer: %s", key)
            return False

        async def async_cancel():
            lock = await _get_lock()
            async with lock:
                existing = _timers.pop(key, None)
                cb = _callbacks.pop(key, None)
                if existing:
                    existing.cancel()
                    logger.info("Cancelled timer: %s", key)
                    return cb
                logger.warning("Timer not found during cancellation: %s", key)
                return cb

        future = asyncio.run_coroutine_threadsafe(async_cancel(), loop)
        cb = future.result(timeout=5)
        if cb:
            asyncio.run_coroutine_threadsafe(cb(key), loop)
        return True
    except Exception as e:
        logger.error("Error cancelling timer %s: %s", key, e)
        return False


def get_active_timers():
    """Return all active timers with their remaining time."""
    # This is for monitoring/debugging
    return {key: "active" for key in _timers.keys()}


async def cleanup_timers():
    """Cleanup all timers (called on shutdown)."""
    lock = await _get_lock()
    async with lock:
        for task in _timers.values():
            task.cancel()
        _timers.clear()
        _callbacks.clear()
    logger.info("Cleaned up all timers")
