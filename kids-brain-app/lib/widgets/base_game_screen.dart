import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';

/// 游戏基类，提供 TTS 读题、重复按钮、TV 适配功能
abstract class BaseGameScreen extends StatefulWidget {
  final String title;
  final String emoji;
  final Color themeColor;
  
  const BaseGameScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.themeColor,
  });
}

abstract class BaseGameState<T extends BaseGameScreen> extends State<T> {
  final TtsService _tts = TtsService();
  int _score = 0;
  int _questionNum = 0;
  bool _answered = false;
  bool _correct = false;
  
  // TV 适配
  bool get isTV {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 800; // 大屏认为是 TV
  }
  
  double get fontSizeLarge => isTV ? 48 : 28;
  double get fontSizeMedium => isTV ? 36 : 22;
  double get fontSizeSmall => isTV ? 28 : 16;
  double get buttonHeight => isTV ? 100 : 60;
  double get spacing => isTV ? 40 : 20;
  double get padding => isTV ? 40 : 16;
  
  String get questionText;
  String? get correctAnswerText;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuestion();
    });
  }
  
  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
  
  Future<void> _speakQuestion() async {
    final text = questionText;
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }
  
  void generateQuestion();
  void checkAnswer(dynamic selected);
  Widget buildQuestionContent();
  Widget buildOptions();
  
  void showResult() {
    _tts.speak('答题结束！你答对了 $_score 道题！');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text('🎉 答题结束', 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold)),
        content: Text(
          '答对了 $_score/10 题\n${_score >= 7 ? '你太厉害了！🌟' : _score >= 4 ? '继续加油！💪' : '再练练吧！😊'}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSizeMedium),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _score = 0;
                _questionNum = 0;
                _answered = false;
                generateQuestion();
              });
            },
            child: Text('再来一轮', style: TextStyle(fontSize: fontSizeMedium)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: TextStyle(fontSize: isTV ? 48 : 28)),
            SizedBox(width: isTV ? 16 : 8),
            Text(widget.title, style: TextStyle(color: Colors.white, fontSize: isTV ? 40 : 24)),
          ],
        ),
        backgroundColor: widget.themeColor,
        elevation: 0,
        toolbarHeight: isTV ? 100 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: isTV ? 48 : 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 重复朗读按钮
          FocusableActionDetector(
            onFocusChange: (focused) {},
            child: IconButton(
              icon: Icon(Icons.volume_up, color: Colors.white, size: isTV ? 48 : 28),
              tooltip: '再听一遍',
              onPressed: () => _speakQuestion(),
            ),
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
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // 得分和进度
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('得分: $_score', 
                style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: widget.themeColor)),
              Text('第 $_questionNum/10 题', 
                style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey)),
            ],
          ),
          SizedBox(height: spacing),
          
          // 题目区域（带语音按钮）
          _buildQuestionArea(),
          
          SizedBox(height: spacing),
          
          // 反馈文字
          _buildFeedback(),
          
          SizedBox(height: spacing / 2),
          
          // 选项区域
          Expanded(child: buildOptions()),
        ],
      ),
    );
  }
  
  Widget _buildTVLandscapeLayout() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          // 左侧：题目和反馈
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('得分: $_score', 
                      style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: widget.themeColor)),
                    Text('第 $_questionNum/10 题', 
                      style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: spacing * 2),
                Expanded(child: _buildQuestionArea()),
                SizedBox(height: spacing),
                _buildFeedback(),
              ],
            ),
          ),
          SizedBox(width: spacing * 2),
          // 右侧：选项
          Expanded(
            flex: 1,
            child: buildOptions(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionArea() {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTV ? 40 : 20),
        boxShadow: [BoxShadow(color: widget.themeColor.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 题目文字
          Text(questionText, 
            style: TextStyle(fontSize: fontSizeLarge, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTV ? 30 : 16),
          // 题目内容（由子类实现）
          buildQuestionContent(),
          SizedBox(height: isTV ? 20 : 12),
          // 显式的重复按钮（TV上更明显）
          if (isTV)
            ElevatedButton.icon(
              onPressed: () => _speakQuestion(),
              icon: Icon(Icons.volume_up, size: fontSizeMedium),
              label: Text('再听一遍', style: TextStyle(fontSize: fontSizeSmall)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isTV ? 40 : 20, vertical: isTV ? 20 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTV ? 20 : 12)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFeedback() {
    if (!_answered) {
      return Text('选正确的答案：', style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey));
    }
    
    if (_correct) {
      return Text('✅ 答对了！', 
        style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: Colors.green));
    } else {
      final correctText = correctAnswerText ?? '';
      return Text('❌ 正确答案是 $correctText', 
        style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold, color: Colors.red));
    }
  }
}

/// TV 优化的按钮
class TVButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;
  final bool isWrong;
  final Color primaryColor;
  final double? fontSize;
  final double? height;

  const TVButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.primaryColor,
    this.isSelected = false,
    this.isWrong = false,
    this.fontSize,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 800;
    final actualFontSize = fontSize ?? (isTV ? 48 : 36);
    final actualHeight = height ?? (isTV ? 120 : 80);
    
    Color bgColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      bgColor = Colors.green[100]!;
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (isWrong) {
      bgColor = Colors.red[100]!;
      borderColor = Colors.red;
      textColor = Colors.red;
    } else {
      bgColor = Colors.white;
      borderColor = primaryColor;
      textColor = primaryColor;
    }
    
    return FocusableActionDetector(
      onFocusChange: (focused) {},
      child: Container(
        height: actualHeight,
        margin: EdgeInsets.symmetric(vertical: isTV ? 16 : 8),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 4,
            padding: EdgeInsets.symmetric(horizontal: isTV ? 40 : 20, vertical: isTV ? 20 : 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTV ? 30 : 20),
              side: BorderSide(color: borderColor, width: isTV ? 4 : 3),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: actualFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
