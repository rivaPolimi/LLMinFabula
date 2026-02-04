from django.shortcuts import get_object_or_404
from .models import Player, Role, Game
from .notifications import notify_player_in_jail

class BaseActionHandler:
    """
    Every role-specific handler inherits from this.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        """
        Perform the role-specific action.
        """
        raise NotImplementedError()
    
    def valid_target(self, acting_player: Player, game: Game):
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

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        return
    

class WolfActionHandler(BaseActionHandler):
    """
    Every night Wolves choose one player to kill.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if target_player not in self.valid_target(acting_player, game):
            return "No one was killed, you did not choose a valid target"
        
        game.wolf_target = target_player
        game.save()
        


    def valid_target(self, acting_player: Player, game: Game):
        return game.get_active_players().exclude(role__name = "wolf")
    

class CourtesanActionHandler(BaseActionHandler):
    """
    Every night the Courtesan can protect one player, but if wolves check the courtesan house, they both die.
    The same player cannot be protected twice in a row.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if game.jailer_target.id == acting_player.id:
            game.courtesan_target = None
            return "Jailer blocked your ability"

        if not target_player in self.valid_target(acting_player, game):
            game.courtesan_target = None
            return "No one was protected, invalid target"
        
        target_player.is_protected = True
        game.courtesan_target = target_player
        target_player.save()
        game.save()

        return "Target protected"

    def valid_target(self, acting_player: Player, game: Game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id).exclude(id == game.courtesan_target.id)


class GuardActionHandler(BaseActionHandler):
    """
    Every night the Guard can protect one player. The same player cannot be protected twice in a row.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if game.jailer_target.id == acting_player.id:
            game.guard_target = None
            return "Jailer blocked your ability"
        
        if not target_player in self.valid_target(acting_player, game):
            game.guard_target = None
            return "No one was protected, invalid target"
        
        target_player.is_protected = True
        game.guard_target = target_player

        return "Target protected"
    
    def valid_target(self, acting_player: Player, game: Game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id).exclude(id == game.guard_target.id)


class HunterActionHandler(BaseActionHandler):
    """
    Every night the Hunter chooses a target. If the wolves kill the hunter he will shoot his target.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if game.jailer_target.id == acting_player.id:
            game.hunter_target = None
            return "Jailer blocked your ability"
        
        if not target_player in self.valid_target(acting_player, game):
            game.hunter_target = None
            return "No one is targeted, invalid target"
        
        game.hunter_target = target_player
        return "Target aimed"
    
    def valid_target(self, acting_player: Player, game: Game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id)


class JailerActionHandler(BaseActionHandler):
    """
    Every night the Jailer chooses a target. The target will be protected but his ability won't have any effect.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if not target_player in self.valid_target(acting_player, game):
            game.jailer_target = None
            return "No one has been put in jail tonight, invalid target"
        
        game.jailer_target = target_player
        target_player.is_protected = True
        
        notify_player_in_jail(game.id, target_player.id)

        return "Player in jail"
    
    def valid_target(self, acting_player: Player, game: Game):
        return super().valid_target(acting_player, game).exclude(id == acting_player.id)


class SeerActionHandler(BaseActionHandler):
    """
    Every night the Seer chooses a player and he is revealed if his target is a wolf or a villager.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
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

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if not target_player in self.valid_target(acting_player, game):
            return "No answer, you asked an alive player"
        
        if target_player.role_name == "wolf":
            return "wolf"
        else:
            return "villager"
    
    def valid_target(self, acting_player: Player, game: Game):
        return Player.objects.filter(game_id = game.id, is_dead = True)


class CopycatActionHandler(BaseActionHandler):
    """
    Every night the Copycat chooses one player. If his target is a wolf the Copycat becomes a wolf.
    """

    def perform_action(self, acting_player: Player, target_player: Player, game: Game):
        if not target_player in self.valid_target():
            return "No one copied"
        
        if target_player.role.name == "wolf":
            role = get_object_or_404(Role, name="wolf")
            acting_player.role = role
            acting_player.role_name = "wolf"
            return "You are now a wolf"
        else:
            return "No one copied"
    
    def valid_target(self, acting_player: Player, game: Game):
        return super().valid_target(acting_player, game).exclude(acting_player)
    

