import 'package:flutter/material.dart';
import 'dart:math';
import '../services/tts_service.dart';

class MazeGame extends StatefulWidget {
  const MazeGame({super.key});

  @override
  State<MazeGame> createState() => _MazeGameState();
}

class _MazeGameState extends State<MazeGame> {
  static const int gridSize = 7;
  late List<List<int>> _maze;
  int _playerRow = 0;
  int _playerCol = 0;
  int _exitRow = 0;
  int _exitCol = 0;
  int _level = 1;
  bool _won = false;
  final TtsService _tts = TtsService();

  bool get isTV => MediaQuery.of(context).size.width > 800;
  double get cellSize => isTV 
    ? (MediaQuery.of(context).size.width - 200) / gridSize 
    : (MediaQuery.of(context).size.width - 48) / gridSize;
  double get emojiSize => isTV ? 60 : 28;

  @override
  void initState() {
    super.initState();
    _generateMaze();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tts.speak('空间迷宫！帮助小兔子找到出口！');
    });
  }

  Future<void> _speakHint() async {
    await _tts.speak('帮助小兔子找到星星出口！用手指点方向按钮移动！');
  }

  void _generateMaze() {
    _won = false;
    final random = Random();
    _maze = List.generate(gridSize, (_) => List.filled(gridSize, 1));

    void carve(int r, int c) {
      _maze[r][c] = 0;
      final dirs = [[0, 2], [2, 0], [0, -2], [-2, 0]];
      dirs.shuffle(random);
      for (final dir in dirs) {
        final nr = r + dir[0];
        final nc = c + dir[1];
        if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize && _maze[nr][nc] == 1) {
          _maze[r + dir[0] ~/ 2][c + dir[1] ~/ 2] = 0;
          carve(nr, nc);
        }
      }
    }

    _playerRow = 1;
    _playerCol = 1;
    carve(1, 1);

    _exitRow = gridSize - 2;
    _exitCol = gridSize - 2;
    if (_maze[_exitRow][_exitCol] == 1) {
      for (int r = gridSize - 1; r >= 0; r--) {
        for (int c = gridSize - 1; c >= 0; c--) {
          if (_maze[r][c] == 0 && (r != 1 || c != 1)) {
            _exitRow = r;
            _exitCol = c;
            break;
          }
        }
        if (_maze[_exitRow][_exitCol] == 0) break;
      }
    }
  }

  void _move(int dr, int dc) {
    if (_won) return;
    final nr = _playerRow + dr;
    final nc = _playerCol + dc;
    if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize && _maze[nr][nc] == 0) {
      setState(() {
        _playerRow = nr;
        _playerCol = nc;
      });
      if (_playerRow == _exitRow && _playerCol == _exitCol) {
        setState(() => _won = true);
        _tts.speak('太棒了！你找到了出口！');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_level < 3) {
            _tts.speak('进入第 ${_level + 1} 关！');
            setState(() {
              _level++;
              _generateMaze();
            });
          } else {
            _tts.speak('恭喜通关！你真是个迷宫大师！');
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTV ? 40 : 24)),
                title: Text('🎉 恭喜通关！', textAlign: TextAlign.center, style: TextStyle(fontSize: isTV ? 56 : 28, fontWeight: FontWeight.bold)),
                content: Text('你真是个迷宫大师！🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: isTV ? 36 : 20)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() { _level = 1; _generateMaze(); });
                    },
                    child: Text('再玩一次', style: TextStyle(fontSize: isTV ? 32 : 18)),
                  ),
                ],
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌀', style: TextStyle(fontSize: isTV ? 48 : 28)),
            SizedBox(width: isTV ? 16 : 8),
            Text('空间迷宫  第$_level关', style: TextStyle(color: Colors.white, fontSize: isTV ? 36 : 22)),
          ],
        ),
        backgroundColor: const Color(0xFFA8E6CF),
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isTV ? 16 : 8),
            child: Text('帮助小兔子 🐰 找到出口 ⭐', 
              style: TextStyle(fontSize: isTV ? 40 : 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(isTV ? 16 : 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTV ? 32 : 16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: isTV ? 20 : 10)],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: isTV ? 4 : 2,
                    crossAxisSpacing: isTV ? 4 : 2,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    final r = index ~/ gridSize;
                    final c = index % gridSize;
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: _maze[r][c] == 1 ? Colors.green[700] : Colors.green[50],
                        borderRadius: BorderRadius.circular(isTV ? 8 : 4),
                      ),
                      child: Center(
                        child: _buildCellContent(r, c),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Direction controls
          Padding(
            padding: EdgeInsets.all(isTV ? 32 : 16),
            child: Column(
              children: [
                _dirButton(Icons.arrow_upward, () => _move(-1, 0)),
                SizedBox(height: isTV ? 16 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirButton(Icons.arrow_back, () => _move(0, -1)),
                    SizedBox(width: isTV ? 80 : 48),
                    _dirButton(Icons.arrow_forward, () => _move(0, 1)),
                  ],
                ),
                SizedBox(height: isTV ? 16 : 8),
                _dirButton(Icons.arrow_downward, () => _move(1, 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellContent(int r, int c) {
    if (r == _playerRow && c == _playerCol) {
      return Text('🐰', style: TextStyle(fontSize: emojiSize));
    }
    if (r == _exitRow && c == _exitCol) {
      return Text('⭐', style: TextStyle(fontSize: emojiSize));
    }
    return const SizedBox.shrink();
  }

  Widget _dirButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: isTV ? 100 : 60,
      height: isTV ? 100 : 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA8E6CF),
          shape: const CircleBorder(),
          elevation: 4,
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, color: Colors.green[800], size: isTV ? 48 : 30),
      ),
    );
  }
}
