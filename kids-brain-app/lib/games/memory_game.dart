import 'package:flutter/material.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with TickerProviderStateMixin {
  static const int _rows = 3;
  static const int _cols = 4;
  static const List<String> _emojis = ['🐶', '🐱', '🐰', '🐸', '🦊', '🐻'];

  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  int _firstIndex = -1;
  int _secondIndex = -1;
  bool _isChecking = false;
  int _moves = 0;
  int _matchCount = 0;
  bool _won = false;

  late AnimationController _winController;
  late Animation<double> _winScale;

  @override
  void initState() {
    super.initState();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _winController, curve: Curves.elasticOut),
    );
    _initGame();
  }

  void _initGame() {
    final pairs = [..._emojis, ..._emojis];
    pairs.shuffle();
    _cards = pairs;
    _flipped = List.filled(_rows * _cols, false);
    _matched = List.filled(_rows * _cols, false);
    _firstIndex = -1;
    _secondIndex = -1;
    _isChecking = false;
    _moves = 0;
    _matchCount = 0;
    _won = false;
    _winController.reset();
  }

  void _onCardTap(int index) {
    if (_isChecking || _flipped[index] || _matched[index]) return;

    setState(() => _flipped[index] = true);

    if (_firstIndex == -1) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _moves++;
      _isChecking = true;
      _checkMatch();
    }
  }

  void _checkMatch() {
    if (_cards[_firstIndex] == _cards[_secondIndex]) {
      setState(() {
        _matched[_firstIndex] = true;
        _matched[_secondIndex] = true;
        _matchCount++;
      });
      _resetSelection();
      if (_matchCount == _emojis.length) {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() => _won = true);
          _winController.forward();
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _flipped[_firstIndex] = false;
          _flipped[_secondIndex] = false;
        });
        _resetSelection();
      });
    }
  }

  void _resetSelection() {
    _firstIndex = -1;
    _secondIndex = -1;
    _isChecking = false;
  }

  @override
  void dispose() {
    _winController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFA),
      appBar: AppBar(
        title: const Text('🏰 记忆城堡', style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFF4ECDC4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard('翻牌', '$_moves', Colors.orange),
                    _statCard('配对', '$_matchCount/${_emojis.length}', Colors.green),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _cols,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _rows * _cols,
                    itemBuilder: (context, index) {
                      return _buildCard(index);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_won) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _flipped[index] || _matched[index]
            ? Container(
                key: ValueKey('front_$index'),
                decoration: BoxDecoration(
                  color: _matched[index] ? Colors.green[50] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _matched[index] ? Colors.green : const Color(0xFF4ECDC4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _cards[index],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              )
            : Container(
                key: ValueKey('back_$index'),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('❓', style: TextStyle(fontSize: 30, color: Colors.white)),
                ),
              ),
      ),
    );
  }

  Widget _buildWinOverlay() {
    return AnimatedBuilder(
      animation: _winController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.5 * _winScale.value),
          child: Center(
            child: Transform.scale(
              scale: _winScale.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 12),
                    const Text(
                      '太棒了！',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4ECDC4)),
                    ),
                    Text(
                      '用了 $_moves 次翻牌',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _initGame());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('再玩一次', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
