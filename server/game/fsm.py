from django_fsm import transition
from .models import *

#TODO: VANNO TOLTI MA LI TENGO QUI PER RICORDAMI COSA FANNO I VARI STATI
PHASE_CHOICES = {
    ("lobby", "Lobby"),
    ("first_night", "First night description"), # first night is alone because only wolf can play
    ("first_night_wolf", "First night wolf attack")
    ("day", "Day"), # Also check win condition
    ("discussion", "Discussion"), # also includes vote
    ("extra_vote", "Extra vote time"), # used in case someone didn't vote in the discussion phase
    ("lynching", "Lynching")
    ("night", "Night"), 
    ("copycat", "Copycat action"),
    ("wolf", "Wolf action"),
    ("seer", "Seer action"),
    ("medium", "Medium action"),
    ("courtesan", "Courtesan action"),
    ("hunter", "Hunter action"),
    ("jailer", "Jailer action"),
    ("guard", "Guard action"),
}

class GameFSMMixin:

    # --- FIRST NIGHT ---

    @transition(field=Game.state, source="lobby", target="first_night")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="first_night", target="first_night_wolf")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="first_night_wolf", target="day")
    def next_phase(self):
        pass

    # --- GAME LOOP ---

    @transition(field=Game.state, source="day", target="discussion")
    def next_phase(self):
        pass

    #TODO: GESTIRE EXTRA_VOTE, SE TUTTI HANNO GIA VOTATO SALTO DIRETTAMENTE A LYNCHING
    @transition(field=Game.state, source="discussion", target="extra_vote")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="extra_vote", target="lynching")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="lynching", target="night")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="night", target="night")
    def next_phase(self, game):
        next_role = game.next_active_role()

        if next_role is None:
            game.state = "day"
            game.current_turn_role = None
            game.save()
            return
        
        game.current_turn_role = next_role
        game.save()

    # --- END GAME ---
    @transition(field=Game.state, source="day", target="end")
    def next_phase(self):
        pass

    @transition(field=Game.state, source="lynching", target="end")
    def next_phase(self):
        pass