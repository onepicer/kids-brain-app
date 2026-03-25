import 'package:flutter/material.dart';
import 'dart:math';

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

  @override
  void initState() {
    super.initState();
    _generateMaze();
  }

  void _generateMaze() {
    _won = false;
    final random = Random();
    // 0=path, 1=wall
    _maze = List.generate(gridSize, (_) => List.filled(gridSize, 1));

    // Simple maze generation using recursive carving
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

    // Start from (1,1)
    _playerRow = 1;
    _playerCol = 1;
    carve(1, 1);

    // Place exit at farthest reachable point
    _exitRow = gridSize - 2;
    _exitCol = gridSize - 2;
    if (_maze[_exitRow][_exitCol] == 1) {
      // Find last path cell
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
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_level < 3) {
            setState(() {
              _level++;
              _generateMaze();
            });
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('🎉 恭喜通关！', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
                content: const Text('你真是个迷宫大师！🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() { _level = 1; _generateMaze(); });
                    },
                    child: const Text('再玩一次', style: TextStyle(fontSize: 16)),
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
    final cellSize = (MediaQuery.of(context).size.width - 48) / gridSize;
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      appBar: AppBar(
        title: Text('🌀 空间迷宫  第$_level关', style: const TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: const Color(0xFFA8E6CF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('帮助小兔子 🐰 找到出口 ⭐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10)],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    final r = index ~/ gridSize;
                    final c = index % gridSize;
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: _maze[r][c] == 1
                            ? Colors.green[700]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _dirButton(Icons.arrow_upward, () => _move(-1, 0)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirButton(Icons.arrow_back, () => _move(0, -1)),
                    const SizedBox(width: 48),
                    _dirButton(Icons.arrow_forward, () => _move(0, 1)),
                  ],
                ),
                const SizedBox(height: 8),
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
      return const Text('🐰', style: TextStyle(fontSize: 24));
    }
    if (r == _exitRow && c == _exitCol) {
      return const Text('⭐', style: TextStyle(fontSize: 24));
    }
    return const SizedBox.shrink();
  }

  Widget _dirButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA8E6CF),
          shape: const CircleBorder(),
          elevation: 4,
        ),
        child: Icon(icon, color: Colors.green[800], size: 30),
      ),
    );
  }
}
