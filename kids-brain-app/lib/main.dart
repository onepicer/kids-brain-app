import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
