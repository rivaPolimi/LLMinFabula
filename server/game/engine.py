
from django.db import transaction
from .models import Game, Player, Poll
from .services.poll import get_result, start_poll_timer, create_poll
from .utils import resolve_night, kill_player, check_win, handle_win
from .notifications import *
from .narrator import Narrator

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

        game.night_counter += 1
        game.save()

        next_role = game.next_active_role()

        if not next_role:
            return GameEngine.finish_night(game)
        
        # Assign next role
        game.current_turn_role = next_role
        game.save()

        # Transition NIGHT -> ROLE_ACTION
        game.fsm.start_role_action()
        game.save()
        
        # Generate the message for the role
        Narrator.gen_role_action_message(game, game.setting, next_role.name)

        poll = create_poll(game, role=next_role.name)
        start_poll_timer(poll)

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

        if target and player:
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

        # Computes all the night actions
        killed_players = resolve_night(game)
        name_killed_players = [killed_player.nickname for killed_player in killed_players]

        # Narrator generates the report for the night
        Narrator.gen_night_report(game, game.setting, name_killed_players)

        # Check if anybody won
        end, winners = check_win(game)
        
        if end:
            return GameEngine.end_game(game, winners)

        game.fsm.finish_night(game)
        game.save()

        return GameEngine.start_discussion(game)

    @staticmethod
    @transaction.atomic
    def start_discussion(game: Game):
        """
        Create and send the discussion poll to players.
        DAY -> DISCUSSION
        """

        # Create poll for discussion
        poll = create_poll(game, duration=300)
        start_poll_timer(poll)

        notify_poll_begin(game, poll)

        # Handle transition
        game.fsm.start_discussion()
        game.save()

    @staticmethod
    @transaction.atomic
    def start_extra_vote(game: Game, poll: Poll):
        """
        If players did not vote before the timer expires start an extra voting time.
        DISCUSSION -> EXTRA_VOTE
        """

        # If timer expired spur players to vote
        extra_duration = 30
        poll.duration = extra_duration
        start_poll_timer(poll)
        poll.save()

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

        # Set lynch target #TODO: handla pareggio
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

        if not game.lynch_target:
            Narrator.gen_lynch_story(game, game.setting, "nobody", False)
        else:
            kill_player(game, game.lynch_target)
            Narrator.gen_lynch_story(game, game.setting, game.lynch_target.nickname, True)

        end, winners = check_win(game)
        if end:
            return GameEngine.end_game(game, winners)
        else:
            game.fsm.lynch_player()
            game.save()
            return GameEngine.handle_night(game)


    @staticmethod
    @transaction.atomic
    def end_game(game: Game, winners: list[Player]):
        """
        Send the winners to the clients and end the game.
        (DAY or LYNCH) -> END_GAME
        """

        winners_name = [winner.nickname for winner in winners]

        reason = ""
        if winners[0].role.name == "wolf":
            reason = "All villagers are eliminated"
        elif winners[0].role.name == "madman":
            reason = "The madman has been successfully lynched"
        else:
            reason = "Villagers killed all wolves"

        # Send winners to clients
        handle_win(game, winners)

        # Tell the story with the narrator
        Narrator.gen_story_end(game, game.setting, winners_name, reason)

        # Handle transition
        game.fsm.end_game()
        game.save()