"""
Custom logging handler to store redis_events logs in the database.
"""
import logging
import re


class DatabaseLogHandler(logging.Handler):
    """Custom handler that writes log records to RedisEventLog model."""
    
    def emit(self, record):
        try:
            # Import here to avoid circular dependency
            from .models import RedisEventLog
            
            # Extract context from the log message
            game_id = self._extract_field(record.getMessage(), 'game_id')
            poll_id = self._extract_field(record.getMessage(), 'poll_id')
            phase = self._extract_field(record.getMessage(), 'phase')
            
            # Create log entry
            RedisEventLog.objects.create(
                level=record.levelname,
                logger_name=record.name,
                message=record.getMessage(),
                game_id=game_id,
                poll_id=poll_id,
                phase=phase,
            )
        except Exception:
            # Don't let logging errors break the app
            self.handleError(record)
    
    def _extract_field(self, message, field_name):
        """Extract field value from structured log message."""
        pattern = rf'{field_name}=(\d+)'
        match = re.search(pattern, message)
        if match:
            return int(match.group(1))
        
        # Try string values for phase
        if field_name == 'phase':
            pattern = r'phase=(\w+)'
            match = re.search(pattern, message)
            if match:
                return match.group(1)
        
        return None
