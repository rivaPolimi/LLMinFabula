
from django.db import transaction
from .models import Game, Player, Poll
from .poll import get_result
from .utils import resolve_night
from .notifications import *

class GameEngine:
    """
    Centralized service layer to manage game flow and FSM transitions. 
    """

    @staticmethod
    @transaction.atomic
    def start_game(game: Game):
        """
        Starts the game. 
        LOBBY -> NIGHT
        """

        # Transition LOBBY -> NIGHT
        game.fsm.begin_night()
        game.save()
        return GameEngine.handle_night(game)

    @staticmethod
    @transaction.atomic
    def handle_night(game: Game):
        """
        Chooses next role or starts day phase.
        NIGHT -> (ROLE_ACTION or DAY)
        """

        next_role = game.next_active_role()

        if not next_role:
            return GameEngine.finish_night(game)
        
        # Assign next role
        game.current_turn_role = next_role
        game.save()

        # Transition NIGHT -> ROLE_ACTION
        game.fsm.start_role_action()
        game.save()
        
        from .poll import create_poll
        poll = create_poll(game, role=next_role.name)
        notify_poll_begin(game, poll)

    @staticmethod
    @transaction.atomic
    def role_action(game: Game, player: Player, target: Player, poll: Poll):
        """
        Performs the action for a specific role.
        ROLE_ACTION -> NIGHT
        """

        # get target
        target = get_result(poll)

        # call action handler
        handler = game.get_action_handler(poll.role.name)
        outcome = handler.perform_action(player, target, game)

        # send outcome to clients
        notify_action_outcome(game.id, target, poll.role.name, outcome)

        # transition to NIGHT state
        game.fsm.end_action(game)
        game.save()

        return GameEngine.handle_night(game)


    @staticmethod
    @transaction.atomic
    def finish_night(game: Game):
        """
        Compute the outcome of the night and sends it to all players.
        NIGHT -> DAY
        """

        resolve_night(game)

        #TODO: call narrator, generate story and send it to players

        game.fsm.finish_night(game)
        game.save()

    @staticmethod
    @transaction.atomic
    def start_discussion(game: Game):
        """
        Create and send the discussion poll to players.
        DAY -> DISCUSSION
        """

        # Create poll for discussion
        from .poll import create_poll
        poll = create_poll(game, duration=300)

        #TODO: set timer


        notify_poll_begin(game, poll)

        # Handle transition
        game.fsm.start_discussion()
        game.save()


    #TODO: CHE FACCIO COL TIMER?

    @staticmethod
    @transaction.atomic
    def start_extra_vote(game: Game):
        """
        If players did not vote before the timer expires start an extra voting time.
        DISCUSSION -> EXTRA_VOTE
        """

        # If timer expired spur players to vote
        #TODO: timer expired. Extra_duration needed to set the new timer
        extra_duration = 30

        # Notify extra time
        notify_start_extra_time(game, extra_duration)

        # Handle transition
        game.fsm.start_extra_vote()
        game.save()

    @staticmethod
    @transaction.atomic
    def end_discussion(game: Game, poll: Poll):
        """
        Close the discussion poll.
        (DISCUSSION or EXTRA_VOTE) -> LYNCH
        """
        #TODO: probabilmente return lynch_player(game)

        # Set lynch target
        lynch = get_result(poll)
        game.lynch_target = lynch
        game.save()

        # Handle transition
        game.fsm.end_discussion()
        game.save()

        return GameEngine.lynch_player(game)

    @staticmethod
    @transaction.atomic
    def lynch_player(game: Game):
        """
        Lynch the target and check if anyone won.
        LYNCH -> NIGHT
        """
        # TODO: check lynch_target = null; potrebbero esserci pareggi nelle votazioni

        pass

    @staticmethod
    @transaction.atomic
    def end_game(game: Game):
        """
        Send the winners to the clients and end the game.
        (DAY or LYNCH) -> END_GAME
        """
        pass