import 'package:flutter/material.dart';
import 'dart:math';

class MathCountGame extends StatefulWidget {
  const MathCountGame({super.key});

  @override
  State<MathCountGame> createState() => _MathCountGameState();
}

class _MathCountGameState extends State<MathCountGame> {
  static const List<String> _objects = ['🍎', '🌟', '🎈', '🌸', '🐟', '🍪', '🦋', '🍒'];


  String _currentObject = '🍎';
  int _count = 0;
  int _targetCount = 3;
  List<String> _options = [];
  int _score = 0;
  int _questionNum = 0;
  bool _answered = false;
  bool _correct = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final objIndex = _random.nextInt(_objects.length);
    _currentObject = _objects[objIndex];
    _targetCount = _random.nextInt(6) + 2; // 2-7
    _count = _targetCount;

    // Generate options
    final correct = _targetCount;
    final opts = <int>{correct};
    while (opts.length < 3) {
      final opt = _random.nextInt(9) + 1;
      if (opt != correct) opts.add(opt);
    }
    _options = opts.map((i) => i.toString()).toList()..shuffle();

    _answered = false;
    _correct = false;
    _questionNum++;
  }

  void _checkAnswer(int selected) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _correct = selected == _targetCount;
      if (_correct) _score++;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (_questionNum >= 10) {
        _showResult();
      } else {
        setState(() => _generateQuestion());
      }
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 答题结束', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24)),
        content: Text(
          '答对了 $_score/10 题\n${_score >= 7 ? '你太厉害了！🌟' : _score >= 4 ? '继续加油！💪' : '再练练吧！😊'}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _score = 0;
                _questionNum = 0;
                _generateQuestion();
              });
            },
            child: const Text('再来一轮', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('👑 数学王国', style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFFFFE66D),
        foregroundColor: Colors.white,
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
            // Score & progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('得分: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('第 $_questionNum/10 题', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            // Question
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('数一数，有几个？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Display objects in rows
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_count, (_) {
                      return Text(_currentObject, style: const TextStyle(fontSize: 32));
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Options
            if (!_answered)
              const Text('选正确的数字：', style: TextStyle(fontSize: 18, color: Colors.grey))
            else if (_correct)
              const Text('✅ 答对了！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))
            else
              Text('❌ 正确答案是 $_targetCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: _options.map((opt) {
                  final optInt = int.tryParse(opt) ?? 0;
                  final isSelected = _answered && optInt == _targetCount;
                  final isWrong = _answered && optInt != _targetCount;
                  return GestureDetector(
                    onTap: () => _checkAnswer(optInt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[100] : isWrong ? Colors.red[100] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.green : isWrong ? Colors.red : Colors.orange,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green : isWrong ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
