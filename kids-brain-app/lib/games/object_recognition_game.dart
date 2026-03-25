import 'package:flutter/material.dart';
import 'dart:math';

class ObjectRecognitionGame extends StatefulWidget {
  const ObjectRecognitionGame({super.key});

  @override
  State<ObjectRecognitionGame> createState() => _ObjectRecognitionGameState();
}

class _ObjectRecognitionGameState extends State<ObjectRecognitionGame> {
  static final List<Map<String, String>> _items = [
    {'emoji': '🐶', 'name': '小狗'},
    {'emoji': '🐱', 'name': '小猫'},
    {'emoji': '🐰', 'name': '兔子'},
    {'emoji': '🐼', 'name': '熊猫'},
    {'emoji': '🐸', 'name': '青蛙'},
    {'emoji': '🦁', 'name': '狮子'},
    {'emoji': '🐯', 'name': '老虎'},
    {'emoji': '🐘', 'name': '大象'},
    {'emoji': '🦒', 'name': '长颈鹿'},
    {'emoji': '🦓', 'name': '斑马'},
  ];

  final Random _random = Random();
  int _currentIndex = 0;
  List<String> _options = [];
  int _score = 0;
  int _questionNum = 0;
  bool _answered = false;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    _currentIndex = _random.nextInt(_items.length);
    _options = [];
    
    // Generate 4 options including the correct answer
    final correctName = _items[_currentIndex]['name']!;
    _options.add(correctName);
    
    final indices = <int>{_currentIndex};
    while (_options.length < 4) {
      final idx = _random.nextInt(_items.length);
      if (!indices.contains(idx)) {
        indices.add(idx);
        _options.add(_items[idx]['name']!);
      }
    }
    
    _options.shuffle();
    _answered = false;
    _correct = false;
    _questionNum++;
  }

  void _checkAnswer(String selected) {
    if (_answered) return;
    final correctName = _items[_currentIndex]['name']!;
    setState(() {
      _answered = true;
      _correct = selected == correctName;
      if (_correct) _score++;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_questionNum >= 10) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('🎉 答题结束', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
            content: Text(
              '答对了 $_score/10 题\n${_score >= 7 ? '你真棒！🌟' : _score >= 4 ? '继续加油！💪' : '再练练吧！😊'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() { _score = 0; _questionNum = 0; _generateQuestion(); });
                },
                child: const Text('再来一轮', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      } else {
        setState(() => _generateQuestion());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        title: const Text('🏝️ 语言岛', style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFFDDA0DD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('得分: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                Text('第 $_questionNum/10 题', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('这是什么动物？', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Animal display
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: Text(currentItem['emoji']!, style: const TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 16),
            if (_answered)
              Text(
                _correct ? '✅ 对了！这是${currentItem['name']}' : '❌ 这是${currentItem['name']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _correct ? Colors.green : Colors.red),
              ),
            const Spacer(),
            // Options
            Column(
              children: _options.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _checkAnswer(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _answered && opt == currentItem['name']
                            ? Colors.green[100]
                            : _answered && opt != currentItem['name']
                                ? Colors.red[50]
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _answered && opt == currentItem['name']
                              ? Colors.green
                              : _answered && opt != currentItem['name']
                                  ? Colors.red
                                  : const Color(0xFFDDA0DD),
                          width: 3,
                        ),
                        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _answered && opt == currentItem['name']
                                ? Colors.green
                                : _answered && opt != currentItem['name']
                                    ? Colors.red
                                    : const Color(0xFFDDA0DD),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
