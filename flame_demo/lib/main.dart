import 'dart:math';

import 'package:flame/camera.dart' show FixedResolutionViewport;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // 用 GameWidget 包裹，启动 Flame 游戏
  runApp(GameWidget(game: AvoidAsteroidsGame()));
}

// 创建主游戏类，继承 FlameGame
// with HasCollisionDetection => 可以检测碰撞
// with HasKeyboardHandlerComponents => 可以监听键盘输入
class AvoidAsteroidsGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player; // 玩家对象
  late TimerComponent spawnTimer; // 定时生成陨石
  late TextComponent scoreText; // 保存分数字
  Random random = Random(); // 随机数生成器
  int score = 0; // 分数
  bool isGameOver = false; // 游戏结束标志

  @override
  Future<void> onLoad() async {
    // 设置固定分辨率（400x600），不同手机上保持一致视觉
    camera.viewport = FixedResolutionViewport(resolution: Vector2(400, 600));

    // 创建玩家，初始位置在底部中间
    player = Player()
      ..position = Vector2(200, 500)
      ..anchor = Anchor.center;
    add(player);

    // 创建定时器，每1秒生成一个陨石
    spawnTimer = TimerComponent(
      period: 1, // 每秒触发
      repeat: true, // 无限循环
      onTick: () {
        // 在随机 x 坐标位置生成一个陨石
        add(Asteroid(position: Vector2(random.nextDouble() * 400, -50)));
      },
    );
    add(spawnTimer);

    // 添加分数字
    scoreText = TextComponent(
      text: "Score: 0",
      position: Vector2(10, 10),
      anchor: Anchor.topLeft,
      priority: 10,
    );
    add(scoreText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameOver) {
      score += (60 * dt).toInt();
      scoreText.text = "Score: $score";
    }
  }

  void gameOver() {
    isGameOver = true;
    pauseEngine();
    add(
      TextComponent(
        text: "Game Over",
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        priority: 20,
      ),
    );
  }
}

class Player extends SpriteComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<AvoidAsteroidsGame> {
  double speed = 200;
  int moveDir = 0; // -1 左，1 右，0 停

  Player() : super(size: Vector2(50, 50));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('me1.png');
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * moveDir * dt;
    position.x = position.x.clamp(25, 375);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // 用 KeyEvent 和 LogicalKeyboardKey
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      moveDir = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      moveDir = 1;
    } else {
      moveDir = 0;
    }
    return true;
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is Asteroid && !gameRef.isGameOver) {
      gameRef.gameOver();
    }
    super.onCollision(points, other);
  }
}

// 陨石类
class Asteroid extends SpriteComponent with CollisionCallbacks {
  double speed = 100; // 每秒下落速度

  Asteroid({required Vector2 position})
    : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('enemy1.png'); // 加载陨石图像
    add(RectangleHitbox()); // 加矩形碰撞盒
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt; // 每帧往下移动

    // 如果掉出屏幕底部就删除
    if (position.y > 650) {
      removeFromParent();
    }
  }
}
