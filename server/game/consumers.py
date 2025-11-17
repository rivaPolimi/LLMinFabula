import json
# import aioredis
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser # TODO: need for authentication?
from django.shortcuts import get_object_or_404
from .models import Player, Game
from collections import Counter
from django.conf import settings
from channels.db import database_sync_to_async

class GameConsumer(AsyncJsonWebsocketConsumer):
    
    async def connect(self):
        self.game_id = self.scope["url_route"]["kwargs"]["game_id"]
        self.player_id = self.scope["url_route"]["kwargs"]["player_id"]

        # Check if player exists and is in game
        try:
            self.player = await database_sync_to_async(Player.objects.get)(
                id=self.player_id, game_id=self.game_id
            )
        except Player.DoesNotExist:
            await self.close()
            return
        
        # Group name
        self.group_all = f"game_{self.game_id}_all"
        self.group_role = "none" #role not assigned yet

        await self.channel_layer.group_add(self.group_all, self.channel_name)

        #TODO: create a per-connection redis client (needed?)

        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.group_all, self.channel_name)

        # If role assigned leave the role group
        if not self.group_role == "none":
            await self.channel_layer.group_discard(self.group_role, self.channel_name)

        #TODO: close redis if used

        # Close connection
        self.close()

    # Receive JSON from the client
    async def receive_json(self, content):
        msg_type = content.get("type")

    async def game_started(self, event):
        # Join role based channel
        self.group_role = f"game_{self.game_id}_{self.player.role}"
        await self.channel_layer.group_add(self.group_role, self.channel_name)

        # Send acknowledgement to players (TODO: needed? can't i just send everything with the story?)
        self.send_json({
            "type": "start_ack",
            "message": event["message"],
            "game_id": event["game_id"]
        })

    async def tell_story(self, event):
        self.send_json({
            "type": event["phase"],
            "text": event["text"],
        })
        
        

