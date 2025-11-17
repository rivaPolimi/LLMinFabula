import json
import random
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import *
from .utils import *
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

#TODO: save all piece of stories?

# Generate introduction for the game based on the setting provided by the user
def gen_introduction(game_id, setting):
    #TODO: call LLM API to generate story
    introduction = setting

    # Broadcast the story to all players
    channel_layer = get_channel_layer()
    async_to_sync(channel_layer.group_send)(
        f"game_{game_id}_all",
        {
            "type": "tell.story",
            "phase": "introduction",
            "text": introduction,
        }
    )