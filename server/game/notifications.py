from collections import Counter
from .models import Game, Player, Poll
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

#TODO: cercare nel codice i vari messaggi mandati e trasformarli in notifiche

def notify_narrator_story(game_id: int, role: str, phase: str, text: str):
    channel_layer = get_channel_layer()
    
    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_{role}",
        {
            "type": "tell.story",
            "phase": phase,
            "text": text,
        }
    )

def notify_action_outcome(game_id: int, target: Player, role: str, outcome: str):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_{role}",
        {"type": "action.outcome", "target_id": target.id, "target_name": target.nickname, "outcome": outcome}
    )

def notify_lynch_outcome(game_id: int, target: Player):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_all",
        {"type": "lynch.result", "target_id": target.id, "target_name": target.nickname}
    )

def notify_poll_begin(game: Game, poll: Poll):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game.id}_{poll.role.name}",
        {"type": "poll.begin", "poll_id": poll.id, "duration": poll.duration}
    )

async def notify_updated_votes(game_id: int, poll: Poll, tally: Counter):
    # Acknowledge all the players in the poll of the vote. TODO: On client check the answers timestamp to avoid showing older votes
    channel_layer = get_channel_layer()

    channel_layer.group_send(
        f"game_{game_id}_{poll.role.name}",
        {"type": "send.tally", "poll_id": poll.id, "tally": tally}
    )

def notify_start_extra_time(game: Game, duration: int):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game.id}_all",
        {"type": "start.extra.time", "duration": duration}
    )

def notify_player_eliminated(game_id: int, player_id: int):
        channel_layer = get_channel_layer()

        async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_{player_id}",
        {"type": "player.eliminated", "message": "You've been killed",},
    )
        
def notify_player_in_jail(game_id: int, player_id: int):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_{player_id}",
        {"type": "player.arrested", "message": "Jailer arrested you", "game_id": game_id}
    )
        
def notify_game_started(game_id: int):
    channel_layer = get_channel_layer()

    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_all",
        {"type": "game.started", "message": "Game started", "game_id": game_id}
    )
        
def notify_game_end(game_id: int, player_id: int, outcome: str):
    channel_layer = get_channel_layer()
    
    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_{player_id}",
        {"type": "game.ended", "outcome": outcome,},
    )

async def notify_new_player_joined(game_id: int, player: Player):
    channel_layer = get_channel_layer()

    await channel_layer.group_send(
        f"game_{game_id}_all",
        {"type": "new.player.joined", "player_id": player.id, "nickname": player.nickname, "is_dead": player.is_dead,},
    )