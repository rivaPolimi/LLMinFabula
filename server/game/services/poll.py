from collections import Counter
from .redis import redis_client
from ..models import Poll, Vote, Player, Game

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

async def start_poll_timer(poll: Poll):
    """
    Start the asynchronous timer for the poll to expire
    """

    # Add some tolerance time to receive votes
    duration = poll.duration + POLL_EXTRA_TIME

    key = f"poll:{poll.id}"
    await redis_client.set(key, "1", ex=duration)

def record_vote(poll, voter_id, target_id):
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


def tally_votes(poll):
    """
    Count votes for this poll
    """

    votes = Vote.objects.filter(poll=poll)
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
    votes = Vote.objects.filter(poll=poll)
    num_players = 0
    if poll.role == "all":
        num_players = Player.objects.filter(game = game, is_dead = False)
    else:
        targeted_players = Player.objects.filter(game = game, role__name = poll.role.name, is_dead = False)
        num_players = len(list(targeted_players))

    # Signal that the poll is completed if everybody voted
    if len(votes) >= num_players:
        return True
    else:
        return False
    
def end_poll_by_id(poll_id: int, player: Player = None):
    from ..engine import GameEngine
    
    try:
        poll = Poll.objects.get(id=poll_id)
    except Poll.DoesNotExist:
        return
    
    if poll.game.state == "discussion" and not check_everybody_voted(poll.game, poll):
        return GameEngine.start_extra_vote(poll.game, poll)
    
    # If poll already finished do not count the vote
    if poll.expired:
        return

    # Get a random voter to perform the action
    if not player:
        player = poll.get_voter()

    # End the poll
    poll.expired = True

    if poll.role == "all":
        return GameEngine.end_discussion(poll.game, poll)
    else:
        return GameEngine.role_action(poll.game, player, poll)

def clear_poll(poll):
    Vote.objects.filter(poll=poll).delete()
    #TODO: also delete poll?