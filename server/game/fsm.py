from viewflow.fsm import Transition, State
from .utils import *

#TODO: togliere dopo che hai implementato fsm

class States:
    LOBBY = "lobby"
    FIRST_NIGHT_WOLF = "first_night_wolf"
    WOLF_FINISH = "wolf_finish"
    DAY = "day"
    DISCUSSION = "discussion"
    EXTRA_VOTE = "extra_vote"
    LYNCHING = "lynching"
    NIGHT_BEGIN = "night_begin"
    ROLE_ACTION = "role_action"
    NIGHT_END = "night_end"

class GameStateMachine:

    state = State(States, default=States.LOBBY)

    @state.transition(source=States.LOBBY, target=States.FIRST_NIGHT_WOLF)
    def first_night_wolf(self, game):
        from .poll import create_poll
        poll = create_poll(game, role="wolf")
        send_poll(game, poll)
    
    @state.transition(source=States.FIRST_NIGHT_WOLF, target=States.DAY)
    def first_night_resolution(self, game):
        pass
