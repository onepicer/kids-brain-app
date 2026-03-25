import 'package:flutter/material.dart';
import 'dart:math';
import '../games/memory_game.dart';
import '../games/math_count_game.dart';
import '../games/pattern_game.dart';
import '../games/maze_game.dart';
import '../games/object_recognition_game.dart';
import '../games/find_diff_game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late List<AnimationController> _floatControllers;
  late AnimationController _cloudController;
  final List<ModuleInfo> _modules = [];

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _modules.addAll([
      const ModuleInfo(
        name: '逻辑乐园',
        emoji: '🧩',
        color: Color(0xFFFF6B6B),
        desc: '找规律、配对、分类',
        screen: PatternGame(),
      ),
      const ModuleInfo(
        name: '记忆城堡',
        emoji: '🏰',
        color: Color(0xFF4ECDC4),
        desc: '翻牌记忆游戏',
        screen: MemoryGame(),
      ),
      const ModuleInfo(
        name: '数学王国',
        emoji: '👑',
        color: Color(0xFFFFE66D),
        desc: '数数、比大小',
        screen: MathCountGame(),
      ),
      const ModuleInfo(
        name: '空间迷宫',
        emoji: '🌀',
        color: Color(0xFFA8E6CF),
        desc: '走迷宫、拼图',
        screen: MazeGame(),
      ),
      const ModuleInfo(
        name: '语言岛',
        emoji: '🏝️',
        color: Color(0xFFDDA0DD),
        desc: '看图认物',
        screen: ObjectRecognitionGame(),
      ),
      const ModuleInfo(
        name: '专注力森林',
        emoji: '🌳',
        color: Color(0xFF87CEEB),
        desc: '找不同',
        screen: FindDiffGame(),
      ),
    ]);

    _floatControllers = List.generate(
      _modules.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + i * 300),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    _cloudController.dispose();
    for (final c in _floatControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA), Color(0xFFA8E6CF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated clouds
              ...List.generate(5, (i) {
                final top = 20.0 + i * 60.0;
                final size = 30.0 + Random(i).nextDouble() * 40;
                return AnimatedBuilder(
                  animation: _cloudController,
                  builder: (context, child) {
                    final dx = (MediaQuery.of(context).size.width + 200) *
                        _cloudController.value -
                        100;
                    return Positioned(
                      left: dx,
                      top: top,
                      child: Opacity(
                        opacity: 0.5 + Random(i).nextDouble() * 0.3,
                        child: Text(
                          '☁️',
                          style: TextStyle(fontSize: size),
                        ),
                      ),
                    );
                  },
                );
              }),
              // Title
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🧠 奇妙大脑岛 🏝️',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ),
              ),
              // Module grid
              Padding(
                padding: const EdgeInsets.only(top: 90, bottom: 20),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    return _buildModuleCard(context, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, int index) {
    final module = _modules[index];
    return AnimatedBuilder(
      animation: _floatControllers[index],
      builder: (context, child) {
        final offset = sin(_floatControllers[index].value * pi) * 5;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => module.screen),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: module.color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    module.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                module.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: module.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                module.desc,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleInfo {
  final String name;
  final String emoji;
  final Color color;
  final String desc;
  final Widget screen;

  const ModuleInfo({
    required this.name,
    required this.emoji,
    required this.color,
    required this.desc,
    required this.screen,
  });
}
