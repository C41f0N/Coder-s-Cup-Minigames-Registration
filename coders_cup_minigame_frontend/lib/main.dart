import 'package:coders_cup_minigame_frontend/firebase_options.dart';
import 'package:coders_cup_minigame_frontend/pages/games_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coder\'s Cup Minigames',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.red[700]!,
          secondary: Colors.red[900]!,
        ),
      ),
      home: GamesPage(),
    );
  }
}
