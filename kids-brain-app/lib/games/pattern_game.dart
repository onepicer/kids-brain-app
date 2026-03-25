import 'package:flutter/material.dart';
import 'dart:math';

class PatternGame extends StatefulWidget {
  const PatternGame({super.key});

  @override
  State<PatternGame> createState() => _PatternGameState();
}

class _PatternGameState extends State<PatternGame> {
  static const List<String> _emojis = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];
  final Random _random = Random();

  List<String> _pattern = [];
  String _answer = '';
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
    const patternLength = 2;
    final a = _emojis[_random.nextInt(_emojis.length)];
    var b = _emojis[_random.nextInt(_emojis.length)];
    while (b == a) {
      b = _emojis[_random.nextInt(_emojis.length)];
    }

    _pattern = [];
    for (int i = 0; i < 4; i++) {
      _pattern.add(i % patternLength == 0 ? a : b);
    }
    _answer = _pattern.length % patternLength == 0 ? a : b;

    // Generate options
    final opts = <String>{_answer};
    while (opts.length < 4) {
      opts.add(_emojis[_random.nextInt(_emojis.length)]);
    }
    _options = opts.toList()..shuffle();

    _answered = false;
    _correct = false;
    _questionNum++;
  }

  void _checkAnswer(String selected) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _correct = selected == _answer;
      if (_correct) _score++;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_questionNum >= 8) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('🎉 答题结束', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
            content: Text('答对了 $_score/8 题\n${_score >= 6 ? '你太厉害了！🌟' : '继续加油！💪'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        title: const Text('🧩 逻辑乐园', style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFFFF6B6B),
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
                Text('得分: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                Text('第 $_questionNum/8 题', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('找到规律，下一个是什么？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ..._pattern.map((e) => Text(e, style: const TextStyle(fontSize: 40))),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3, strokeAlign: BorderSide.strokeAlignOutside),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _answered
                        ? Center(child: Text(_answer, style: const TextStyle(fontSize: 30)))
                        : const Center(child: Text('?', style: TextStyle(fontSize: 24, color: Colors.grey, fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_answered)
              Text(
                _correct ? '✅ 答对了！' : '❌ 答错了',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _correct ? Colors.green : Colors.red),
              ),
            const Spacer(),
            // Options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _options.map((opt) {
                return GestureDetector(
                  onTap: () => _checkAnswer(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _answered && opt == _answer ? Colors.green : Colors.red,
                        width: 3,
                      ),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)],
                    ),
                    child: Center(child: Text(opt, style: const TextStyle(fontSize: 32))),
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
