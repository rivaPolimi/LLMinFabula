from collections import Counter
from .models import Poll, Vote


def create_poll(game_id, duration=30, role="all"):
    """
    Create a poll for players to vote
    """

    poll = Poll.objects.create(
        game_id = game_id,
        duration = duration,
        role = role
    )

    return poll

def record_vote(game_id, poll_id, voter_id, target_id):
    """
    Save vote in the database
    """

    Vote.objects.update_or_create(
        game_id = game_id,
        poll_id = poll_id,
        voter = voter_id,
        target = target_id
    )

def tally_votes(game_id, poll_id):
    """
    Count votes for this poll
    """

    votes = Vote.objects.filter(game_id=game_id, poll_id=poll_id)
    tally = Counter(v.target for v in votes)
    if not tally:
        return None
    
    return tally

def get_result(game_id, poll_id):
    """
    Return the result of the poll
    """
    tally = tally_votes(game_id, poll_id)

    winner = max(tally, key=tally.get) if tally else None
    return winner