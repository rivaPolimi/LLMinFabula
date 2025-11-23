from django.db import models
from django_fsm import FSMField, transition
from .fsm import GameFSMMixin

#TODO: riempire il db con i vari ruoli
class Role(models.Model):
    name = models.CharField(max_length=50)
    order = models.PositiveIntegerField()
    action_class = models.CharField(max_length=255, null=True, blank=True)


class Game(models.Model, GameFSMMixin):

    SETTING_CHOICES = {
        ("child", "Child"),
        ("wolf", "Wolf"),
        ("vampire", "Vampire"),
        ("zombie", "Zombie"),
    }

    max_players = models.IntegerField(default=5)
    setting = models.CharField(
                    max_length=7,
                    choices=SETTING_CHOICES,
                    default="wolf")
    password = models.CharField(max_length=20)
    available_roles = models.JSONField()
    
    # FSM helper fields
    state = FSMField(default="lobby", protected=True)
    current_turn_role = models.ForeignKey(Role, null=True, blank=True, on_delete=models.SET_NULL)

    # Role choices TODO: needed?
    
    REQUIRED_FIELDS = [password]

    def get_active_players(self):
        """
        Return all the alive players.
        """

        return Player.objects.filter(game_id = self.id, is_dead = False)

    def active_roles(self):
        """
        Return all the roles that have at least one living player.
        """

        roles = (
            self.players.filter(game_id = self.id, is_dead = False).values_list("role", flat=True).distinct()
        )
        return Role.objects.filter(id__in = roles).order_by("order")

    def next_active_role(self):
        """
        Return the next role in turn order which has alive players.
        """

        roles = list(self.active_roles())

        if not roles:
            return None
        
        # First turn after lynching
        if self.current_turn_role is None:
            return roles[0]
        
        # Normal progression
        for i, role in enumerate(roles):
            if role.id == self.current_turn_role.id and i + 1 < len(roles):
                return roles[i + 1]
            
        # Reached end
        return None
    

class Player(models.Model):
    
    ROLES_CHOICES = {
        ("none", "None"),
        ("wolf", "Wolf"),
        ("villager", "Villager"),
        ("seer", "Seer"),
        ("madman", "Madman"),
        ("courtesan", "Courtesan"),
        ("medium", "Medium"),
        ("hunter", "Hunter"),
        ("jailer", "Jailer"),
        ("copycat", "Copycat"),
        ("guard", "Guard"),
        ("ghost", "Ghost"), # fake role for dead players
    }
    
    game_id = models.ForeignKey(Game, on_delete=models.CASCADE, related_name="players")
    nickname = models.CharField(max_length=20)
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True)
    is_dead = models.BooleanField(default=False)
    protected = models.BooleanField(default=False)

    REQUIRED_FIELDS = [game_id, nickname]

class Poll(models.Model):

    ROLES_CHOICES = {
        ("none", "None"),
        ("wolf", "Wolf"),
        ("villager", "Villager"),
        ("seer", "Seer"),
        ("madman", "Madman"),
        ("courtesan", "Courtesan"),
        ("medium", "Medium"),
        ("hunter", "Hunter"),
        ("jailer", "Jailer"),
        ("copycat", "Copycat"),
        ("guard", "Guard"),
        ("ghost", "Ghost"), # fake role for dead players
        ("all", "All"),
    }

    game_id = models.ForeignKey(Game, on_delete=models.CASCADE)
    duration = models.PositiveIntegerField(default=30)
    role = models.CharField(max_length=10, choices=ROLES_CHOICES, default="none")

    REQUIRED_FIELDS = [game_id]

class Vote(models.Model):
    # poll_id is unique, in any case I can check if the game is correct from the poll instance
    poll_id = models.ForeignKey(Poll, on_delete=models.CASCADE)
    voter = models.ForeignKey(Player, on_delete=models.DO_NOTHING, related_name="voter")
    target = models.ForeignKey(Player, on_delete=models.DO_NOTHING, related_name="target")

    class Meta:
        unique_together = ("poll_id", "voter") # One vote per poll

    REQUIRED_FIELDS = [poll_id, voter, target]


