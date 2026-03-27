import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/base_game_screen.dart';
import '../services/tts_service.dart';

class MathCountGame extends BaseGameScreen {
  const MathCountGame({super.key}) 
    : super(
        title: '数学王国',
        emoji: '👑',
        themeColor: Color(0xFFFFE66D),
      );

  @override
  State<MathCountGame> createState() => _MathCountGameState();
}

class _MathCountGameState extends BaseGameState<MathCountGame> {
  static const List<String> _objects = ['🍎', '🌟', '🎈', '🌸', '🐟', '🍪', '🦋', '🍒'];

  String _currentObject = '🍎';
  int _count = 0;
  int _targetCount = 3;
  List<String> _options = [];
  final Random _random = Random();

  @override
  String get questionText => '数一数，有几个？';
  
  @override
  String? get correctAnswerText => _targetCount.toString();

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  @override
  void generateQuestion() {
    final objIndex = _random.nextInt(_objects.length);
    _currentObject = _objects[objIndex];
    _targetCount = _random.nextInt(6) + 2; // 2-7
    _count = _targetCount;

    // Generate options
    final correctAnswer = _targetCount;
    final opts = <int>{correctAnswer};
    while (opts.length < 3) {
      final opt = _random.nextInt(9) + 1;
      if (opt != correctAnswer) opts.add(opt);
    }
    _options = opts.map((i) => i.toString()).toList()..shuffle();

    setState(() {
      answered = false;
      correct = false;
      questionNum++;
    });
    
    // 题目生成后朗读
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuestionWithCount();
    });
  }
  
  Future<void> _speakQuestionWithCount() async {
    final tts = TtsService();
    await tts.speak('数一数，有几个$_currentObject？');
  }

  @override
  void checkAnswer(dynamic selected) {
    if (answered) return;
    final selectedInt = selected as int;
    setState(() {
      answered = true;
      correct = selectedInt == _targetCount;
      if (correct) score++;
    });
    
    // 播放反馈语音
    final tts = TtsService();
    if (correct) {
      tts.speak('答对了！真棒！');
    } else {
      tts.speak('不对哦，正确答案是 $_targetCount');
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
    final objectSize = isTV ? 80.0 : 48.0;
    final spacing = isTV ? 24.0 : 12.0;
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(_count, (_) {
        return Text(_currentObject, style: TextStyle(fontSize: objectSize));
      }),
    );
  }

  @override
  Widget buildOptions() {
    if (isTV && MediaQuery.of(context).size.width > MediaQuery.of(context).size.height) {
      // TV 横屏：垂直排列大按钮
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _options.map((opt) {
          final optInt = int.tryParse(opt) ?? 0;
          final isSelected = answered && optInt == _targetCount;
          final isWrong = answered && optInt != _targetCount;
          return TVButton(
            text: opt,
            onPressed: () => checkAnswer(optInt),
            primaryColor: widget.themeColor,
            isSelected: isSelected,
            isWrong: isWrong,
          );
        }).toList(),
      );
    }
    
    // 普通布局：网格
    return GridView.count(
      crossAxisCount: isTV ? 3 : 3,
      shrinkWrap: true,
      mainAxisSpacing: isTV ? 32 : 16,
      crossAxisSpacing: isTV ? 32 : 16,
      childAspectRatio: isTV ? 1.5 : 1.2,
      children: _options.map((opt) {
        final optInt = int.tryParse(opt) ?? 0;
        final isSelected = answered && optInt == _targetCount;
        final isWrong = answered && optInt != _targetCount;
        return GestureDetector(
          onTap: () => checkAnswer(optInt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[100] : isWrong ? Colors.red[100] : Colors.white,
              borderRadius: BorderRadius.circular(isTV ? 40 : 20),
              border: Border.all(
                color: isSelected ? Colors.green : isWrong ? Colors.red : widget.themeColor,
                width: isTV ? 6 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withOpacity(0.2),
                  blurRadius: isTV ? 16 : 8,
                  offset: Offset(0, isTV ? 8 : 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: isTV ? 72 : 36,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : isWrong ? Colors.red : widget.themeColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
