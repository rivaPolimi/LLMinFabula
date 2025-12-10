"""
ASGI config for lupus_server project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/asgi/
"""

import os
import django

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lupus_server.settings')
django.setup()

import game.routing

django_asgi_app = get_asgi_application()

# Start timer listener in background
from .poll_listeners import start_poll_listener
import asyncio

class LifespanApp:
    """
    A minimal ASGI lifespan wrapper that starts background tasks on startup.
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "lifespan":
            # Startup
            await receive()
            asyncio.create_task(start_poll_listener())
            await send({"type": "lifespan.startup.complete"})

            # Shutdown
            await receive()
            await send({"type": "lifespan.shutdown.complete"})
        else:
            await self.app(scope, receive, send)


application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(game.routing.websocket_urlpatterns)
    ),
})

# Wrap application with lifespan handler
application = LifespanApp(application)