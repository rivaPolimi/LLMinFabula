from django.shortcuts import get_object_or_404
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import *
from .utils import kill_player

class BaseActionHandler:
    """
    Every role-specific handler inherits from this.
    """

    def perform_action(self, acting_player, target_player, game):
        """
        Perform the role-specific action.
        """
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


class NoActionHandler(BaseActionHandler):
    """
    Villagers do not perform any action.
    """

    def perform_action(self, acting_player, target_player, game):
        return
    
#TODO: forse meglio spostare la logica in una funzione resolve_night e usare questa solo per settare wolf_target
#TODO: cambiare wolf.perform_action() e creare resolve_night()
class WolfActionHandler(BaseActionHandler):
    """
    Every night Wolves choose one player to kill.
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
        if game.jailer_target.id == acting_player.id:
            game.courtesan_target = None
            return "Jailer blocked your ability"

        if not target_player in self.valid_target(acting_player, game):
            game.courtesan_target = None
            return "No one was protected, invalid target"
        
        target_player.protected = True
        game.courtesan_target = target_player
        
        return "Target protected"

    def valid_target(self, acting_player, game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id).exclude(id == game.courtesan_target.id)


class GuardActionHandler(BaseActionHandler):
    """
    Every night the Guard can protect one player. The same player cannot be protected twice in a row.
    """

    def perform_action(self, acting_player, target_player, game):
        if game.jailer_target.id == acting_player.id:
            game.guard_target = None
            return "Jailer blocked your ability"
        
        if not target_player in self.valid_target(acting_player, game):
            game.guard_target = None
            return "No one was protected, invalid target"
        
        target_player.protected = True
        game.guard_target = target_player

        return "Target protected"
    
    def valid_target(self, acting_player, game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id).exclude(id == game.guard_target.id)


class HunterActionHandler(BaseActionHandler):
    """
    Every night the Hunter chooses a target. If the wolves kill the hunter he will shoot his target.
    """

    def perform_action(self, acting_player, target_player, game):
        if game.jailer_target.id == acting_player.id:
            game.hunter_target = None
            return "Jailer blocked your ability"
        
        if not target_player in self.valid_target(acting_player, game):
            game.hunter_target = None
            return "No one is targeted, invalid target"
        
        game.hunter_target = target_player
        return "Target aimed"
    
    def valid_target(self, acting_player, game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id)


class JailerActionHandler(BaseActionHandler):
    """
    Every night the Jailer chooses a target. The target will be protected but his ability won't have any effect.
    """

    def perform_action(self, acting_player, target_player, game):
        if not target_player in self.valid_target(acting_player, game):
            game.jailer_target = None
            return "No one has been put in jail tonight, invalid target"
        
        game.jailer_target = target_player
        target_player.protected = True
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"game_{game.id}_{target_player.id}",
            {"type": "player.arrested", "message": "Jailer arrested you", "game_id": game.id}
        )

        return "Player in jail"
    
    def valid_target(self, acting_player, game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id)


class SeerActionHandler(BaseActionHandler):
    """
    Every night the Seer chooses a player and he is revealed if his target is a wolf or a villager.
    """

    def perform_action(self, acting_player, target_player, game):
        if game.jailer_target.id == acting_player.id:
            return "Jailer blocked your ability"
        
        if not target_player in self.valid_target(acting_player, game):
            return "None, invalid target"
        
        if target_player.role == "wolf":
            return "wolf"
        else:
            return "villager"


class MediumActionHandler(BaseActionHandler):
    """
    Every night the Medium chooses a dead player and asks him if he was a wolf or not.
    """

    def perform_action(self, acting_player, target_player, game):
        if not target_player in self.valid_target(acting_player, game):
            return "No answer, you asked an alive player"
        
        if target_player.role_name == "wolf":
            return "wolf"
        else:
            return "villager"
    
    def valid_target(self, acting_player, game):
        return Player.objects.filter(game_id = game.id, is_dead = True)


class CopycatActionHandler(BaseActionHandler):
    """
    Every night the Copycat chooses one player. If his target is a wolf the Copycat becomes a wolf.
    """

    def perform_action(self, acting_player, target_player, game):
        if not target_player in self.valid_target():
            return "No one copied"
        
        if target_player.role.name == "wolf":
            role = get_object_or_404(Role, name="wolf")
            acting_player.role = role
            acting_player.role_name = "wolf"
            return "You are now a wolf"
        else:
            return "No one copied"
    
    def valid_target(self, acting_player, game):
        return super().valid_target(acting_player, game).exclude(acting_player)
    

