import 'package:flutter/material.dart';
import 'dart:math';

class FindDiffGame extends StatefulWidget {
  const FindDiffGame({super.key});

  @override
  State<FindDiffGame> createState() => _FindDiffGameState();
}

class _FindDiffGameState extends State<FindDiffGame> {
  static const int gridSize = 4;
  final Random _random = Random();
  
  late List<List<String>> _leftGrid;
  late List<List<String>> _rightGrid;
  int _diffsFound = 0;
  int _totalDiffs = 0;
  int _attempts = 0;
  bool _gameComplete = false;

  static final List<String> _items = ['🍎', '🍊', '🍌', '🍇', '🍓', '🍉', '🍒', '🥝', '🍍', '🥭'];

  @override
  void initState() {
    super.initState();
    _startGame();
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
    
    // Fill grids
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        _leftGrid[r][c] = _items[_random.nextInt(_items.length)];
        _rightGrid[r][c] = _leftGrid[r][c];
      }
    }
    
    // Create 5 differences
    _totalDiffs = 5;
    final diffPositions = <int>[];
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
    
    // Check if this position has a difference
    final hasDiff = _leftGrid[row][col] != _rightGrid[row][col];
    
    if (hasDiff && _diffsFound < _totalDiffs) {
      setState(() {
        _diffsFound++;
        _attempts++;
        if (_diffsFound >= _totalDiffs) {
          _gameComplete = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            _showWinDialog();
          });
        }
      });
    } else if (!hasDiff) {
      setState(() => _attempts++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ 这里没不同，再看看！', style: TextStyle(fontSize: 16)),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showWinDialog() {
    final accuracy = _totalDiffs / _attempts * 100;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 太棒了！', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('找到了全部 $_totalDiffs 处不同！', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('准确率: ${accuracy.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Text('👀', style: TextStyle(fontSize: 40)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _startGame());
            },
            child: const Text('再玩一次', style: TextStyle(fontSize: 16)),
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
        title: const Text('🌳 专注力森林', style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFF87CEEB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBox('找到', '$_diffsFound/$_totalDiffs', Colors.green),
                  _statBox('尝试', '$_attempts', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('找出左右两边不同的水果！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Grids
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGrid(_leftGrid, true)),
                  const SizedBox(width: 8),
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
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGrid(List<List<String>> grid, bool isLeft) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF87CEEB), width: 2),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8)],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
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
                borderRadius: BorderRadius.circular(8),
                border: hasDiff && _diffsFound > 0
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(grid[r][c], style: const TextStyle(fontSize: 20)),
              ),
            ),
          );
        },
      ),
    );
  }
}
