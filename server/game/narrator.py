import os
from .models import *
from .utils import *
from .notifications import notify_narrator_story
from openai import AzureOpenAI

class Narrator:

    @staticmethod
    def get_deployment_name():
        return os.environ.get("AZURE_DEPLOYMENT_NAME")

    @staticmethod
    def get_openai_client():
        return AzureOpenAI(
            azure_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT"),
            api_key=os.environ.get("AZURE_OPENAI_KEY"),
            api_version=os.environ.get("AZURE_DEPLOYMENT_MODEL")
        )

    @staticmethod
    def gen_introduction(game_id: int, setting: Setting):
        """
        Generate introduction for the game based on the setting provided by the user
        """
        #TODO: GESTIRE BAMBINI

        client = Narrator.get_openai_client()

        # Set the background prompt for the LLM.
        conversation = [{
            "role": "system", 
            "content": setting.initial_prompt
        }]

        # Ask LLM to generate an introduction
        conversation.append({
            "role": "user",
            "content": "Please write an introduction for this lupus in fabula game."
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        introduction = response.choices[0].message.content

        # Broadcast the story to all players
        notify_narrator_story(game_id, "all", "introduction", introduction)

    @staticmethod
    def gen_night_intro(game: Game, setting: Setting):
        """
        Generate introduction to night phase.
        """

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        # Ask LLM to generate the message
        conversation.append({
            "role": "user",
            "content": "Write an introduction to the night phase of the game",
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        message = response.choices[0].message.content

        # Broadcast story to all players
        notify_narrator_story(game.id, "all", "nightIntro", message)

    @staticmethod
    def gen_role_action_message(game: Game, setting: Setting, role: str):
        """
        Generate the message that confirms the role turn.
        """

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        role_name = setting.alternative_role_names[role]

        # Ask LLM to generate the message
        conversation.append({
            "role": "user",
            "content": "Write a short paragraph of no more than 50 words to tell that now is " + role_name + "'s turn",
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        message = response.choices[0].message.content

        # Broadcast story to all players
        notify_narrator_story(game.id, "all", "roleAction", message)

    @staticmethod
    def gen_night_report(game: Game, setting: Setting, killed_players: list[str]):
        """
        Generate the final report for the current night
        """

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        #evil_role_name = setting.alternative_role_names["wolf"]

        # Ask LLM to generate the report
        conversation.append({
            "role": "user",
            "content": 
                f"""
                Write a nighttime report for a Lupus in Fabula session. The report must be written as a short narrative told by an elderly storyteller—wise, dramatic, and a bit cryptic, as if speaking by firelight.
                Describe the night's events in a poetic, atmospheric way, but without breaking game secrecy; never reveal hidden roles unless they are meant to be known.
                Include:

                The mood of the village as night falls

                Actions that occurred during the night (e.g., attacks, protections, visions) expressed metaphorically or suggestively

                Any outcomes that should be revealed to the players at dawn (e.g., who died, what was discovered)

                Subtle foreshadowing or hints, but no direct spoilers

                Keep the style evocative, full of imagery, reminiscent of a seasoned narrator spinning a tale from memory. The ending should transition naturally into the new day for the players. 
                The players who died during the night are: {killed_players}               
                """
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        message = response.choices[0].message.content

        # Broadcast story to all players
        notify_narrator_story(game.id, "all", "nightReport", message)

    @staticmethod
    def gen_lynch_story(game: Game, setting: Setting, voted_player: str, lynch_success: bool):
        """
        Generate the piece of story for the lynch phase
        """

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        conversation.append({
            "role": "user",
            "content":
                f"""
                    Write a narrative for the lynch phase of a *Lupus in Fabula* game, spoken by an
                    elderly storyteller who recounts the events as if by the glow of a fading sunset.
                    The tone should be solemn, atmospheric, and tinged with the weight of judgment.

                    Describe the village gathering after the day's debates and suspicions, using
                    vivid imagery and metaphoric hints, without revealing any hidden roles.

                    The following information should be included:
                    - Player with most votes: {voted_player}
                    - Whether the lynch is successful: {lynch_success}  # values: True or False
                    - If successful, name of the lynched player: {voted_player}
                    - If no lynch occurs, a sentence explaining why

                    The narration must naturally adapt:
                    - If {lynch_success} is True:
                        The storyteller should describe how the villagers, heavy-hearted or vengeful,
                        carry out the lynching of {voted_player}. The tone may reflect doubt,
                        righteousness, or unease.
                    - If {lynch_success} is False:
                        The storyteller should describe how confusion, conflicting votes, or fear
                        prevent the villagers from condemning anyone. No one is executed.

                    Do not reveal secret roles.
                    Close the narration with a smooth transition into the coming night.
                """
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        message = response.choices[0].message.content

        # Broadcast story to all players
        notify_narrator_story(game.id, "all", "lynch", message)

    @staticmethod
    def gen_story_end(game: Game, setting: Setting, winners: list[str], reason: str):
        """
        Generate the conclusion of the story
        """

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        conversation.append({
            "role": "user",
            "content": 
                f"""
                Write a closing tale for a game of *Lupus in Fabula*, narrated by an elderly storyteller
                who speaks as if by the last embers of a village fire. The tone should be wise, poetic,
                a little cryptic, and filled with the weight of the story's end.

                The narrator must reveal who won the game. Use atmospheric storytelling, metaphors, and evocative imagery.

                Insert the following details into the tale:
                - Winner: {winners}
                - Reason for victory: {reason}
                - Summary of the final state (optional)

                The possible win conditions are:
                - Wolves win if the number of wolves is greater than or equal to the number of villagers.
                - Villagers win if they eliminate all wolves.
                - The Madman wins only if he is lynched by the village after the day discussion.

                Write the narration as if the storyteller has witnessed the entire saga.
                End with a sense of closure—quiet, solemn, or triumphant depending on the winner.
            """
        })
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )

        message = response.choices[0].message.content

        # Broadcast story to all players
        notify_narrator_story(game.id, "all", "endGame", message)

        