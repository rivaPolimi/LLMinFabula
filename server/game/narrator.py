import json
import os
import random
import openai
from django.shortcuts import get_object_or_404
from .models import *
from .utils import *
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

openai.api_key = os.getenv("AZURE_OPENAI_KEY")
openai.azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
openai.api_type = "azure"
openai.api_version = "2023-05-15"

deployment_name = "LLMinFabula"

# Generate introduction for the game based on the setting provided by the user
def gen_introduction(game_id, setting):
    #TODO: call LLM API to generate story
    #TODO: GESTIRE BAMBINI

    # Set the background prompt for the LLM. TODO: forse setting va messo nei prompt, c'è rischio che si confonda con le varie partite
    conversation = [{
        "role": "system", 
        "content": "you are a narrator for a lupus in fabula game, " +
        "which is set in a " + setting + " enviroment."
    }]

    # Ask LLM to generate an introduction
    conversation.append({
        "role": "user",
        "content": "Please write an introduction for this lupus in fabula game."
    })
    response = openai.chat.completions.create(
        messages=conversation
    )

    introduction = response.choices[0].message.content

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