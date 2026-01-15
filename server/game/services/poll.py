import logging
import asyncio
from collections import Counter
from ..models import Poll, Vote, Player, Game, States
from channels.db import database_sync_to_async
from .timer_manager import schedule_timer

logger = logging.getLogger("redis_events")

POLL_EXTRA_TIME = 10


def create_poll(game, duration=30, role="all"):
    """
    Create a poll for players to vote
    """
    poll = Poll.objects.create(
        game=game,
        duration=duration,
        role=role
    )
    poll.save()
    return poll


def start_poll_timer(poll: Poll):
    """
    Schedule a poll timer using asyncio.
    Safe to call from sync or async contexts (including thread pools).
    """
    # Add some tolerance time to receive votes
    duration = poll.duration + POLL_EXTRA_TIME
    key = f"poll:{poll.id}_{poll.game_id}"
    
    async def schedule():
        await schedule_timer(key, duration, _on_poll_expire)
    
    try:
        # Try to get the running event loop
        try:
            loop = asyncio.get_running_loop()
            asyncio.create_task(schedule())
        except RuntimeError:
            # No running loop in current thread, try to get the main loop
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.create_task(schedule())
    except Exception as e:
        logger.error("Error scheduling poll timer: %s", e)
        return
    
    logger.info("Starting poll timer: game_id=%s poll_id=%s duration=%ss", poll.game_id, poll.id, duration, extra={'game_id': poll.game_id, 'poll_id': poll.id})


async def _on_poll_expire(key: str):
    """
    Called when a poll timer expires.
    """
    try:
        # Parse key: poll:pollId_gameId
        parts = key.replace('poll:', '').rsplit('_', 1)
        if len(parts) != 2:
            logger.error("Invalid poll key format: %s", key)
            return
        
        poll_id_str, game_id_str = parts
        poll_id = int(poll_id_str)
        game_id = int(game_id_str)
        
        logger.info("Poll timer expired: game_id=%s poll_id=%s", game_id, poll_id, extra={'game_id': game_id, 'poll_id': poll_id})
        
        await end_poll(poll_id, game_id)
    except Exception as e:
        logger.exception("Error handling poll expiry for key %s: %s", key, e)


async def end_poll(poll_id: int, game_id: int):
    """
    Handle poll expiration and transition.
    """
    try:
        poll = await database_sync_to_async(Poll.objects.get)(id=poll_id, game_id=game_id)
        game = poll.game
    except Poll.DoesNotExist:
        logger.error("Poll not found: poll_id=%s game_id=%s", poll_id, game_id)
        return
    
    if poll.expired:
        logger.info("Poll already expired: game_id=%s poll_id=%s", game_id, poll_id)
        return
    
    from ..engine import GameEngine
    
    # Check if we need extra voting time
    everyone_voted = await database_sync_to_async(check_everybody_voted)(game, poll)
    if game.state == "discussion" and not everyone_voted:
        logger.info("Poll extra time: game_id=%s poll_id=%s", game_id, poll_id, extra={'game_id': game_id, 'poll_id': poll_id})
        await database_sync_to_async(GameEngine.start_extra_vote)(game, poll)
        return
    
    # Mark as expired and handle
    poll.expired = True
    await database_sync_to_async(poll.save)()
    
    if poll.role == "all":
        logger.info("Ending discussion poll: game_id=%s poll_id=%s", game_id, poll_id, extra={'game_id': game_id, 'poll_id': poll_id})
        await database_sync_to_async(GameEngine.end_discussion)(game, poll)
    else:
        logger.info("Ending role poll: game_id=%s poll_id=%s role=%s", game_id, poll_id, poll.role, extra={'game_id': game_id, 'poll_id': poll_id})
        player = await database_sync_to_async(poll.get_voter)()
        await database_sync_to_async(GameEngine.role_action)(game, player, None, poll)


def record_vote(poll: Poll, voter_id: int, target_id: int):
    """
    Save vote in the database
    """

    voter = Player.objects.get(id=voter_id)
    target = Player.objects.get(id=target_id)

    Vote.objects.update_or_create(
        poll = poll,
        voter = voter,
        target = target,
    )

    return check_everybody_voted(poll.game, poll)


def tally_votes(poll: Poll):
    """
    Count votes for this poll
    """

    votes = Vote.objects.select_related("voter", "target", "poll").filter(poll=poll)
    tally = Counter(v.target for v in votes)
    if not tally:
        return None
    
    return tally

def get_result(poll: Poll):
    """
    Return the result of the poll
    """
    tally = tally_votes(poll)
    if not tally:
        return None
    
    # Get the highest number of votes
    max_votes = max(tally.values())

    # Find the player(s) with the highest number of votes
    top_players = [player for player, count in tally.items() if count == max_votes]

    # If more than one player got {max_votes} votes there is a tie, no decision is taken and return None
    if len(top_players) != 1:
        return None
    
    return top_players[0]

def check_everybody_voted(game: Game, poll: Poll):
    votes = Vote.objects.select_related("voter", "target", "poll").filter(poll=poll)
    num_players = 0
    if poll.role == "all":
        num_players = Player.objects.select_related("role").filter(game = game, is_dead = False).count()
    else:
        targeted_players = Player.objects.select_related("role").filter(game = game, role__name = poll.role.name, is_dead = False)
        num_players = len(list(targeted_players))

    # Signal that the poll is completed if everybody voted
    if len(votes) >= num_players:
        return True
    else:
        return False
    
async def end_poll_by_id(poll_id: int, player: Player = None):
    from ..engine import GameEngine
    
    try:
        poll = await database_sync_to_async(Poll.objects.select_related("game").get)(id=poll_id)
    except Poll.DoesNotExist:
        logger.info("Poll expiry ignored: poll_id=%s not found", poll_id)
        return
    
    if poll.game.state == States.DISCUSSION and not check_everybody_voted(poll.game, poll):
        logger.info("Poll extra time: game_id=%s poll_id=%s", poll.game_id, poll.id)
        return GameEngine.start_extra_vote(poll.game, poll)
    
    # If poll already finished do not count the vote
    if poll.expired:
        logger.info("Poll already expired: game_id=%s poll_id=%s", poll.game_id, poll.id)
        return

    # Get a random voter to perform the action
    if not player:
        player = poll.get_voter()

    # End the poll
    poll.expired = True

    if poll.role == "all":
        logger.info("Ending discussion poll: game_id=%s poll_id=%s", poll.game_id, poll.id)
        return GameEngine.end_discussion(poll.game, poll)
    else:
        logger.info("Ending role poll: game_id=%s poll_id=%s role=%s", poll.game_id, poll.id, poll.role)
        return GameEngine.role_action(poll.game, player, poll)

def clear_poll(poll: Poll):
    Vote.objects.select_related("poll").filter(poll=poll).delete()
    #TODO: also delete poll?