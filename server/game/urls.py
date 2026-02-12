from django.urls import path
from .views import *

urlpatterns = [
    path('create_game/', CreateGameView.as_view(), name='Create Game'),
    path('join_game/', JoinGameView.as_view(), name='Join Game'),
    path('start_game/', StartGameView.as_view(), name='Start Game'),
]