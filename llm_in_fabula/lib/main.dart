import 'package:flutter/material.dart';
import 'package:llm_in_fabula/routers/app_router.dart';
import 'package:provider/provider.dart';
import 'models/state.dart';
import 'models/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load icon registry first, then themes that reference icon names
  await GameThemes.loadIconMapFromJson('assets/icons.json');
  await GameThemes.loadThemesFromJson('assets/themes.json');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const MyApp(),
    )
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLM in Fabula',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const AppRouter(),
    );
  }
}
