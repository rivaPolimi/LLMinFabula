from django.db.models import Q
from .models import *
from .utils import kill_player

class BaseActionHandler:
    """
    Every role-specific handler inherits from this.
    """

    def perform_action(self, acting_player, target_player, game):
        raise NotImplementedError()
    
    def valid_target(self, acting_player, game):
        """
        Return which players this role is allowed to target.
        """
        return game.get_active_players()
    
    def is_action_required(self):
        """
        Some roles may not need to act every night.
        """
        return True
    
#TODO: Implement role specific action handlers

class NoActionHandler(BaseActionHandler):
    """
    Villagers do not perform any action.
    """

    def perform_action(self, acting_player, target_player, game):
        return
    
class WolfActionHandler(BaseActionHandler):
    """
    Wolf kill people during night.
    """

    def perform_action(self, acting_player, target_player, game):
        if target_player not in self.valid_target(acting_player, game):
            return "No one was killed, you did not choose a valid target"
        
        # Target does not die if he is protected
        if target_player.protected:
            return "No one was killed, your target was protected"

        # If courtesan is killed also her protected dies
        if target_player.role.name == "courtesan":
            protected_player = game.courtesan_target
            game.courtesan_target = None
            if not protected_player.role == "wolf":
                kill_player(protected_player)

        # If hunter is killed also his protected dies
        elif target_player.role.name == "hunter":
            aimed_player = game.hunter_target
            game.hunter_target = None
            kill_player(game, aimed_player)

        kill_player(game, target_player)

        return "Player killed"


    def valid_target(self, acting_player, game):
        return game.get_active_players().exclude(role__name = "wolf")
    
class CourtesanActionHandler(BaseActionHandler):
    """
    Every night the Courtesan can protect one player, but if wolves check the courtesan house, they both die.
    The same player cannot be protected twice in a row.
    """

    def perform_action(self, acting_player, target_player, game):
        if (not target_player in self.valid_target(acting_player, game) or 
            target_player.id == acting_player.id or 
            target_player.id == game.courtesan_target.id):
            game.courtesan_target = None
            return "No one was protected, invalid target"
        
        target_player.protected = True
        game.courtesan_target = target_player
        
        return "Target protected"

class GuardActionHandler(BaseActionHandler):
    """
    Every night the guard can protect one player. The same player cannot be protected twice in a row.
    """

    def perform_action(self, acting_player, target_player, game):
        if(not target_player in self.valid_target(acting_player, game) or
           target_player.id == acting_player.id or
           target_player.id == game.guard_target.id):
            game.guard_target = None
            return "No one was protected, invalid target"
        
        target_player.protected = True
        game.guard_target = target_player

        return "Target protected"
    
#TODO: serve? In teoria no se salvo la sua scelta nel db appena vota. Inoltre non modifica nulla nel db, 
#       succede qualcosa solo se muore, può anche votare più volte la stessa persona
class HunterActionHandler(BaseActionHandler):
    """
    Every night the hunter chooses a target. If the wolves kill the hunter he will shoot his target.
    """

    def perform_action(self, acting_player, target_player, game):
        if (not target_player in self.valid_target(acting_player, game) or 
            target_player.id == acting_player.id):
            game.hunter_target = None
            return "No one is targeted, invalid target"
        
        game.hunter_target = target_player
        return "Target aimed"

class JailerActionHandler(BaseActionHandler):
    """
    Every night the jailer chooses a target. The target will be protected but his ability won't have any effect.
    """

    def perform_action(self, acting_player, target_player, game):
        if (not target_player in self.valid_target(acting_player, game) or
            acting_player.id == target_player.id):
            game.jailer_target = None
            return "No one has been put in jail tonight, invalid target"
        
        game.jailer_target = target_player
        target_player.protected = True
        
        #TODO: senda la notifica dove chiami questa funzione
        return "Player in jail"