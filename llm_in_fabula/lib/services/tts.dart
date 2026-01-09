import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Tts {
  FlutterTts flutterTts = FlutterTts();
  

  Future<void> configureTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
  }

  Future<void> speakText(String text, {VoidCallback? onComplete,}) async {
    flutterTts.setCompletionHandler(() {
      onComplete?.call();
    });
    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking(String text) async {
    await flutterTts.stop();
  }
}