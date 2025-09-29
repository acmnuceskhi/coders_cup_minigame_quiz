import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'src/pages/auth_gate.dart';
import 'src/pages/user_home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coders Cup Quiz',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(primary: Colors.blue[400]!),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const UserHome(),
        '/admin': (_) => const AuthGate(),
      },
    );
  }
}

