import 'package:flutter/material.dart';
import 'screens/play_screen.dart';

void main() {
  runApp(const MyApp());
}

// APP + TEMA BASE

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLM in Fabula',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto', // poi lo cambi col font che hai importato
        useMaterial3: true,
      ),
      home: const PlayScreen(),
    );
  }
}
