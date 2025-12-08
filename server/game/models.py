from django.db import models
from django.utils.module_loading import import_string
from .fsm import GameStateMachine

#TODO: riempire il db con i vari ruoli
class Role(models.Model):
    name = models.CharField(max_length=50)
    order = models.PositiveIntegerField()
    play_first_night = models.BooleanField(default=True)
    action_class = models.CharField(max_length=255, null=True, blank=True)


class Game(models.Model):

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
    night_counter = models.IntegerField(default=0)
    
    # FSM helper fields
    fsm = GameStateMachine()
    state = models.CharField(default="lobby")
    current_turn_role = models.ForeignKey("Role", null=True, blank=True, on_delete=models.SET_NULL, related_name="current_turn_role")

    # Role choices
    wolf_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="wolf_target")
    courtesan_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="courtesan_target")
    hunter_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="hunter_target")
    jailer_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="jailer_target")
    guard_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="guard_target")
    
    # Target of the daily lynching
    lynch_target = models.ForeignKey("Player", null=True, blank=True, on_delete=models.SET_NULL, related_name="lynch_target")

    
    REQUIRED_FIELDS = ["password"]

    def get_active_players(self):
        """
        Return all the alive players.
        """

        return Player.objects.filter(game_id = self.id, is_dead = False)

    def active_roles(self):
        """
        Return all the roles that have at least one living player.
        """

        #TODO: cambia la query e sistemala
        roles = ()
        if self.night_counter <= 1:
            roles = (
                self.players
                    .filter(game_id = self.id, is_dead = False)
                    .exclude(role__play_first_night = False)
                    .values_list("role", flat=True)
                    .distinct()
            )
        else:
            roles = (
                self.players
                    .filter(game_id = self.id, is_dead = False)
                    .values_list("role", flat=True)
                    .distinct()
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
    
    def get_action_handler(self, role_name):
        role = Role.objects.get(name = role_name)
        if not role or not role.action_class or not role == self.current_turn_role:
            from .actions import NoActionHandler
            return NoActionHandler()
        
        cls = import_string(role.action_class)
        return cls()

    

class Player(models.Model):
    
    #TODO: TOGLIERLI
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
        ("copycat", "Copycat"), #TODO: immune al jailer
        ("guard", "Guard"),
        ("ghost", "Ghost"), # fake role for dead players
    }
    
    game = models.ForeignKey("Game", on_delete=models.CASCADE, related_name="players")
    nickname = models.CharField(max_length=20)
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True)
    is_dead = models.BooleanField(default=False)
    protected = models.BooleanField(default=False)

    # Queried by the medium to check the role of the player when he was alive
    role_name = models.CharField(max_length=20, default=None, null=True) 

    REQUIRED_FIELDS = ["game", "nickname"]

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

    game = models.ForeignKey("Game", on_delete=models.CASCADE, related_name="polls")
    duration = models.PositiveIntegerField(default=30)
    role = models.CharField(max_length=10, choices=ROLES_CHOICES, default="none")

    REQUIRED_FIELDS = ["game", "duration", "role"]

class Vote(models.Model):
    # poll_id is unique, in any case I can check if the game is correct from the poll instance
    poll = models.ForeignKey("Poll", on_delete=models.CASCADE)
    voter = models.ForeignKey("Player", on_delete=models.DO_NOTHING, related_name="voter")
    target = models.ForeignKey("Player", on_delete=models.DO_NOTHING, related_name="target")

    class Meta:
        unique_together = ("poll", "voter") # One vote per poll

    REQUIRED_FIELDS = ["poll", "voter", "target"]


