import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // import Firebase
import 'screens/signup_screen.dart';
import 'screens/greet_screen.dart'; // WelcomeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ensures binding before async
  await Firebase.initializeApp(); // initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MealMatch App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      initialRoute: '/', // first screen
      routes: {
        '/': (context) => WelcomeScreen(), // your first screen
        '/signup': (context) => SignUpScreen(), // sign-up screen
        // Add other screens here later (e.g., login)
      },
    );
  }
}
