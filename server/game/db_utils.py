"""
Database utility functions for handling SQLite locking issues.
"""
import logging
import time
from functools import wraps
from django.db import transaction
from django.db.utils import OperationalError

logger = logging.getLogger("redis_events")

# Maximum retries for database operations
MAX_RETRIES = 5
RETRY_DELAY = 0.1  # Start with 100ms


def retry_on_db_lock(max_retries=MAX_RETRIES):
    """
    Decorator to retry database operations on SQLite lock errors.
    Uses exponential backoff to avoid hammering the database.
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            delay = RETRY_DELAY
            
            for attempt in range(max_retries):
                try:
                    with transaction.atomic():
                        return func(*args, **kwargs)
                except OperationalError as e:
                    if "database is locked" in str(e):
                        last_exception = e
                        if attempt < max_retries - 1:
                            logger.warning(
                                "Database locked, retrying in %.2fs (attempt %d/%d)",
                                delay, attempt + 1, max_retries
                            )
                            time.sleep(delay)
                            delay = min(delay * 2, 1.0)  # Cap at 1 second
                        continue
                    else:
                        raise
            
            # If we got here, we've exhausted retries
            logger.error("Database locked after %d retries", max_retries)
            raise last_exception
        
        return wrapper
    return decorator


async def retry_on_db_lock_async(func, *args, max_retries=MAX_RETRIES, **kwargs):
    """
    Async version of retry_on_db_lock.
    Use this for async functions that call sync database operations.
    """
    from asgiref.sync import sync_to_async
    import asyncio
    
    last_exception = None
    delay = RETRY_DELAY
    
    for attempt in range(max_retries):
        try:
            # Run sync function in thread pool with transaction
            def wrapped():
                with transaction.atomic():
                    return func(*args, **kwargs)
            
            # Use a non-thread-sensitive executor to avoid single-thread deadlocks
            return await sync_to_async(wrapped, thread_sensitive=False)()
        except OperationalError as e:
            if "database is locked" in str(e):
                last_exception = e
                if attempt < max_retries - 1:
                    logger.warning(
                        "Database locked, retrying in %.2fs (attempt %d/%d)",
                        delay, attempt + 1, max_retries
                    )
                    await asyncio.sleep(delay)
                    delay = min(delay * 2, 1.0)
                continue
            else:
                raise
    
    logger.error("Database locked after %d retries", max_retries)
    raise last_exception
