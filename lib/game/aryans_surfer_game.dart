import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../components/obstacle.dart';
import '../components/coin.dart';

class AryansSurferGame extends FlameGame with HasCollisionDetection, PanDetector, TapDetector, HasGameRef<AryansSurferGame> {
  late Player player;
  final Random _rng = Random();

  // World config
  final double laneGap = 120; // distance between lanes
  final List<int> lanes = [-1, 0, 1]; // 3 lanes
  double gameSpeed = 240; // pixels per second base
  double difficultyTimer = 0;

  // UI overlays
  late Widget hud;
  late Widget pauseOverlay;
  late Widget gameOverOverlay;

  // Score
  int score = 0;
  double _scoreTimer = 0;
  int best = 0;
  bool pausedByOverlay = false;
  bool isGameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(Vector2(720, 1280));

    // Parallax background
    add(
      ParallaxComponent(
        parallax: await loadParallax([
          ParallaxImageData(''),
        ], baseVelocity: Vector2(0, -30), velocityMultiplierDelta: Vector2(0, 1.2)),
      ),
    );

    // Create player centered in middle lane near bottom
    player = Player(
      lanes: lanes,
      laneGap: laneGap,
      y: size.y - 220,
    );
    add(player);

    // Pre-spawn some coins to feel alive
    for (var i = 0; i < 6; i++) {
      spawnCoin(yOffset: 300.0 * i + 800);
    }

    // Build overlays widgets
    hud = _buildHUD();
    pauseOverlay = _buildPauseOverlay();
    gameOverOverlay = _buildGameOverOverlay();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    if (paused) return;

    // Increase difficulty gradually
    difficultyTimer += dt;
    if (difficultyTimer > 5) {
      difficultyTimer = 0;
      gameSpeed += 20;
    }

    // Score increases over time
    _scoreTimer += dt;
    if (_scoreTimer > 0.1) {
      _scoreTimer = 0;
      score += 1;
      overlays.notifyListeners();
    }

    // Spawn obstacles and coins
    if (children.query<Obstacle>().length < 4 && _rng.nextDouble() < 0.03) {
      spawnObstacle();
    }
    if (children.query<Coin>().length < 8 && _rng.nextDouble() < 0.05) {
      spawnCoin();
    }
  }

  void spawnObstacle() {
    final lane = lanes[_rng.nextInt(lanes.length)];
    final y = -100.0; // starts off screen at the top
    add(Obstacle(
      lane: lane,
      laneGap: laneGap,
      startY: y,
      speed: gameSpeed + _rng.nextDouble() * 80,
      width: 70 + _rng.nextDouble() * 30,
      height: 70 + _rng.nextDouble() * 60,
      color: Colors.primaries[_rng.nextInt(Colors.primaries.length)],
    ));
  }

  void spawnCoin({double? yOffset}) {
    final lane = lanes[_rng.nextInt(lanes.length)];
    final y = (yOffset ?? 0) - _rng.nextDouble() * 800 - 100;
    add(Coin(
      lane: lane,
      laneGap: laneGap,
      startY: y,
      speed: gameSpeed * 0.9,
    ));
  }

  // Input: swipes (left/right to change lane, up to jump, down to slide)
  Vector2? _dragStart;
  @override
  void onPanStart(DragStartInfo info) {
    _dragStart = info.eventPosition.global;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (_dragStart == null) return;
    final end = info.velocity;
    final vx = end.x;
    final vy = end.y;
    if (vx.abs() > vy.abs()) {
      if (vx > 0) {
        player.moveRight();
      } else {
        player.moveLeft();
      }
    } else {
      if (vy > 0) {
        player.slide();
      } else {
        player.jump();
      }
    }
    _dragStart = null;
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Single tap to jump (simple control on desktop)
    player.jump();
  }

  void pauseGame() {
    pausedByOverlay = true;
    pauseEngine();
    overlays.add('Pause');
  }

  void resumeGame() {
    overlays.remove('Pause');
    pausedByOverlay = false;
    resumeEngine();
  }

  void endGame() {
    isGameOver = true;
    best = max(best, score);
    overlays.add('GameOver');
    pauseEngine();
  }

  void restart() {
    // Reset state
    score = 0;
    gameSpeed = 240;
    difficultyTimer = 0;
    isGameOver = false;
    _scoreTimer = 0;

    // Remove entities
    children.whereType<Obstacle>().forEach((o) => o.removeFromParent());
    children.whereType<Coin>().forEach((c) => c.removeFromParent());

    // Reset player
    player.reset();

    // Resume
    overlays.remove('GameOver');
    resumeEngine();
  }

  // ---------- UI Builders (Flutter widgets as overlays) ----------
  Widget _buildHUD() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chip(text: "Score: $score"),
              Row(
                children: [
                  _Chip(text: "Best: $best"),
                  const SizedBox(width: 8),
                  _RoundButton(icon: Icons.pause, onPressed: pauseGame),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Paused", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(onPressed: resumeGame, child: const Text("Resume")),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: restart, child: const Text("Restart")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Game Over", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Score: $score", style: const TextStyle(color: Colors.white, fontSize: 20)),
            Text("Best: $best", style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(onPressed: restart, child: const Text("Play Again")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _RoundButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Icon(icon),
      ),
    );
  }
}
