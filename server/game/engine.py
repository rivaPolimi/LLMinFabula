
from django.db import transaction
from .models import Game, Player, Poll, States
from .services.poll import get_result, start_poll_timer, create_poll
from .utils import resolve_night, kill_player, check_win, handle_win
from .notifications import *
from .narrator import Narrator
from .services.phase import start_phase_timer
from .fsm import GameStateMachine

class GameEngine:
    """
    Centralized service layer to manage game flow and FSM transitions. 
    """

    @staticmethod
    def _get_fsm(game: Game) -> GameStateMachine:
        """Return an FSM instance aligned with the game's current state."""
        fsm = GameStateMachine()
        current_state = game.state or States.LOBBY
        # Normalize to States enum and seed via descriptor's set()
        try:
            normalized = States(current_state)
        except Exception:
            normalized = States.LOBBY
        GameStateMachine.state.set(fsm, normalized)
        return fsm

    @staticmethod
    @transaction.atomic
    def start_game(game: Game):
        """
        Starts the game. 
        LOBBY -> INTRODUCTION
        """

        GameEngine._transition(game, "start_introduction")

        # Generate introduction
        Narrator.gen_introduction(game.id, game.setting)

        # Notify client
        INTRO_DURATION = 30 # Max duration of introduction screen
        notify_phase_start(game.id, "introduction", INTRO_DURATION)

        start_phase_timer(game.id, "introduction", INTRO_DURATION)

    @staticmethod
    @transaction.atomic
    def role_reveal(game: Game):
        """
        Reveals the role to players
        INTRODUCTION -> ROLE_REVEAL
        """

        GameEngine._transition(game, "start_role_reveal")

        ROLE_DURATION = 15

        # Notify phase change
        notify_phase_start(game.id, "roleReveal", ROLE_DURATION)
        start_phase_timer(game.id, "roleReveal", ROLE_DURATION)

    @staticmethod
    @transaction.atomic
    def night_intro(game: Game):
        """
        Send the introduction to night phase to client.
        (ROLE_REVEAL or CHECK_WIN) -> NIGHT
        """

        game.night_counter += 1
        GameEngine._transition(game, "begin_night")

        NIGHT_INTRO_DURATION = 15

        # Generate intro
        Narrator.gen_night_intro(game, game.setting)

        notify_phase_start(game.id, "nightIntro", NIGHT_INTRO_DURATION)
        start_phase_timer(game.id, "nightIntro", NIGHT_INTRO_DURATION)

    @staticmethod
    @transaction.atomic
    def handle_night(game: Game):
        """
        Chooses next role or starts day phase.
        NIGHT_INTRO -> (ROLE_ACTION or DAY)
        """

        next_role = game.next_active_role()

        if not next_role:
            return GameEngine.finish_night(game)
        
        # Assign next role
        game.current_turn_role = next_role
        game.save()

        # Transition NIGHT -> ROLE_ACTION
        GameEngine._transition(game, "start_role_action")
        
        # Generate the message for the role
        Narrator.gen_role_action_message(game, game.setting, next_role.name)

        poll = create_poll(game, role=next_role.name)
        notify_poll_begin(game, poll)
        start_poll_timer(poll)

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
        GameEngine._transition(game, "end_action")

        return GameEngine.handle_night(game)


    @staticmethod
    @transaction.atomic
    def finish_night(game: Game):
        """
        Compute the outcome of the night and sends it to all players.
        NIGHT -> NIGHT_REPORT
        """

        GameEngine._transition(game, "finish_night")

        # Computes all the night actions
        killed_players = resolve_night(game)
        name_killed_players = [killed_player.nickname for killed_player in killed_players]

        NIGHT_REPORT_DURATION = 30

        # Narrator generates the report for the night
        Narrator.gen_night_report(game, game.setting, name_killed_players)
        
        notify_night_victims(game.id, killed_players)
        
        notify_phase_start(game.id, "nightReport", NIGHT_REPORT_DURATION)
        start_phase_timer(game.id, "nightReport", NIGHT_REPORT_DURATION)

    @staticmethod
    @transaction.atomic
    def check_win_engine(game: Game, previous_phase: str):
        """
        Check if there is any winner, if so end the game, if not continue.
        () -> CHECK_WIN
        """

        GameEngine._transition(game, "check_win")

        # Check if anybody won
        end, winners = check_win(game)
        
        if end:
            return GameEngine.end_game(game, winners)
        elif previous_phase == "nightReport":
            return GameEngine.start_discussion(game)
        elif previous_phase == "lynchOutcome":
            return GameEngine.night_intro(game)

    @staticmethod
    @transaction.atomic
    def start_discussion(game: Game):
        """
        Create and send the discussion poll to players.
        CHECK_WIN -> DISCUSSION
        """

        notify_phase_start(game.id, "discussion", None)

        # Create poll for discussion
        poll = create_poll(game, duration=300)
        start_poll_timer(poll)

        notify_poll_begin(game, poll)

        # Handle transition
        GameEngine._transition(game, "start_discussion")

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
        GameEngine._transition(game, "start_extra_vote")

    @staticmethod
    @transaction.atomic
    def end_discussion(game: Game, poll: Poll):
        """
        Close the discussion poll.
        (DISCUSSION or EXTRA_VOTE) -> LYNCH
        """

        # Set lynch target
        lynch = get_result(poll)
        game.lynch_target = lynch
        game.save()

        # Handle transition
        GameEngine._transition(game, "end_discussion")

        return GameEngine.lynch_player(game)

    @staticmethod
    @transaction.atomic
    def lynch_player(game: Game):
        """
        Lynch the target and check if anyone won.
        """

        if not game.lynch_target:
            Narrator.gen_lynch_story(game, game.setting, "nobody", False)
        else:
            kill_player(game, game.lynch_target)
            Narrator.gen_lynch_story(game, game.setting, game.lynch_target.nickname, True)

        LYNCH_DURATION = 30
        
        notify_phase_start(game.id, "lynch", LYNCH_DURATION)
        start_phase_timer(game.id, "lynch", LYNCH_DURATION)

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
        notify_phase_start(game.id, "endGame", 0)

        # Handle transition
        GameEngine._transition(game, "end_game")

    @staticmethod
    @transaction.atomic
    def _transition(game: Game, transition_name: str):
        fsm = GameEngine._get_fsm(game)
        transition = getattr(fsm, transition_name)
        transition()
        game.state = fsm.state
        # Save the whole game object to persist any other in-flight changes (e.g., counters).
        game.save()
