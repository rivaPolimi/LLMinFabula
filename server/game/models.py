from django.db import models
from django.contrib.auth.models import User

class Game(models.Model):

    SETTING_CHOICES = {
        ("child", "Child"),
        ("wolf", "Wolf"),
        ("vampire", "Vampire"),
        ("zombie", "Zombie"),
    }

    PHASE_CHOICES = {
        ("lobby", "Lobby"),
        ("first_night", "First night wolf attack"), #first night is alone because only wolf can play
        ("day", "Day"),
        ("discussion", "Discussion"), #also includes vote
        ("extra_vote", "Extra vote time"), #used in case someone didn't vote in the discussion phase
        ("night", "Night")
    }

    num_players = models.IntegerField(default=5)
    setting = models.CharField(
                    max_length=7,
                    choices=SETTING_CHOICES,
                    default="wolf")
    password = models.CharField(max_length=20)
    is_full = models.BooleanField(default=False)
    phase = models.CharField(
                    max_length=15,
                    choices=PHASE_CHOICES,
                    default="lobby")
    
    REQUIRED_FIELDS = [password]
    
class Role(models.Model):
    #TODO: maybe setup a One-to-one relationship?
    game_id = models.ForeignKey(Game, on_delete=models.CASCADE)
    wolf = models.PositiveSmallIntegerField(default=1)
    villager = models.PositiveSmallIntegerField(default=4)
    seer = models.PositiveSmallIntegerField(default=0)
    madman = models.PositiveSmallIntegerField(default=0)
    courtesan = models.PositiveSmallIntegerField(default=0)
    medium = models.PositiveSmallIntegerField(default=0)
    hunter = models.PositiveSmallIntegerField(default=0)
    jailer = models.PositiveSmallIntegerField(default=0)
    copycat = models.PositiveSmallIntegerField(default=0)
    guard = models.PositiveSmallIntegerField(default=0)

    def get_fields(self):
        return [(field.name, getattr(self, field.name)) for field in Role._meta.fields if not field.name == "game_id"]

    REQUIRED_FIELDS = [game_id]

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
    
    game_id = models.ForeignKey(Game, on_delete=models.CASCADE)
    nickname = models.CharField(max_length=20)
    role = models.CharField(max_length=10, choices=ROLES_CHOICES, default="none")
    is_dead = models.BooleanField(default=False)

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
    voter = models.ForeignKey(Player, on_delete=models.DO_NOTHING)
    target = models.PositiveIntegerField()

    class Meta:
        unique_together = ("poll_id", "voter") # One vote per poll

    REQUIRED_FIELDS = [game_id, poll_id, voter, target]


