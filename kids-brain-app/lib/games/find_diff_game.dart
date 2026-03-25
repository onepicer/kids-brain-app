import 'package:flutter/material.dart';
import 'dart:math';
import '../services/tts_service.dart';

class FindDiffGame extends StatefulWidget {
  const FindDiffGame({super.key});

  @override
  State<FindDiffGame> createState() => _FindDiffGameState();
}

class _FindDiffGameState extends State<FindDiffGame> {
  static const int gridSize = 4;
  final Random _random = Random();
  final TtsService _tts = TtsService();
  
  late List<List<String>> _leftGrid;
  late List<List<String>> _rightGrid;
  int _diffsFound = 0;
  int _totalDiffs = 0;
  int _attempts = 0;
  bool _gameComplete = false;

  static final List<String> _items = ['🍎', '🍊', '🍌', '🍇', '🍓', '🍉', '🍒', '🥝', '🍍', '🥭'];

  bool get isTV => MediaQuery.of(context).size.width > 800;
  double get fontSize => isTV ? 36 : 20;
  double get itemSize => isTV ? 48 : 28;
  double get spacing => isTV ? 16 : 4;

  @override
  void initState() {
    super.initState();
    _startGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tts.speak('专注力森林！找出左右两边不同的水果！');
    });
  }

  Future<void> _speakHint() async {
    await _tts.speak('找出左右两边不同的水果！点击不同的地方！');
  }

  void _startGame() {
    _totalDiffs = 0;
    _diffsFound = 0;
    _attempts = 0;
    _gameComplete = false;
    _generateLevel();
  }

  void _generateLevel() {
    _leftGrid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    _rightGrid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        _leftGrid[r][c] = _items[_random.nextInt(_items.length)];
        _rightGrid[r][c] = _leftGrid[r][c];
      }
    }
    
    _totalDiffs = 5;
    final diffPositions = <int>{};
    while (diffPositions.length < _totalDiffs) {
      final pos = _random.nextInt(gridSize * gridSize);
      if (!diffPositions.contains(pos)) {
        diffPositions.add(pos);
        final r = pos ~/ gridSize;
        final c = pos % gridSize;
        var newItem = _items[_random.nextInt(_items.length)];
        while (newItem == _rightGrid[r][c]) {
          newItem = _items[_random.nextInt(_items.length)];
        }
        _rightGrid[r][c] = newItem;
      }
    }
  }

  void _onGridTap(int row, int col, bool isLeft) {
    if (_gameComplete) return;
    
    final hasDiff = _leftGrid[row][col] != _rightGrid[row][col];
    
    if (hasDiff) {
      setState(() {
        _diffsFound++;
        _attempts++;
      });
      _tts.speak('找到了！');
      if (_diffsFound >= _totalDiffs) {
        _gameComplete = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _showWinDialog();
        });
      }
    } else {
      setState(() => _attempts++);
      _tts.speak('这里没不同，再看看！');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 这里没不同，再看看！', style: TextStyle(fontSize: isTV ? 32 : 18)),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTV ? 20 : 12)),
          margin: EdgeInsets.all(isTV ? 40 : 20),
        ),
      );
    }
  }

  void _showWinDialog() {
    final accuracy = _totalDiffs / _attempts * 100;
    _tts.speak('太棒了！找到了全部 $_totalDiffs 处不同！');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTV ? 40 : 24)),
        title: Text('🎉 太棒了！', textAlign: TextAlign.center, style: TextStyle(fontSize: isTV ? 56 : 28, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('找到了全部 $_totalDiffs 处不同！', style: TextStyle(fontSize: isTV ? 36 : 20)),
            SizedBox(height: isTV ? 16 : 8),
            Text('准确率: ${accuracy.toStringAsFixed(0)}%', style: TextStyle(fontSize: isTV ? 28 : 16, color: Colors.grey[600])),
            SizedBox(height: isTV ? 20 : 12),
            const Text('👀', style: TextStyle(fontSize: 60)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _startGame());
            },
            child: Text('再玩一次', style: TextStyle(fontSize: isTV ? 32 : 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌳', style: TextStyle(fontSize: isTV ? 48 : 28)),
            SizedBox(width: isTV ? 16 : 8),
            Text('专注力森林', style: TextStyle(color: Colors.white, fontSize: isTV ? 40 : 24)),
          ],
        ),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        toolbarHeight: isTV ? 100 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: isTV ? 48 : 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up, color: Colors.white, size: isTV ? 48 : 28),
            onPressed: () => _speakHint(),
            tooltip: '再听一遍',
          ),
          SizedBox(width: isTV ? 20 : 8),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isTV ? 24 : 12),
        child: Column(
          children: [
            // Progress
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTV ? 40 : 20, vertical: isTV ? 20 : 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isTV ? 24 : 16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: isTV ? 16 : 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('找到', '$_diffsFound/$_totalDiffs', Colors.green),
                  _statBox('尝试', '$_attempts', Colors.orange),
                ],
              ),
            ),
            SizedBox(height: isTV ? 24 : 12),
            Text('找出左右两边不同的水果！', style: TextStyle(fontSize: isTV ? 36 : 20, fontWeight: FontWeight.bold)),
            SizedBox(height: isTV ? 24 : 12),
            // Grids
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGrid(_leftGrid, true)),
                  SizedBox(width: isTV ? 16 : 8),
                  Expanded(child: _buildGrid(_rightGrid, false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: isTV ? 48 : 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: isTV ? 24 : 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGrid(List<List<String>> grid, bool isLeft) {
    return Container(
      padding: EdgeInsets.all(isTV ? 16 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTV ? 24 : 16),
        border: Border.all(color: const Color(0xFF87CEEB), width: isTV ? 4 : 2),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: isTV ? 16 : 8)],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          final r = index ~/ gridSize;
          final c = index % gridSize;
          final hasDiff = _leftGrid[r][c] != _rightGrid[r][c];
          
          return GestureDetector(
            onTap: () => _onGridTap(r, c, isLeft),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(isTV ? 12 : 8),
                border: hasDiff && _diffsFound > 0
                    ? Border.all(color: Colors.green, width: isTV ? 4 : 2)
                    : null,
              ),
              child: Center(
                child: Text(grid[r][c], style: TextStyle(fontSize: itemSize)),
              ),
            ),
          );
        },
      ),
    );
  }
}
