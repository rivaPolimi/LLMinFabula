import redis.asyncio as redis
import os
from game.services.poll import end_poll_by_id

REDIS_URL = os.environ.get("REDIS_URL")

async def start_poll_listener():
    redis_client = await redis.Redis.from_url(REDIS_URL, decode_responses=True)

    # Enable expiration notifications
    await redis_client.config_set("notify-keyspace-events", "Ex")

    pubsub = redis_client.pubsub()
    await pubsub.subscribe("__keyevent@0__:expired")

    async for msg in pubsub.listen():
        if msg["type"] != "message":
            continue

        key = msg["data"]

        if key.startswith("poll:"):
            poll_id = int(key.split(":")[1])
            end_poll_by_id(poll_id)
            try:
                pass
            except Exception as e:
                print("Error finishing poll: ", e)  