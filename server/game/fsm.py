from viewflow.fsm import Transition, State

class States:
    LOBBY = "lobby"
    INTRODUCTION = "introduction"
    ROLE_REVEAL = "role_reveal"
    DAY = "day"
    DISCUSSION = "discussion"
    EXTRA_VOTE = "extra_vote"
    LYNCH = "lynching"
    NIGHT = "night"
    NIGHT_REPORT = "night_report"
    ROLE_ACTION = "role_action"
    CHECK_WIN = "check_win"
    END_GAME = "end_game"

class GameStateMachine:

    state = State(States, default=States.LOBBY)

    @state.transition(source=States.LOBBY, target=States.INTRODUCTION)
    def start_introduction(self):
        pass

    @state.transition(source=States.INTRODUCTION, target=States.ROLE_REVEAL)
    def start_role_reveal(self):
        pass

    @state.transition(source=[States.ROLE_REVEAL, States.CHECK_WIN], target=States.NIGHT)
    def begin_night(self):
        pass

    @state.transition(source=States.NIGHT, target=States.ROLE_ACTION)
    def start_role_action(self):
        pass

    @state.transition(source=States.ROLE_ACTION, target=States.NIGHT)
    def end_action(self):
        pass

    @state.transition(source=States.NIGHT, target=States.NIGHT_REPORT)
    def finish_night(self):
        pass

    @state.transition(source=States.CHECK_WIN, target=States.DISCUSSION)
    def start_discussion(self):
        pass

    @state.transition(source=States.DISCUSSION, target=States.EXTRA_VOTE)
    def start_extra_vote(self):
        pass

    @state.transition(source=[States.DISCUSSION, States.EXTRA_VOTE], target=States.LYNCH)
    def end_discussion(self):
        pass

    @state.transition(source=[States.NIGHT_REPORT, States.LYNCH], target=States.CHECK_WIN)
    def check_win(self):
        pass

    @state.transition(source=States.CHECK_WIN, target=States.END_GAME)
    def end_game(self):
        pass
