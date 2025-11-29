from viewflow.fsm import Transition, State
from .models import *
from .poll import *
from .utils import *

#TODO: togliere dopo che hai implementato fsm

#class States:
#    LOBBY = "lobby"
#    FIRST_NIGHT_BEGIN = "first_night_begin"
#    WOLF_FINISH = "wolf_finish"
#    DAY = "day"
#    DISCUSSION = "discussion"
#    EXTRA_VOTE = "extra_vote"
#    LYNCHING = "lynching"
#    NIGHT_BEGIN = "night_begin"
#    ROLE_ACTION = "role_action"
#    NIGHT_END = "night_end"

class GameStateMachine:

    state = State()

    @Transition(source="lobby", target="first_night_wolf")
    def first_night_wolf(self, game):
        poll = create_poll(game.id, role="wolf")
        send_poll(game, poll)
    
    @Transition(source="first_night_wolf", target="day")
    def first_night_resolution(self, game):
        pass
