import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/aryans_surfer_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AryansSurferApp());
}

class AryansSurferApp extends StatelessWidget {
  const AryansSurferApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = AryansSurferGame();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Aryan's Surfer",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'HUD': (context, game) => game.hud,
            'Pause': (context, game) => game.pauseOverlay,
            'GameOver': (context, game) => game.gameOverOverlay,
          },
          initialActiveOverlays: const ['HUD'],
        ),
      ),
    );
  }
}
