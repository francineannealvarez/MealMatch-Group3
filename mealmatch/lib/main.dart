import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/signup_screen.dart';
import 'screens/getstarted_screen.dart';
import 'screens/greet_screen.dart';
import 'screens/login_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/logfood_screen.dart';
import 'screens/termsandcondition_screen.dart';
import 'screens/privacypolicy_screen.dart';
// import 'screens/log_history_screen.dart';
// import 'screens/profile_screen.dart';
// import 'screens/recipes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MealMatch App',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/preferences': (context) => GetStartedScreen(email: '', password: ''),
        '/home': (context) => const HomePage(),
        '/logfood': (context) => const SelectMealScreen(),
        '/terms': (context) => const TermsConditionScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        // '/log-history': (context) => LogFoodHistory(),
        // '/profile': (context) => ProfileScreen(),
        // '/recipes': (context) => RecipesScreen(),
      },
    );
  }
}
