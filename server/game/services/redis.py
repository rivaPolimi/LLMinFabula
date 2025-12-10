import redis.asyncio as redis
import os

REDIS_URL = os.environ.get("REDIS_URL")

#redis_client = redis.Redis.from_url(REDIS_URL, decode_responses=True)
redis_client = None