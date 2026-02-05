import logging
import asyncio
import threading
from collections import Counter
from ..models import Poll, Vote, Player, Game, States
from channels.db import database_sync_to_async
from .timer_manager import schedule_timer
from ..db_utils import retry_on_db_lock_async

logger = logging.getLogger("redis_events")

POLL_EXTRA_TIME = 10

# Global reference to the background event loop
_event_loop: asyncio.AbstractEventLoop | None = None
_loop_lock = threading.Lock()


def _get_or_create_event_loop() -> asyncio.AbstractEventLoop:
    """Get the running event loop or create a background one."""
    global _event_loop
    
    try:
        # Try to get the currently running loop
        return asyncio.get_running_loop()
    except RuntimeError:
        # No running loop, use/create background loop
        with _loop_lock:
            if _event_loop is None or _event_loop.is_closed():
                _event_loop = asyncio.new_event_loop()
                
                # Start running the loop in a background thread
                def run_loop():
                    asyncio.set_event_loop(_event_loop)
                    _event_loop.run_forever()
                
                thread = threading.Thread(target=run_loop, daemon=True, name="asyncio-event-loop-poll")
                thread.start()
                logger.info("Started background asyncio event loop thread for polls")
            
            return _event_loop


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
        loop = _get_or_create_event_loop()
        asyncio.run_coroutine_threadsafe(schedule(), loop)
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
    Handle poll expiration and transition with retry logic for database locks.
    """
    try:
        # Retry fetching poll if database is locked
        def get_poll():
            return Poll.objects.select_related("game").get(id=poll_id, game_id=game_id)
        
        poll = await retry_on_db_lock_async(get_poll)
        game = poll.game
    except Poll.DoesNotExist:
        logger.error("Poll not found: poll_id=%s game_id=%s", poll_id, game_id)
        return
    except Exception as e:
        logger.exception("Error fetching poll: %s", e)
        return
    
    if poll.expired:
        logger.info("Poll already expired: game_id=%s poll_id=%s", game_id, poll_id)
        return
    
    from ..engine import GameEngine
    
    # Check if we need extra voting time
    everyone_voted = await retry_on_db_lock_async(check_everybody_voted, game, poll)
    if game.state == "discussion" and not everyone_voted:
        logger.info("Poll extra time: game_id=%s poll_id=%s", game_id, poll_id, extra={'game_id': game_id, 'poll_id': poll_id})
        await retry_on_db_lock_async(GameEngine.start_extra_vote, game, poll)
        return
    
    # Mark as expired and handle (with retry)
    def mark_expired_and_transition():
        poll.expired = True
        poll.save()
        
        if poll.role == "all":
            logger.info("Ending discussion poll: game_id=%s poll_id=%s", game_id, poll_id, extra={'game_id': game_id, 'poll_id': poll_id})
            GameEngine.end_discussion(game, poll)
        else:
            logger.info("Ending role poll: game_id=%s poll_id=%s role=%s", game_id, poll_id, poll.role, extra={'game_id': game_id, 'poll_id': poll_id})
            player = poll.get_voter()
            GameEngine.role_action(game, player, None, poll)
    
    try:
        await retry_on_db_lock_async(mark_expired_and_transition)
    except Exception as e:
        logger.exception("Error ending poll: %s", e)


async def record_vote(poll: Poll, voter_id: int, target_id: int):
    """
    Save vote in the database
    """

    voter = await database_sync_to_async(Player.objects.get)(id=voter_id)
    target = await database_sync_to_async(Player.objects.get)(id=target_id)

    await database_sync_to_async(Vote.objects.update_or_create)(
        poll = poll,
        voter = voter,
        target = target,
    )

    return await database_sync_to_async(check_everybody_voted)(poll.game, poll)


def tally_votes(poll: Poll):
    """
    Count votes for this poll
    """

    votes = Vote.objects.select_related("voter", "target", "poll").filter(poll=poll)
    tally = Counter(v.target for v in votes)
    if not tally:
        return None
    
    return tally

async def tally_votes_async(poll: Poll):
    """
    Async version: Count votes for this poll
    """
    return await database_sync_to_async(tally_votes)(poll)

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
        targeted_players = Player.objects.select_related("role").filter(game = game, role__name = poll.role, is_dead = False)
        num_players = len(list(targeted_players))

    # Signal that the poll is completed if everybody voted
    if len(votes) >= num_players:
        return True
    else:
        return False
    
async def end_poll_by_id(poll_id: int, player: Player = None):
    from ..engine import GameEngine
    from .timer_manager import cancel_timer
    
    try:
        poll = await database_sync_to_async(Poll.objects.select_related("game").get)(id=poll_id)
    except Poll.DoesNotExist:
        logger.info("Poll expiry ignored: poll_id=%s not found", poll_id)
        return
    
    everyone_voted = await database_sync_to_async(check_everybody_voted)(poll.game, poll)
    if poll.game.state == States.DISCUSSION and not everyone_voted:
        logger.info("Poll extra time: game_id=%s poll_id=%s", poll.game_id, poll.id)
        return GameEngine.start_extra_vote(poll.game, poll)
    
    # If poll already finished do not count the vote
    if poll.expired:
        logger.info("Poll already expired: game_id=%s poll_id=%s", poll.game_id, poll.id)
        return

    # Cancel the poll timer since everyone has voted
    poll_key = f"poll:{poll.id}_{poll.game_id}"
    timer_cancelled = cancel_timer(poll_key)
    if timer_cancelled:
        logger.info("Poll timer cancelled (everyone voted): game_id=%s poll_id=%s", poll.game_id, poll.id, extra={'game_id': poll.game_id, 'poll_id': poll.id})
        # Callback will execute end_poll immediately
        return

    # Fallback: if no timer existed, end now
    logger.info("Poll timer not found; ending directly: game_id=%s poll_id=%s", poll.game_id, poll.id)
    return await end_poll(poll.id, poll.game_id)

def clear_poll(poll: Poll):
    Vote.objects.select_related("poll").filter(poll=poll).delete()
    #TODO: also delete poll?