"""Async-safe logging handler to store redis_events logs in the database."""
import logging
import re
import threading
import queue
from django.db import close_old_connections


# Bounded queue to avoid blocking async contexts
_log_queue: queue.Queue = queue.Queue(maxsize=10000)


def _log_worker():
    """Worker thread that drains the queue and writes to DB."""
    while True:
        record = _log_queue.get()
        try:
            close_old_connections()
            # Import inside the worker to avoid circular imports on startup
            from .models import RedisEventLog

            # Extract context from the log message
            game_id = _extract_field(record.getMessage(), 'game_id')
            poll_id = _extract_field(record.getMessage(), 'poll_id')
            phase = _extract_field(record.getMessage(), 'phase')

            RedisEventLog.objects.create(
                level=record.levelname,
                logger_name=getattr(record, "name", ""),
                message=record.getMessage(),
                game_id=game_id,
                poll_id=poll_id,
                phase=phase,
            )
        except Exception:
            # Swallow exceptions to keep the worker alive
            pass
        finally:
            _log_queue.task_done()


def _start_worker_once():
    """Ensure the worker thread is started exactly once."""
    global _worker_started
    try:
        _worker_started
    except NameError:
        _worker_started = False

    if not _worker_started:
        t = threading.Thread(target=_log_worker, name="db-log-writer", daemon=True)
        t.start()
        _worker_started = True


class DatabaseLogHandler(logging.Handler):
    """Threaded DB log handler safe for async contexts."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        _start_worker_once()

    def emit(self, record):
        try:
            _log_queue.put_nowait(record)
        except queue.Full:
            # Drop the log if the queue is full to avoid blocking
            self.handleError(record)


def _extract_field(message: str, field_name: str):
    """Extract field value from structured log message."""
    pattern = rf'{field_name}=(\d+)'
    match = re.search(pattern, message)
    if match:
        return int(match.group(1))

    if field_name == 'phase':
        pattern = r'phase=(\w+)'
        match = re.search(pattern, message)
        if match:
            return match.group(1)

    return None
