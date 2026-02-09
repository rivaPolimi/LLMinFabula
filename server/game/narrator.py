import os
import logging
import time
from .models import *
from .utils import *
from .notifications import notify_narrator_story
from openai import AzureOpenAI
from openai import APITimeoutError, APIConnectionError

logger = logging.getLogger(__name__)

class Narrator:

    @staticmethod
    def get_deployment_name():
        return os.environ.get("AZURE_DEPLOYMENT_NAME")

    @staticmethod
    def get_openai_client():
        return AzureOpenAI(
            azure_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT"),
            api_key=os.environ.get("AZURE_OPENAI_KEY"),
            api_version=os.environ.get("AZURE_DEPLOYMENT_MODEL"),
            timeout=60.0,  # 60 second timeout
            max_retries=2  # Retry up to 2 times on timeout
        )

    @staticmethod
    def gen_introduction(game_id: int, setting: Setting):
        """
        Generate introduction for the game based on the setting provided by the user
        """
        start_time = time.time()
        logger.info(f"[Game {game_id}] Starting introduction generation")

        client = Narrator.get_openai_client()
        logger.debug(f"[Game {game_id}] OpenAI client initialized")

        # Set the background prompt for the LLM.
        conversation = [{
            "role": "system", 
            "content": setting.initial_prompt
        }]

        # Ask LLM to generate an introduction
        conversation.append({
            "role": "user",
            "content": "Please write an introduction for this Lupus in Fabula game."
        })
        
        logger.debug(f"[Game {game_id}] Sending request to Azure OpenAI for introduction")
        api_start = time.time()
        try:
            response = client.chat.completions.create(
                model=Narrator.get_deployment_name(),
                messages=conversation
            )
        except (APITimeoutError, APIConnectionError) as e:
            logger.error(f"[Game {game_id}] Azure OpenAI timeout/connection error: {str(e)}")
            # Send a default introduction if LLM fails
            introduction = "The storyteller begins the tale of Lupus in Fabula. The roles have been assigned. Let the game begin..."
            notify_narrator_story(game_id, "all", "introduction", introduction)
            total_duration = time.time() - start_time
            logger.warning(f"[Game {game_id}] Using fallback introduction due to API error")
            return
        api_duration = time.time() - api_start
        logger.info(f"[Game {game_id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        introduction = response.choices[0].message.content
        logger.debug(f"[Game {game_id}] Introduction generated: {len(introduction)} characters")

        # Broadcast the story to all players
        notify_start = time.time()
        notify_narrator_story(game_id, "all", "introduction", introduction)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game_id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game_id}] Introduction generation completed in {total_duration:.2f}s (API: {api_duration:.2f}s, Notify: {notify_duration:.2f}s)")

    @staticmethod
    def gen_night_intro(game: Game, setting: Setting):
        """
        Generate introduction to night phase.
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting night intro generation")

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        # Ask LLM to generate the message
        conversation.append({
            "role": "user",
            "content": "Write a short introduction (max 45 seconds) to the night phase of the game",
        })
        
        logger.debug(f"[Game {game.id}] Sending request to Azure OpenAI for night intro")
        api_start = time.time()
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )
        api_duration = time.time() - api_start
        logger.info(f"[Game {game.id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        message = response.choices[0].message.content
        logger.debug(f"[Game {game.id}] Night intro generated: {len(message)} characters")

        # Broadcast story to all players
        notify_start = time.time()
        notify_narrator_story(game.id, "all", "nightIntro", message)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game.id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] Night intro generation completed in {total_duration:.2f}s")

    @staticmethod
    def gen_role_action_message(game: Game, setting: Setting, role: str):
        """
        Generate the message that confirms the role turn.
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting role action message generation for role: {role}")

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        role_name = setting.alternative_role_names[role] if role != "courtesan" else "ladylove"

        # Ask LLM to generate the message
        conversation.append({
            "role": "user",
            "content": "Write a short paragraph of no more than 40 words to tell that now is " + role_name + "'s turn." +
                "You should add the exact name of the role in the message, maintain a plain text format without '*'",
        })
        
        logger.debug(f"[Game {game.id}] Sending request to Azure OpenAI for role action message")
        api_start = time.time()
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )
        api_duration = time.time() - api_start
        logger.info(f"[Game {game.id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        message = response.choices[0].message.content

        # To avoid Azure restrictions we use "ladylove" instead of "courtesan" (or similar)
        if role == "courtesan":
            message = message.replace("ladylove", setting.alternative_role_names[role])
            message = message.replace("Ladylove", setting.alternative_role_names[role])

        # Broadcast story to all players
        notify_start = time.time()
        notify_narrator_story(game.id, "all", "roleAction", message)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game.id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] Role action message generation completed in {total_duration:.2f}s")

    @staticmethod
    def gen_night_report(game: Game, setting: Setting, killed_players: list[str]):
        """
        Generate the final report for the current night
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting night report generation for killed players: {killed_players}")

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
                The players who died during the night are: {killed_players if killed_players else "nobody"}               
                """
        })
        
        logger.debug(f"[Game {game.id}] Sending request to Azure OpenAI for night report")
        api_start = time.time()
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )
        api_duration = time.time() - api_start
        logger.info(f"[Game {game.id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        message = response.choices[0].message.content
        logger.debug(f"[Game {game.id}] Night report generated: {len(message)} characters")

        # Broadcast story to all players
        notify_start = time.time()
        notify_narrator_story(game.id, "all", "nightReport", message)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game.id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] Night report generation completed in {total_duration:.2f}s")

    @staticmethod
    def gen_lynch_story(game: Game, setting: Setting, voted_player: str, lynch_success: bool):
        """
        Generate the piece of story for the lynch phase
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting lynch story generation for player: {voted_player}, success: {lynch_success}")

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        conversation.append({
            "role": "user",
            "content":
                f"""
                    Write a short narrative of max 100 words for the lynch phase of a Lupus in Fabula game, spoken by an
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
                """
        })
        
        logger.debug(f"[Game {game.id}] Sending request to Azure OpenAI for lynch story")
        api_start = time.time()
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )
        api_duration = time.time() - api_start
        logger.info(f"[Game {game.id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        message = response.choices[0].message.content
        logger.debug(f"[Game {game.id}] Lynch story generated: {len(message)} characters")

        # Broadcast story to all players
        notify_start = time.time()
        notify_narrator_story(game.id, "all", "lynch", message)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game.id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] Lynch story generation completed in {total_duration:.2f}s")

    @staticmethod
    def gen_story_end(game: Game, setting: Setting, winners: list[str], reason: str):
        """
        Generate the conclusion of the story
        """
        start_time = time.time()
        logger.info(f"[Game {game.id}] Starting end story generation for winners: {winners}, reason: {reason}")

        client = Narrator.get_openai_client()

        conversation = [{
            "role": "system",
            "content": setting.initial_prompt,
        }]

        conversation.append({
            "role": "user",
            "content": 
                f"""
                Write a closing tale for a game of Lupus in Fabula, narrated by an elderly storyteller
                who speaks as if by the last embers of a village fire. The tone should be wise, poetic,
                a little cryptic, and filled with the weight of the story's end.

                The narrator must reveal who won the game. Use atmospheric storytelling, and evocative imagery.

                Insert the following details into the tale:
                - Winner: {winners}
                - Reason for victory: {reason}
                - Summary of the final state (optional)

                The possible win conditions are:
                - Wolves win if the number of wolves is greater than or equal to the number of villagers.
                - Villagers win if they eliminate all wolves.
                - The Madman wins only if he is lynched by the village after the day discussion.

                Write the narration as if the storyteller has witnessed the entire saga.
                End with a sense of closure—quiet (wolves won), solemn (villagers won), or funny (Madman won) depending on the winner.
            """
        })
        
        logger.debug(f"[Game {game.id}] Sending request to Azure OpenAI for end story")
        api_start = time.time()
        response = client.chat.completions.create(
            model=Narrator.get_deployment_name(),
            messages=conversation
        )
        api_duration = time.time() - api_start
        logger.info(f"[Game {game.id}] Azure OpenAI API call completed in {api_duration:.2f}s")

        message = response.choices[0].message.content
        logger.debug(f"[Game {game.id}] End story generated: {len(message)} characters")

        # Broadcast story to all players
        notify_start = time.time()
        notify_narrator_story(game.id, "all", "endGame", message)
        notify_duration = time.time() - notify_start
        logger.debug(f"[Game {game.id}] Broadcast notification sent in {notify_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"[Game {game.id}] End story generation completed in {total_duration:.2f}s")

        