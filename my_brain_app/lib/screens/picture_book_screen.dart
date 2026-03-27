import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/tts.dart';

class PictureBookScreen extends StatefulWidget {
  const PictureBookScreen({Key? key}) : super(key: key);

  @override
  State<PictureBookScreen> createState() => _PictureBookScreenState();
}

class _PictureBookScreenState extends State<PictureBookScreen> {
  List<String> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final data = await rootBundle.loadString('assets/json/book.json');
    final List<dynamic> json = jsonDecode(data);
    setState(() {
      _pages = json.map((e) => e.toString()).toList();
    });
  }

  void _onPageChanged(int index) {
    if (index < _pages.length) {
      TtsHelper.speak(_pages[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绘本阅读')),
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/img/picture_${index + 1}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pages[index],
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }
}
