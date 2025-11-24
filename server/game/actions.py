from .models import *

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

