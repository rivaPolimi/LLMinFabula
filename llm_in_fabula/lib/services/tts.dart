import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState{playing, stopped}

class Tts {
  FlutterTts flutterTts = FlutterTts();
  TtsState state = TtsState.stopped;
  

  Future<void> configureTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setVoice({'name': 'en-us-x-iol-local', 'locale': 'en-US'});
  }

  Future<void> speakText(String text, {VoidCallback? onComplete,}) async {
    state = TtsState.playing;
    flutterTts.setCompletionHandler(() {
      onComplete?.call();
    });
    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    state = TtsState.stopped;
  }
}