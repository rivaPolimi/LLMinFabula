"""
ASGI config for lupus_server project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/asgi/
"""

import os
import django
import logging
import asyncio
import threading

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lupus_server.settings')
django.setup()

import game.routing

django_asgi_app = get_asgi_application()

# Setup logging
logger = logging.getLogger('redis_events')

# Start timer listener in background
from .poll_listeners import start_poll_listener

# Store listener task
listener_task = None

def _start_poll_listener_thread():
    def runner():
        try:
            asyncio.run(start_poll_listener())
        except Exception as e:
            logger.exception("Poll listener crashed: %s", e)
    t = threading.Thread(target=runner, name="poll-listener", daemon=True)
    t.start()
    return t

class StartupMiddleware:
    """Start poll listener on first incoming ASGI call (HTTP/WS)."""
    started = False
    lock = threading.Lock()

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if not StartupMiddleware.started:
            with StartupMiddleware.lock:
                if not StartupMiddleware.started:
                    logger.info("[ASGI] Starting poll listener thread")
                    _start_poll_listener_thread()
                    StartupMiddleware.started = True
        await self.app(scope, receive, send)


router = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(game.routing.websocket_urlpatterns)
    ),
})

application = StartupMiddleware(router)