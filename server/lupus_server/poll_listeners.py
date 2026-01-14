import redis.asyncio as redis
import os
import logging
from game.services.poll import end_poll_by_id
from game.services.phase import end_phase
from django.conf import settings

REDIS_URL = getattr(settings, "REDIS_URL", "redis://localhost:6379/0")
logger = logging.getLogger("redis_events")

async def start_poll_listener():
    
    redis_client = await redis.Redis.from_url(REDIS_URL, decode_responses=True, socket_keepalive=True)

    # Enable expiration notifications (may be restricted on managed services)
    try:
        await redis_client.config_set("notify-keyspace-events", "Ex")
        logger.info("Enabled Redis notify-keyspace-events=Ex")
    except Exception as e:
        logger.warning("Could not set notify-keyspace-events=Ex: %s", e)

    pubsub = redis_client.pubsub()
    await pubsub.subscribe("__keyevent@0__:expired")
    logger.info("Subscribed to __keyevent@0__:expired")

    async for msg in pubsub.listen():
        if msg["type"] != "message":
            continue

        key = msg["data"]
        logger.info("Redis expired event received: key=%s", key)

        if key.startswith("poll:"):
            try:
                poll_id = int(key.split(":")[1])
                logger.info("Ending poll due to expiry: poll_id=%s", poll_id)
                await end_poll_by_id(poll_id)
            except Exception as e:
                logger.exception("Error finishing poll: %s", e)
        
        elif key.startswith("phase:"):
            try:
                subkey = key.split(":")[1]
                phase_key = subkey.split("_")[0]
                game_id = int(subkey.split("_"))[1]
                logger.info("Ending phase due to expiry: game_id=%s phase=%s", game_id, phase_key)
                await end_phase(phase_key, game_id)                
            except Exception as e:
                logger.exception("Error finishing phase: %s", e)