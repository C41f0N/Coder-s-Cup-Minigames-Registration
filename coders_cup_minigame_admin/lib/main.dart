import 'package:coders_cup_minigame_admin/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coders Cup Minigame Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.red[700]!,
          secondary: Colors.red[900]!,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
