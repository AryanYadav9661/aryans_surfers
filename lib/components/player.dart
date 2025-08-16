import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/aryans_surfer_game.dart';

class Player extends PositionComponent with HasGameRef<AryansSurferGame>, CollisionCallbacks {
  final List<int> lanes;
  final double laneGap;
  final double baseY;
  int currentLane = 0;

  // Physics
  double vy = 0;
  double gravity = 900;
  bool isOnGround = true;
  bool isSliding = false;
  double slideTimer = 0;

  // Visual
  late RectangleComponent body;
  late RectangleComponent shadow;

  Player({required this.lanes, required this.laneGap, required double y})
      : baseY = y,
        super(priority: 10);

  @override
  Future<void> onLoad() async {
    size = Vector2(80, 120);
    position = Vector2(gameRef.size.x / 2, baseY);
    anchor = Anchor.center;

    shadow = RectangleComponent(
      position: Vector2(0, size.y / 2 + 16),
      anchor: Anchor.center,
      size: Vector2(size.x * 0.7, 12),
      paint: Paint()..color = Colors.black.withOpacity(0.2),
    );
    add(shadow);

    body = RectangleComponent(
      size: size,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.deepPurpleAccent,
      children: [
        RectangleHitbox(), // collision
      ],
    );
    add(body);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Gravity
    vy += gravity * dt;
    y += vy * dt;

    // Ground collision
    final groundY = baseY;
    if (y > groundY) {
      y = groundY;
      vy = 0;
      isOnGround = true;
    } else {
      isOnGround = false;
    }

    // Sliding timer
    if (isSliding) {
      slideTimer -= dt;
      if (slideTimer <= 0) {
        isSliding = false;
        body.size = Vector2(80, 120);
      }
    }

    // Lerp towards lane target
    final targetX = gameRef.size.x / 2 + currentLane * laneGap;
    x += (targetX - x) * 10 * dt;

    // Shadow squish based on height
    final h = (groundY - y).abs();
    final k = (1 - (h / 240)).clamp(0.5, 1.0);
    shadow.size = Vector2(56 * k, 12 * k);
    shadow.position = Vector2(0, size.y / 2 + 16);
  }

  void moveLeft() {
    final next = currentLane - 1;
    if (lanes.contains(next)) currentLane = next;
  }

  void moveRight() {
    final next = currentLane + 1;
    if (lanes.contains(next)) currentLane = next;
  }

  void jump() {
    if (isOnGround) {
      vy = -520;
    }
  }

  void slide() {
    if (isOnGround && !isSliding) {
      isSliding = true;
      slideTimer = 0.7;
      body.size = Vector2(80, 70);
    }
  }

  void reset() {
    position = Vector2(gameRef.size.x / 2, baseY);
    vy = 0;
    currentLane = 0;
    isSliding = false;
    body.size = Vector2(80, 120);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is Obstacle) {
      gameRef.endGame();
    } else if (other is Coin) {
      other.collect();
      gameRef.score += 5;
    }
    super.onCollision(points, other);
  }
}

class Obstacle extends RectangleComponent with CollisionCallbacks, HasGameRef<AryansSurferGame> {
  final int lane;
  final double laneGap;
  final double startY;
  final double speed;
  Obstacle({
    required this.lane,
    required this.laneGap,
    required this.startY,
    required this.speed,
    double width = 80,
    double height = 80,
    Color color = Colors.red,
  }) : super(
          position: Vector2.zero(),
          size: Vector2(width, height),
          anchor: Anchor.center,
          paint: Paint()..color = color,
          priority: 5,
          children: [RectangleHitbox()],
        );

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2 + lane * laneGap, startY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += speed * dt;
    if (y - height > gameRef.size.y) {
      removeFromParent();
    }
  }
}

class Coin extends CircleComponent with CollisionCallbacks, HasGameRef<AryansSurferGame> {
  final int lane;
  final double laneGap;
  final double startY;
  final double speed;
  bool _collected = false;

  Coin({required this.lane, required this.laneGap, required this.startY, required this.speed})
      : super(
          radius: 20,
          anchor: Anchor.center,
          paint: Paint()..color = Colors.amber,
          priority: 6,
          children: [CircleHitbox()],
        );

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2 + lane * laneGap, startY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += speed * dt;
    if (y - radius > gameRef.size.y) {
      removeFromParent();
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    // Simple pop animation
    add(ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.15), onComplete: () {
      removeFromParent();
    }));
  }
}
