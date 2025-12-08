from viewflow.fsm import Transition, State

class States:
    LOBBY = "lobby"
    DAY = "day"
    DISCUSSION = "discussion"
    EXTRA_VOTE = "extra_vote"
    LYNCH = "lynching"
    NIGHT = "night_begin"
    ROLE_ACTION = "role_action"
    END_GAME = "end_game"

class GameStateMachine:

    state = State(States, default=States.LOBBY)

    @state.transition(source=States.LOBBY, target=States.NIGHT)
    def begin_night(self):
        pass

    @state.transition(source=States.NIGHT, target=States.ROLE_ACTION)
    def start_role_action(self):
        pass

    @state.transition(source=States.ROLE_ACTION, target=States.NIGHT)
    def end_action(self):
        pass

    @state.transition(source=States.NIGHT, target=States.DAY)
    def finish_night(self):
        pass

    @state.transition(source=States.DAY, target=States.DISCUSSION)
    def start_discussion(self):
        pass

    @state.transition(source=States.DISCUSSION, target=States.LYNCH)
    def end_discussion(self):
        pass

    @state.transition(source=States.DISCUSSION, target=States.EXTRA_VOTE)
    def start_extra_vote(self):
        pass

    @state.transition(source=States.EXTRA_VOTE, target=States.LYNCH)
    def end_discussion(self):
        pass

    @state.transition(source=States.LYNCH, target=States.NIGHT)
    def lynch_player(self):
        pass

    @state.transition(source=States.DAY, target=States.END_GAME)
    def end_game(self):
        pass

    @state.transition(source=States.LYNCH, target=States.END_GAME)
    def end_game(self):
        pass