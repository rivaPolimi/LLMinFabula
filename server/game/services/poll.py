import logging
from collections import Counter
from .redis import redis_client
from ..models import Poll, Vote, Player, Game, States
from channels.db import database_sync_to_async
import time

logger = logging.getLogger("redis_events")

POLL_EXTRA_TIME = 10

def create_poll(game, duration=30, role="all"):
    """
    Create a poll for players to vote
    """

    poll = Poll.objects.create(
        game = game,
        duration = duration,
        role = role
    )
    poll.save()

    return poll

def start_poll_timer(poll: Poll):
    """
    Start the asynchronous timer for the poll to expire
    """

    # Add some tolerance time to receive votes
    duration = poll.duration + POLL_EXTRA_TIME

    key = f"poll:{poll.id}"
    logger.info("Starting poll timer: game_id=%s poll_id=%s duration=%ss", poll.game_id, poll.id, duration)

    # Set expiration in Redis
    expiry_time = int(time.time()) + duration
    redis_client.expireat(key, expiry_time)

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