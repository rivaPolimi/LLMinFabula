import redis.asyncio as redis
from django.conf import settings

# Single source of truth for Redis URL (supports redis/rediss from env)
REDIS_URL = getattr(settings, 'REDIS_URL', 'redis://localhost:6379/0')

redis_client = redis.from_url(REDIS_URL, decode_responses=True)