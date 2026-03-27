import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/base_game_screen.dart';
import '../services/tts_service.dart';

class ObjectRecognitionGame extends BaseGameScreen {
  const ObjectRecognitionGame({super.key})
    : super(
        title: '语言岛',
        emoji: '🏝️',
        themeColor: const Color(0xFFDDA0DD),
      );

  @override
  State<ObjectRecognitionGame> createState() => _ObjectRecognitionGameState();
}

class _ObjectRecognitionGameState extends BaseGameState<ObjectRecognitionGame> {
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

  @override
  String get questionText => '这是什么动物？';
  
  @override
  String? get correctAnswerText => _items[_currentIndex]['name'];

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  @override
  void generateQuestion() {
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
    
    setState(() {
      answered = false;
      correct = false;
      questionNum++;
    });
    
    // 朗读题目
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuestionWithAnimal();
    });
  }
  
  Future<void> _speakQuestionWithAnimal() async {
    final tts = TtsService();
    final animalName = _items[_currentIndex]['name']!;
    await tts.speak('这是什么动物？');
  }

  @override
  void checkAnswer(dynamic selected) {
    if (answered) return;
    final selectedName = selected as String;
    final correctName = _items[_currentIndex]['name']!;
    
    setState(() {
      answered = true;
      correct = selectedName == correctName;
      if (correct) score++;
    });
    
    // 播放反馈语音
    final tts = TtsService();
    if (correct) {
      tts.speak('答对了！这是$correctName！');
    } else {
      tts.speak('不对哦，这是$correctName！');
    }
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (questionNum >= 10) {
        showResult();
      } else {
        generateQuestion();
      }
    });
  }

  @override
  Widget buildQuestionContent() {
    final currentItem = _items[_currentIndex];
    final boxSize = isTV ? 280.0 : 150.0;
    final emojiSize = isTV ? 180.0 : 100.0;
    
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTV ? 60 : 30),
        boxShadow: [BoxShadow(
          color: widget.themeColor.withOpacity(0.3), 
          blurRadius: isTV ? 30 : 15, 
          offset: Offset(0, isTV ? 10 : 5)
        )],
      ),
      child: Center(
        child: Text(currentItem['emoji']!, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }

  @override
  Widget buildOptions() {
    final currentItem = _items[_currentIndex];
    
    if (isTV && MediaQuery.of(context).size.width > MediaQuery.of(context).size.height) {
      // TV 横屏：垂直排列大按钮
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _options.map((opt) {
          final isSelected = answered && opt == currentItem['name'];
          final isWrong = answered && opt != currentItem['name'];
          return TVButton(
            text: opt,
            onPressed: () => checkAnswer(opt),
            primaryColor: widget.themeColor,
            isSelected: isSelected,
            isWrong: isWrong,
          );
        }).toList(),
      );
    }
    
    // 普通布局
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _options.map((opt) {
        final isSelected = answered && opt == currentItem['name'];
        final isWrong = answered && opt != currentItem['name'];
        return Padding(
          padding: EdgeInsets.only(bottom: isTV ? 20 : 12),
          child: GestureDetector(
            onTap: () => checkAnswer(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isTV ? 24 : 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green[100]
                    : isWrong
                        ? Colors.red[50]
                        : Colors.white,
                borderRadius: BorderRadius.circular(isTV ? 30 : 16),
                border: Border.all(
                  color: isSelected
                      ? Colors.green
                      : isWrong
                          ? Colors.red
                          : widget.themeColor,
                  width: isTV ? 5 : 3,
                ),
                boxShadow: [BoxShadow(
                  color: widget.themeColor.withOpacity(0.1), 
                  blurRadius: isTV ? 16 : 8, 
                  offset: Offset(0, isTV ? 6 : 3)
                )],
              ),
              child: Center(
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: isTV ? 48 : 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.green
                        : isWrong
                            ? Colors.red
                            : widget.themeColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
