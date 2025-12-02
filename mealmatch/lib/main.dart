import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mealmatch/models/fooditem.dart';
import 'package:mealmatch/screens/recipes_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/getstarted_screen.dart';
import 'screens/greet_screen.dart';
import 'screens/login_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/logfood_screen.dart';
import 'screens/modifyfood_screen.dart';
import 'screens/termsandcondition_screen.dart';
import 'screens/privacypolicy_screen.dart';
import 'screens/log_history_screen.dart';
import 'screens/whatcanicook_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/user_manual_screen.dart';
import 'screens/upload_recipe.dart ';
import 'screens/notifications_screen.dart';
import 'helpers/notification_trigger_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// 🆕 CHANGED: MyApp is now StatefulWidget to handle app lifecycle
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// 🆕 NEW: State class with WidgetsBindingObserver to detect app state changes
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // 🆕 Register this widget as an observer of app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // 🆕 Trigger notification checks when app first opens
    _checkNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 🆕 Trigger notification checks when app comes to foreground (resumed)
    // This runs when user switches back to the app from background
    if (state == AppLifecycleState.resumed) {
      _checkNotifications();
    }
  }

  @override
  void dispose() {
    // 🆕 Unregister observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🆕 NEW: Helper method to trigger all notification checks
  Future<void> _checkNotifications() async {
    try {
      await NotificationTriggerHelper.onAppOpen();
      print('✅ Notification checks completed successfully');
    } catch (e) {
      print('❌ Error running notification checks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MealMatch App',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
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
        '/recipes': (context) => const RecipesScreen(),
        '/terms': (context) => const TermsConditionScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/history': (context) => const LogHistoryPage(),
        '/whatcanicook': (context) => const WhatCanICookScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/aboutus': (context) => const AboutUsScreen(),
        '/usermanual': (context) => const UserManualScreen(),
        '/upload': (context) => const UploadRecipeScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}