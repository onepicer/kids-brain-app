import 'package:flutter/material.dart';
import 'dart:math';
import '../services/tts_service.dart';

class PatternGame extends StatefulWidget {
  const PatternGame({super.key});

  @override
  State<PatternGame> createState() => _PatternGameState();
}

class _PatternGameState extends State<PatternGame> {
  static const List<String> _emojis = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];
  final Random _random = Random();
  final TtsService _tts = TtsService();

  List<String> _pattern = [];
  String _answer = '';
  List<String> _options = [];
  int score = 0;
  int questionNum = 0;
  bool answered = false;
  bool correct = false;

  bool get isTV => MediaQuery.of(context).size.width > 800;
  double get fontSize => isTV ? 48 : 22;
  double get emojiSize => isTV ? 80 : 40;
  double get spacing => isTV ? 40 : 16;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  Future<void> _speakQuestion() async {
    await _tts.speak('找到规律，下一个是什么？');
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

    setState(() {
      answered = false;
      correct = false;
      questionNum++;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakQuestion());
  }

  void _checkAnswer(String selected) {
    if (answered) return;
    setState(() {
      answered = true;
      correct = selected == _answer;
      if (correct) score++;
    });
    
    if (correct) {
      _tts.speak('答对了！真棒！');
    } else {
      _tts.speak('不对哦，再想想看！');
    }
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (questionNum >= 8) {
        _showResult();
      } else {
        setState(() => _generateQuestion());
      }
    });
  }

  void _showResult() {
    _tts.speak('答题结束！你答对了 $score 道题！');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTV ? 40 : 24)),
        title: Text('🎉 答题结束', 
          textAlign: TextAlign.center, 
          style: TextStyle(fontSize: isTV ? 56 : 28, fontWeight: FontWeight.bold)),
        content: Text('答对了 $score/8 题\n${score >= 6 ? '你太厉害了！🌟' : '继续加油！💪'}', 
          textAlign: TextAlign.center, 
          style: TextStyle(fontSize: isTV ? 40 : 20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { score = 0; questionNum = 0; _generateQuestion(); });
            },
            child: Text('再来一轮', style: TextStyle(fontSize: isTV ? 32 : 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧩', style: TextStyle(fontSize: isTV ? 48 : 28)),
            SizedBox(width: isTV ? 16 : 8),
            Text('逻辑乐园', style: TextStyle(color: Colors.white, fontSize: isTV ? 40 : 24)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        elevation: 0,
        toolbarHeight: isTV ? 100 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: isTV ? 48 : 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up, color: Colors.white, size: isTV ? 48 : 28),
            onPressed: () => _speakQuestion(),
            tooltip: '再听一遍',
          ),
          SizedBox(width: isTV ? 20 : 8),
        ],
      ),
      body: isLandscape && isTV
        ? _buildTVLandscapeLayout()
        : _buildNormalLayout(),
    );
  }

  Widget _buildNormalLayout() {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('得分: $score', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.red)),
              Text('第 $questionNum/8 题', style: TextStyle(fontSize: isTV ? 32 : 16, color: Colors.grey)),
            ],
          ),
          SizedBox(height: spacing),
          Text('找到规律，下一个是什么？', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(isTV ? 40 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTV ? 40 : 20),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ..._pattern.map((e) => Text(e, style: TextStyle(fontSize: emojiSize))),
                Container(
                  width: isTV ? 100 : 50,
                  height: isTV ? 100 : 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: isTV ? 5 : 3),
                    borderRadius: BorderRadius.circular(isTV ? 20 : 12),
                  ),
                  child: answered
                      ? Center(child: Text(_answer, style: TextStyle(fontSize: isTV ? 60 : 30)))
                      : Center(child: Text('?', style: TextStyle(fontSize: isTV ? 48 : 24, color: Colors.grey, fontWeight: FontWeight.bold))),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          if (answered)
            Text(
              correct ? '✅ 答对了！' : '❌ 答错了',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: correct ? Colors.green : Colors.red),
            ),
          const Spacer(),
          Wrap(
            spacing: isTV ? 32 : 16,
            runSpacing: isTV ? 32 : 16,
            alignment: WrapAlignment.center,
            children: _options.map((opt) {
              return GestureDetector(
                onTap: () => _checkAnswer(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isTV ? 140 : 70,
                  height: isTV ? 140 : 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTV ? 32 : 16),
                    border: Border.all(
                      color: answered && opt == _answer ? Colors.green : Colors.red,
                      width: isTV ? 6 : 3,
                    ),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: isTV ? 16 : 6)],
                  ),
                  child: Center(child: Text(opt, style: TextStyle(fontSize: emojiSize))),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: spacing),
        ],
      ),
    );
  }

  Widget _buildTVLandscapeLayout() {
    return Padding(
      padding: EdgeInsets.all(spacing * 2),
      child: Row(
        children: [
          // Left side: pattern and question
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('得分: $score', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.red)),
                    Text('第 $questionNum/8 题', style: TextStyle(fontSize: isTV ? 32 : 16, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Text('找到规律，下一个是什么？', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: spacing * 2),
                Container(
                  padding: EdgeInsets.all(isTV ? 50 : 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTV ? 40 : 24),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ..._pattern.map((e) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: isTV ? 20 : 10),
                        child: Text(e, style: TextStyle(fontSize: isTV ? 100 : 48)),
                      )),
                      Container(
                        width: isTV ? 120 : 60,
                        height: isTV ? 120 : 60,
                        margin: EdgeInsets.only(left: isTV ? 20 : 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: isTV ? 6 : 4),
                          borderRadius: BorderRadius.circular(isTV ? 24 : 12),
                        ),
                        child: answered
                            ? Center(child: Text(_answer, style: TextStyle(fontSize: isTV ? 72 : 36)))
                            : Center(child: Text('?', style: TextStyle(fontSize: isTV ? 56 : 28, color: Colors.grey, fontWeight: FontWeight.bold))),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                if (answered)
                  Text(
                    correct ? '✅ 答对了！' : '❌ 答错了',
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: correct ? Colors.green : Colors.red),
                  ),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(width: spacing * 2),
          // Right side: options
          Expanded(
            flex: 1,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: isTV ? 40 : 20,
              crossAxisSpacing: isTV ? 40 : 20,
              childAspectRatio: 1,
              children: _options.map((opt) {
                return ElevatedButton(
                  onPressed: () => _checkAnswer(opt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTV ? 40 : 20),
                      side: BorderSide(
                        color: answered && opt == _answer ? Colors.green : Colors.red,
                        width: isTV ? 6 : 3,
                      ),
                    ),
                  ),
                  child: Text(opt, style: TextStyle(fontSize: isTV ? 100 : 48)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
