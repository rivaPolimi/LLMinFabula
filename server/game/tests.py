from django.test import TestCase

from .actions import NoActionHandler, WolfActionHandler
from .engine import GameEngine
from .fsm import GameStateMachine
from .models import Game, Player, Role, Setting, States


class GameModelTests(TestCase):
	def setUp(self):
		self.setting = Setting.objects.create(
			name="default",
			alternative_role_names={},
			initial_prompt="prompt",
		)

		# Ensure unique role names within test DB to avoid duplicates
		Role.objects.filter(name__in=["wolf", "seer", "villager"]).delete()
		self.wolf = Role.objects.create(
			name="wolf",
			description="",
			order=1,
			play_first_night=True,
			has_action=True,
			action_class="game.actions.WolfActionHandler",
		)
		self.seer = Role.objects.create(
			name="seer",
			description="",
			order=2,
			play_first_night=False,
			has_action=True,
		)
		self.villager = Role.objects.create(
			name="villager",
			description="",
			order=3,
			play_first_night=True,
			has_action=False,
		)

		self.game = Game.objects.create(
			setting=self.setting,
			password="pw",
			available_roles=["wolf", "seer", "villager"],
		)

		self.wolf_player = Player.objects.create(
			game=self.game,
			nickname="w",
			role=self.wolf,
			role_name="wolf",
		)
		self.seer_player = Player.objects.create(
			game=self.game,
			nickname="s",
			role=self.seer,
			role_name="seer",
		)
		self.villager_player = Player.objects.create(
			game=self.game,
			nickname="v",
			role=self.villager,
			role_name="villager",
		)

	def test_active_roles_respects_first_night_and_actions(self):
		# First night: only roles with actions and play_first_night=True are considered.
		self.game.night_counter = 0
		self.game.save()
		names = [r.name for r in self.game.active_roles()]
		self.assertEqual(names, ["wolf"])

		# Later nights: roles with actions join even if play_first_night=False.
		self.game.night_counter = 2
		self.game.save()
		names = [r.name for r in self.game.active_roles()]
		self.assertEqual(names, ["wolf", "seer"])

	def test_next_active_role_progresses_and_stops(self):
		self.game.night_counter = 2
		self.game.current_turn_role = None
		self.game.save()

		self.assertEqual(self.game.next_active_role(), self.wolf)

		self.game.current_turn_role = self.wolf
		self.assertEqual(self.game.next_active_role(), self.seer)

		self.game.current_turn_role = self.seer
		self.assertIsNone(self.game.next_active_role())

	def test_get_action_handler_matches_current_turn(self):
		self.game.current_turn_role = self.wolf
		handler = self.game.get_action_handler("wolf")
		self.assertIsInstance(handler, WolfActionHandler)

		self.game.current_turn_role = self.seer
		handler = self.game.get_action_handler("wolf")
		self.assertIsInstance(handler, NoActionHandler)


class GameStateMachineTests(TestCase):
	def test_transitions_update_state(self):
		fsm = GameStateMachine()
		# Seed initial state using descriptor API rather than direct assignment
		GameStateMachine.state.set(fsm, States.LOBBY)

		fsm.start_introduction()
		self.assertEqual(fsm.state, States.INTRODUCTION)

		fsm.start_role_reveal()
		self.assertEqual(fsm.state, States.ROLE_REVEAL)

		fsm.begin_night()
		self.assertEqual(fsm.state, States.NIGHT)

		fsm.start_role_action()
		self.assertEqual(fsm.state, States.ROLE_ACTION)

		fsm.end_action()
		self.assertEqual(fsm.state, States.NIGHT)


class GameEngineTests(TestCase):
	def setUp(self):
		setting = Setting.objects.create(
			name="default",
			alternative_role_names={},
			initial_prompt="prompt",
		)
		self.game = Game.objects.create(
			setting=setting,
			password="pw",
			available_roles=["wolf"],
		)

		# A second game to ensure FSM state is not shared across instances.
		self.other_game = Game.objects.create(
			setting=setting,
			password="pw2",
			available_roles=["wolf"],
		)

	def test_transition_persists_game_state(self):
		GameEngine._transition(self.game, "start_introduction")
		self.game.refresh_from_db()
		self.assertEqual(self.game.state, States.INTRODUCTION)

	def test_fsm_not_shared_between_games(self):
		GameEngine._transition(self.game, "start_introduction")
		GameEngine._transition(self.game, "start_role_reveal")

		# The second game stays in its own LOBBY state until transitioned.
		self.other_game.refresh_from_db()
		self.assertEqual(self.other_game.state, States.LOBBY)

		GameEngine._transition(self.other_game, "start_introduction")
		self.other_game.refresh_from_db()
		self.assertEqual(self.other_game.state, States.INTRODUCTION)
