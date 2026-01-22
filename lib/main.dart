import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'src/pages/auth_gate.dart';
import 'src/pages/user_home.dart';
import 'src/pages/admin_password_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await TeXRenderingServer.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coders Cup Quiz',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 186, 30, 30),
        ),
        useMaterial3: true,
      ),
      home: const AppRoot(),
      routes: {'/admin': (_) => const AdminPasswordGate()},
    );
  }
}

/// Root widget that checks auth state on startup
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        // If not logged in, show auth gate (login page)
        if (user == null) {
          return const AuthGate();
        }
        // If logged in, show user home
        return const UserHome();
      },
    );
  }
}
