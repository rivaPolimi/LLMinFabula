import logging
from .redis import redis_client
from ..models import Game
from django.shortcuts import get_object_or_404
from channels.db import database_sync_to_async
import time

logger = logging.getLogger("redis_events")

def start_phase_timer(game_id, phase_name: str, duration: int):
    """
    Starts asynchronous timer for phase to expire
    """
    
    key = f"phase:{phase_name}_{game_id}"

    # Set expiration in Redis
    expiry_time = int(time.time()) + duration
    redis_client.expireat(key, expiry_time)

    logger.info("Starting phase timer: game_id=%s phase=%s duration=%ss", game_id, phase_name, duration, extra={'game_id': game_id, 'phase': phase_name})

async def end_phase(key: str, game_id: int):
    game = await database_sync_to_async(get_object_or_404)(Game, id=game_id)

    phase = game.state
    if phase != key:
        logger.info("Ignoring phase expiry: game_id=%s expected=%s actual=%s", game_id, key, phase)
        return
    
    from ..engine import GameEngine

    if key == "introduction":
        logger.info("Phase expired: introduction -> roleReveal (game_id=%s)", game_id)
        GameEngine.role_reveal(game)
    if key == "roleReveal":
        logger.info("Phase expired: roleReveal -> nightIntro (game_id=%s)", game_id)
        GameEngine.night_intro(game)
    if key == "nightIntro":
        logger.info("Phase expired: nightIntro -> handleNight (game_id=%s)", game_id)
        GameEngine.handle_night(game)
    if key == "nightReport":
        logger.info("Phase expired: nightReport -> checkWin (game_id=%s)", game_id)
        GameEngine.check_win_engine(game, "nightReport")
    if key == "lynchOutcome":
        logger.info("Phase expired: lynchOutcome -> checkWin (game_id=%s)", game_id)
        GameEngine.check_win_engine(game, "lynchOutcome")