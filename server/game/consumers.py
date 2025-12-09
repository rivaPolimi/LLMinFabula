import json
# import aioredis
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser # TODO: need for authentication?
from django.shortcuts import get_object_or_404
from .models import Player, Game
from .services.poll import *
from .notifications import notify_updated_votes
from .engine import GameEngine
from django.conf import settings
from channels.db import database_sync_to_async

class GameConsumer(AsyncJsonWebsocketConsumer):
    
    async def connect(self):
        self.game_id = self.scope["url_route"]["kwargs"]["game_id"]
        self.player_id = self.scope["url_route"]["kwargs"]["player_id"]

        # Check if game exists
        try:
            self.game = await database_sync_to_async(Game.objects.get)(
                id=self.game_id
            )
        except Game.DoesNotExist:
            await self.close()
            return

        # Check if player exists and is in game
        try:
            self.player = await database_sync_to_async(Player.objects.get)(
                id=self.player_id, game=self.game
            )
        except Player.DoesNotExist:
            await self.close()
            return
        
        # Groups name
        self.group_all = f"game_{self.game_id}_all"
        self.group_self = f"game_{self.game_id}_{self.player_id}" # Group used for personal notifications
        self.group_role = "none" #role not assigned yet

        await self.channel_layer.group_add(self.group_all, self.channel_name)
        await self.channel_layer.group_add(self.group_self, self.channel_name)

        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.group_all, self.channel_name)

        # If role assigned leave the role group
        if not self.group_role == "none":
            await self.channel_layer.group_discard(self.group_role, self.channel_name)

        # Close connection
        self.close()

    # Receive JSON from the client
    async def receive_json(self, content):
        msg_type = content.get("type")

        if msg_type == "vote":
            self.handle_vote(self, content)

    async def game_started(self, event):
        # Join role based channel
        self.group_role = f"game_{self.game_id}_{self.player.role.name}"
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

    async def handle_vote(self, content):
        try:
            poll = await database_sync_to_async(Poll.objects.get)(
                id=content.get("poll_id")
            )
        except Poll.DoesNotExist:
            self.send_json({
                "type": "Vote error",
                "text": "Poll not found, vote not registered",
            })

        if not self.player.role.name == poll.role:
            self.send_json({
                "type": "Vote error",
                "text": "Not allowed",
            })
        
        poll_finished = record_vote(poll, self.player_id, content.get("target"))

        if poll_finished:
            end_poll_by_id(poll.id, player=self.player)
        else:
            tally = tally_votes(poll)
            notify_updated_votes(self.game, poll, tally)

    async def player_arrested(self, event):
        self.send_json({
            "type": "arrested_notification",
            "message": event["message"],
        })

    async def player_eliminated(self, event):
        # Remove player from the role channel
        await self.channel_layer.group_discard(self.group_role, self.channel_name)
        self.group_role = ""
        
        self.send_json({
            "type": "death",
            "message": event["message"],
        })

    async def game_ended(self, event):
        self.send_json({
            "type": "game_ended",
            "outcome": event["outcome"],
        })

    async def action_outcome(self, event):
        self.send_json({
            "type": "action_outcome",
            "target_id": event["target_id"],
            "target_name": event["target_name"],
            "outcome": event["outcome"],
        })
        
    async def poll_begin(self, event):
        self.send_json({
            "type": "poll_begin",
            "poll_id": event["poll_id"],
            "duration": event["duration"],
        })

    async def start_extra_time(self, event):
        self.send_json({
            "type": "start_extra_time",
            "duration": event["duration"],
        })

    async def send_tally(self, event):
        self.send_json({
            "type": "tally",
            "poll_id": event["poll_id"],
            "tally": event["tally"],
        })

