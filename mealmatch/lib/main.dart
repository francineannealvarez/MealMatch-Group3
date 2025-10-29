import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mealmatch/models/fooditem.dart';
import 'screens/signup_screen.dart';
import 'screens/getstarted_screen.dart';
import 'screens/greet_screen.dart';
import 'screens/login_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/logfood_screen.dart';
import 'screens/modifyfood_screen.dart';
import 'screens/termsandcondition_screen.dart';
import 'screens/privacypolicy_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/log_history_screen.dart';
// import 'screens/profile_screen.dart';

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
        '/preferences': (context) => GetStartedScreen(email: '', password: ''),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/logfood': (context) => const SelectMealScreen(),
        '/modifyfood': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ModifyFoodScreen(
            food: args['food'] as FoodItem,
            preselectedMeal: args['preselectedMeal'] as String?,
          );
        },
        '/recipes': (context) => const RecipesPage(),
        '/terms': (context) => const TermsConditionScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/history': (context) => const LogHistoryPage(),
        // '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
