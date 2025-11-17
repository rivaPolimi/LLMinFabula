from django.urls import path
from .views import *

urlpatterns = [
    path('create/', CreateGameView.as_view(), name='Create Game'),
    path('join/', JoinGameView.as_view(), name='Join Game'),
    path('start/', StartGameView.as_view(), name='Start Game'),
]