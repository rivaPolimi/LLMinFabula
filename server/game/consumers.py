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

    async def receive_json(self, content):
        msg_type = content.get("type")

        if msg_type == "vote":
            await self.handle_vote(content)
        
        elif msg_type == "narration_finished":
            await self.handle_phase_ack(content)

    async def new_player_joined(self, event):
        if(event["player_id"] != self.player_id):
            await self.send_json({
                "type": "player_joined",
                "player_id": event["player_id"],
                "nickname": event["nickname"],
                "is_dead": event["is_dead"],
            })

    async def reload_db_state(self):
        self.player = await database_sync_to_async(Player.objects.select_related("role", "game").get)(id=self.player_id)
        self.game = await database_sync_to_async(Game.objects.select_related("setting").get)(id=self.game_id)

    async def game_started(self, event):
        await self.reload_db_state()
        # Join role based channel
        self.group_role = f"game_{self.game_id}_{self.player.role.name}"
        await self.channel_layer.group_add(self.group_role, self.channel_name)

        setting = self.game.setting

        # Send role to players
        await self.send_json({
            "type": "role_reveal",
            "original_name": self.player.role.name,
            "name": setting.alternative_role_names[self.player.role.name],
            "description": setting.alternative_role_descriptions[self.player.role.name],
            "game_id": event["game_id"],
        })

    async def wolves_list(self, event):
        await self.send_json({
            "type": "wolves_list",
            "wolves": event["wolves"],
        })

    async def tell_story(self, event):
        await self.send_json({
            "type": "narrator",
            "phase": event["phase"],
            "text": event["text"],
        })

    async def handle_vote(self, content):
        try:
            poll = await database_sync_to_async(Poll.objects.select_related("game").get)(
                id=content.get("poll_id")
            )

            await self.reload_db_state()

            if not self.player.role.name == poll.role and poll.role != "all":
                await self.send_json({
                    "type": "Vote error",
                    "text": "Not allowed",
                })

            # If poll expired ignore the vote
            if poll.expired:
                await self.send_json({
                    "type": "Vote error",
                    "text": "Poll expired",
                })
                return

            poll_finished = await record_vote(poll, self.player_id, content.get("target"))
            
            # Send updated tally to clients anyway, even if the poll is finished, to update the UI in real time
            tally = await tally_votes_async(poll)
            await notify_updated_votes(self.game_id, poll, tally)

            if poll_finished:
                await end_poll_by_id(poll.id, player=self.player)

        except Poll.DoesNotExist:
            await self.send_json({
                "type": "Vote error",
                "text": "Poll not found, vote not registered",
            })

#    async def handle_narration_finished(self, content):
#        from engine import GameEngine
#        await self.reload_db_state()
#
#        phase = content["phase"]
#        state = self.game.state
#        
#        if phase == States.INTRODUCTION and state == States.INTRODUCTION:
#            GameEngine.role_reveal(self.game)
#        elif phase == States.ROLE_REVEAL and state == States.ROLE_REVEAL:
#            GameEngine.night_intro(self.game)
#        elif phase == States.NIGHT and state == States.NIGHT:
#            GameEngine.handle_night(self.game)
#        elif phase == States.NIGHT_REPORT and state == States.NIGHT_REPORT:
#            GameEngine.check_win_engine(self.game)

    async def player_arrested(self, event):
        await self.send_json({
            "type": "arrested_notification",
            "message": event["message"],
        })

    async def player_eliminated(self, event):
        # Remove player from the role channel
        if self.group_role and self.group_role != "none":
            await self.channel_layer.group_discard(self.group_role, self.channel_name)
        self.group_role = "none"
        
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
            "started_at": event["started_at"],
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

    async def role_turn(self, event):
        await self.send_json({
            "type": "role_turn",
            "role": event["role"],
        })

    async def night_victims(self, event):
        await self.send_json({
            "type": "night_victims",
            "victims_id": event["victims_id"],
        })

    async def lynch_result(self, event):
        await self.send_json({
            "type": "lynch_result",
            "target_id": event["target_id"],
            "target_name": event["target_name"],
        })

    async def handle_phase_ack(self, content):
        """
        Handle phase acknowledgment from client.
        Cancel the server-side timer when client acknowledges it received the phase start.
        """
        from .services.timer_manager import cancel_timer
        
        phase_name = content.get("phase")
        
        if not phase_name:
            await self.send_json({
                "type": "ack_error",
                "error": "phase parameter required"
            })
            return
        
        # Build the timer key
        key = f"phase:{phase_name}_{self.game_id}"
        
        # Cancel the timer
        cancelled = cancel_timer(key)
        
        if cancelled:
            await self.send_json({
                "type": "ack_success",
                "message": f"Timer cancelled for phase: {phase_name}"
            })
        else:
            await self.send_json({
                "type": "ack_warning",
                "message": f"Timer not found for phase: {phase_name}"
            })