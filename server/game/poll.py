from collections import Counter
from .models import Poll, Vote, Player


def create_poll(game, duration=30, role="all"):
    """
    Create a poll for players to vote
    """

    poll = Poll.objects.create(
        game = game,
        duration = duration,
        role = role
    )

    return poll

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

def get_result(poll):
    """
    Return the result of the poll
    """
    tally = tally_votes(poll)

    winner = max(tally, key=tally.get) if tally else None
    return winner

def check_everybody_voted(game, poll):
    votes = Vote.objects.filter(poll=poll)
    num_players = 0
    if poll.role == "all":
        num_players = Player.objects.filter(game = game, is_dead = False)
    else:
        targeted_players = Player.objects.filter(game = game, role__name = poll.role, is_dead = False)
        num_players = len(list(targeted_players))

    # Signal that the poll is completed if everybody voted
    if len(votes) >= num_players:
        return True
    else:
        return False

def clear_poll(poll):
    Vote.objects.filter(poll=poll).delete()
    #TODO: also delete poll?