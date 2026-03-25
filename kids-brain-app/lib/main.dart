import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/tts_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 支持横竖屏（TV主要是横屏）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // 初始化TTS
  TtsService().init();
  
  runApp(const KidsBrainApp());
}

class KidsBrainApp extends StatelessWidget {
  const KidsBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '奇妙大脑岛',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'RoundFont',
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
