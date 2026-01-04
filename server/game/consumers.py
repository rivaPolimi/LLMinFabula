from channels.generic.websocket import AsyncJsonWebsocketConsumer
from .models import Player, Game
from .services.poll import *
from .fsm import States
from .notifications import notify_updated_votes, notify_new_player_joined
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

        await notify_new_player_joined(self.game_id, self.player)

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
            await self.handle_vote(self, content)

        elif msg_type == "narration_finished":
            await self.handle_narration_finished(content)

    async def new_player_joined(self, event):
        if(event["player_id"] != self.player_id):
            await self.send_json({
                "type": "player_joined",
                "player_id": event["player_id"],
                "nickname": event["nickname"],
                "is_dead": event["is_dead"],
            })

    async def game_started(self, event):
        # Join role based channel
        self.group_role = f"game_{self.game_id}_{self.player.role.name}"
        await self.channel_layer.group_add(self.group_role, self.channel_name)

        setting = self.game.setting

        # Send role to players
        await self.send_json({
            "type": "role_reveal",
            "original_name": self.player.role.name,
            "name": setting.alternative_role_names[self.player.role.name],
            "description": '', #setting.alternative_role_descriptions[self.player.role.name], TODO: da sbloccare
            "game_id": event["game_id"],
        })

    async def tell_story(self, event):
        await self.send_json({
            "type": "narrator",
            "phase": event["phase"],
            "text": event["text"],
        })

    async def handle_vote(self, content):
        try:
            poll = await database_sync_to_async(Poll.objects.get)(
                id=content.get("poll_id")
            )
        except Poll.DoesNotExist:
            await self.send_json({
                "type": "Vote error",
                "text": "Poll not found, vote not registered",
            })

        if not self.player.role.name == poll.role:
            await self.send_json({
                "type": "Vote error",
                "text": "Not allowed",
            })
        
        poll_finished = record_vote(poll, self.player_id, content.get("target"))

        if poll_finished:
            end_poll_by_id(poll.id, player=self.player)
        else:
            tally = tally_votes(poll)
            await notify_updated_votes(self.game, poll, tally)

    async def handle_narration_finished(self, content):
        from engine import GameEngine
        phase = content["phase"]
        state = self.game.state
        
        if phase == States.INTRODUCTION and state == States.INTRODUCTION:
            GameEngine.role_reveal(self.game)
        elif phase == States.ROLE_REVEAL and state == States.ROLE_REVEAL:
            GameEngine.night_intro(self.game)
        elif phase == "night_intro" and state == States.NIGHT:
            GameEngine.handle_night(self.game)
        elif phase == States.NIGHT_REPORT and state == States.NIGHT_REPORT:
            GameEngine.check_win_engine(self.game)

    async def player_arrested(self, event):
        await self.send_json({
            "type": "arrested_notification",
            "message": event["message"],
        })

    async def player_eliminated(self, event):
        # Remove player from the role channel
        await self.channel_layer.group_discard(self.group_role, self.channel_name)
        self.group_role = ""
        
        await self.send_json({
            "type": "death",
            "message": event["message"],
        })

    async def game_ended(self, event):
        await self.send_json({
            "type": "game_ended",
            "outcome": event["outcome"],
        })

    async def action_outcome(self, event):
        await self.send_json({
            "type": "action_outcome",
            "target_id": event["target_id"],
            "target_name": event["target_name"],
            "outcome": event["outcome"],
        })
        
    async def poll_begin(self, event):
        await self.send_json({
            "type": "poll_begin",
            "poll_id": event["poll_id"],
            "duration": event["duration"],
        })

    async def start_extra_time(self, event):
        await self.send_json({
            "type": "start_extra_time",
            "duration": event["duration"],
        })

    async def send_tally(self, event):
        await self.send_json({
            "type": "tally",
            "poll_id": event["poll_id"],
            "tally": event["tally"],
        })

    async def phase_start(self, event):
        await self.send_json({
            "type": "game_phase",
            "phase": event["phase"],
            "started_at": event["started_at"],
            "duration": event["duration"],
        })

