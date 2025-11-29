from collections import Counter
from .models import Poll, Vote, Game, Player


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

    return check_everybody_voted(game_id, poll_id) 


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

def check_everybody_voted(game_id, poll_id):
    poll = Poll.objects.get(id = poll_id)
    votes = Vote.objects.filter(game_id = game_id, poll_id = poll_id)
    num_players = 0
    if poll.role == "all":
        num_players = Player.objects.filter(game_id = game_id, is_dead = False)
    else:
        targeted_players = Player.objects.filter(game_id = game_id, role__name = poll.role, is_dead = False)
        num_players = len(list(targeted_players))

    # Signal that the poll is completed if everybody voted
    if len(votes) >= num_players:
        return True
    else:
        return False

def clear_poll(game_id, poll_id):
    Vote.objects.filter(game_id = game_id, poll_id = poll_id).delete()
    #TODO: also delete poll?