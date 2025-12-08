import os
from django.shortcuts import get_object_or_404
from .models import *
from .utils import *
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from openai import OpenAI

def get_deployment_name():
    return os.environ.get("AZURE_DEPLOYMENT_NAME")

def get_openai_client():
    return OpenAI(
        base_url=os.environ.get("AZURE_OPENAI_ENDPOINT"),
        api_key=os.environ.get("AZURE_OPENAI_KEY")
    )

# Generate introduction for the game based on the setting provided by the user
def gen_introduction(game_id, setting):
    #TODO: call LLM API to generate story
    #TODO: GESTIRE BAMBINI

    client = get_openai_client()

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
    response = client.chat.completions.create(
        model=get_deployment_name(),
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