import logging
import time
from django.db import transaction
from .models import Game, Player, Poll, States
from .services.poll import get_result, start_poll_timer, create_poll
from .utils import resolve_night, kill_player, check_win, handle_win
from .notifications import *
from .narrator import Narrator
from .services.phase import start_phase_timer
from .fsm import GameStateMachine

logger = logging.getLogger(__name__)

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
    def start_game(game: Game):
        """
        Starts the game. 
        LOBBY -> INTRODUCTION
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting game initialization")

        transition_start = time.time()
        GameEngine._transition(game, "start_introduction")
        logger.debug(f"[Game {game.id}] FSM transition completed in {time.time() - transition_start:.2f}s")

        # Generate introduction
        intro_start = time.time()
        logger.debug(f"[Game {game.id}] Calling Narrator.gen_introduction")
        Narrator.gen_introduction(game.id, game.setting)
        logger.info(f"[Game {game.id}] Introduction generation completed in {time.time() - intro_start:.2f}s")

        # All wolves should know each other
        wolves_start = time.time()
        wolves = game.get_active_players().filter(role__name="wolf")
        wolf_ids = [wolf.id for wolf in wolves]
        notify_wolves(game.id, wolf_ids)
        logger.debug(f"[Game {game.id}] Wolf notification sent in {time.time() - wolves_start:.2f}s (wolf_count: {len(wolf_ids)})")

        # Notify client
        INTRO_DURATION = 120 # Max duration of introduction screen
        notify_start = time.time()
        notify_phase_start(game.id, "introduction", INTRO_DURATION)
        logger.debug(f"[Game {game.id}] Phase start notification sent in {time.time() - notify_start:.2f}s")
        
        timer_start = time.time()
        start_phase_timer(game.id, "introduction", INTRO_DURATION)
        logger.debug(f"[Game {game.id}] Phase timer started in {time.time() - timer_start:.2f}s")

        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] Game start_game() completed in {total_duration:.2f}s")

    @staticmethod
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
    def night_intro(game: Game):
        """
        Send the introduction to night phase to client.
        (ROLE_REVEAL or CHECK_WIN) -> NIGHT
        """

        # Update night counter and reset targets
        game.night_counter += 1
        game.wolf_target = None
        game.courtesan_target = None
        game.hunter_target = None
        game.jailer_target = None
        game.guard_target = None
        game.lynch_target = None
        game.current_turn_role = None
        GameEngine._transition(game, "begin_night")

        game.save()

        NIGHT_INTRO_DURATION = 45

        # Generate intro
        Narrator.gen_night_intro(game, game.setting)

        notify_phase_start(game.id, "nightIntro", NIGHT_INTRO_DURATION)
        start_phase_timer(game.id, "nightIntro", NIGHT_INTRO_DURATION)

    @staticmethod
    def handle_night(game: Game):
        """
        Chooses next role or starts day phase.
        NIGHT_INTRO -> (ROLE_ACTION or DAY)
        """

        next_role = game.next_active_role()

        if next_role is None:
            return GameEngine.finish_night(game)
        
        # Assign next role
        game.current_turn_role = next_role
        game.save()

        # Transition NIGHT -> ROLE_ACTION
        GameEngine._transition(game, "start_role_action")

        # Generate the message for the role
        Narrator.gen_role_action_message(game, game.setting, next_role.name)
        
        # Notify clients about the action phase and the role that has to play
        notify_phase_start(game.id, "roleAction", 0)
        notify_role_turn(game.id, next_role.name)

        poll = create_poll(game, role=next_role.name)
        notify_poll_begin(game, poll)
        start_poll_timer(poll)

    @staticmethod
    def role_action(game: Game, player: Player, target: Player, poll: Poll):
        """
        Performs the action for a specific role.
        ROLE_ACTION -> NIGHT
        """

        # get target
        target = get_result(poll)

        if target and player:
            # call action handler
            handler = game.get_action_handler(poll.role)
            outcome = handler.perform_action(player, target, game)
    
            # send outcome to clients if medium or seer acted
            if poll.role in ["medium", "seer"]:
                if outcome in ["wolf", "villager"]:
                    outcome = game.setting.alternative_role_names[outcome]
                notify_action_outcome(game.id, target, poll.role, outcome)

        # transition to NIGHT state
        GameEngine._transition(game, "end_action")

        return GameEngine.handle_night(game)


    @staticmethod
    def finish_night(game: Game):
        """
        Compute the outcome of the night and sends it to all players.
        NIGHT -> NIGHT_REPORT
        """

        GameEngine._transition(game, "finish_night")

        # Computes all the night actions
        killed_players = resolve_night(game)
        name_killed_players = [killed_player.nickname for killed_player in killed_players] if killed_players else []

        NIGHT_REPORT_DURATION = 300

        # Narrator generates the report for the night
        Narrator.gen_night_report(game, game.setting, name_killed_players)
        
        if killed_players is not None:
            notify_night_victims(game.id, killed_players)
        
        notify_phase_start(game.id, "nightReport", NIGHT_REPORT_DURATION)
        start_phase_timer(game.id, "nightReport", NIGHT_REPORT_DURATION)

    @staticmethod
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
    def start_discussion(game: Game):
        """
        Create and send the discussion poll to players.
        CHECK_WIN -> DISCUSSION
        """

        notify_phase_start(game.id, "discussion", 0)

        # Create poll for discussion
        poll = create_poll(game, duration=300)
        start_poll_timer(poll)

        notify_poll_begin(game, poll)

        # Handle transition
        GameEngine._transition(game, "start_discussion")

    @staticmethod
    def end_discussion(game: Game, poll: Poll):
        """
        Close the discussion poll.
        DISCUSSION -> LYNCH
        """

        # Set lynch target
        lynch = get_result(poll)
        game.lynch_target = lynch
        game.save()

        # Handle transition
        GameEngine._transition(game, "end_discussion")

        return GameEngine.lynch_player(game)

    @staticmethod
    def lynch_player(game: Game):
        """
        Lynch the target and check if anyone won.
        """

        if not game.lynch_target:
            Narrator.gen_lynch_story(game, game.setting, "nobody", False)
        else:
            kill_player(game, game.lynch_target)
            notify_lynch_outcome(game.id, game.lynch_target)
            Narrator.gen_lynch_story(game, game.setting, game.lynch_target.nickname, True)

        LYNCH_DURATION = 60
        
        notify_phase_start(game.id, "lynching", LYNCH_DURATION)
        start_phase_timer(game.id, "lynching", LYNCH_DURATION)

    @staticmethod
    def end_game(game: Game, winners: list[Player]):
        """
        Send the winners to the clients and end the game.
        (DAY or LYNCH) -> END_GAME
        """

        winners_name = [winner.nickname for winner in winners]

        reason = ""
        if winners[0].role_name == "madman":
            reason = "The madman has been successfully lynched"
        elif winners[0].role.name == "wolf":
            reason = "All villagers are eliminated"
        else:
            reason = "Villagers killed all wolves"

        # Handle transition BEFORE deleting the game
        GameEngine._transition(game, "end_game")

        # Send winners to clients
        handle_win(game, winners)

        # Tell the story with the narrator
        Narrator.gen_story_end(game, game.setting, winners_name, reason)
        notify_phase_start(game.id, "endGame", 0)

    @staticmethod
    @transaction.atomic
    def _transition(game: Game, transition_name: str):
        fsm = GameEngine._get_fsm(game)
        transition = getattr(fsm, transition_name)
        transition()
        game.state = fsm.state
        # Save the whole game object to persist any other in-flight changes (e.g., counters).
        game.save()
