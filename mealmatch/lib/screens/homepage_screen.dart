import 'dart:math';

import 'package:flutter/material.dart';
import '../services/calorielog_history_service.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:mealmatch/services/themealdb_service.dart';
import 'package:mealmatch/services/cooked_recipes_service.dart';
import 'package:mealmatch/screens/recipe_details_screen.dart';
import 'package:mealmatch/services/recipe_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RecipeService _recipeService = RecipeService();
  List<Map<String, dynamic>> userRecipes = []; // For community recipes
  bool isLoadingUserRecipes = true; // Loading state for user recipes
  final LogService _logService = LogService();
  final FirebaseService _firebaseService = FirebaseService();
  final CookedRecipesService _cookedService = CookedRecipesService();
  
  int _selectedIndex = 0;

  int userGoalCalories = 2000;
  int consumedCalories = 0;
  bool isLoading = true;

  // Recipe lists - INITIALIZE WITH EMPTY LISTS
  List<Map<String, dynamic>> cookAgainRecipes = [];
  List<Map<String, dynamic>> tryTheseRecipes = [];
  List<Map<String, dynamic>> discoverProteinRecipes = [];

  // User stats for metabolism card
  Map<String, dynamic>? userData;
  double? userBMR;
  double? userTDEE;

  // Track if user has meal history
  bool hasLoggedMeals = false;
  bool hasCookedRecipes = false;

  // PREVENT DOUBLE LOADING
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  // Load data more efficiently
  Future<void> _loadTodayData() async {
    setState(() => isLoading = true);

    try {
      // --- Phase 1: Load critical data first (fast) ---
      final userDataFuture = _logService.getUserData();
      final goalFuture = _firebaseService.getUserCalorieGoal();
      final logsFuture = _logService.getTodayLogs();

      // Wait for critical data
      userData = await userDataFuture;
      final goal = await goalFuture;
      final logs = await logsFuture;

      // Process critical data
      if (userData != null) {
        userBMR = _calculateBMR(
          gender: userData!['gender'],
          age: userData!['age'],
          height: userData!['height'].toDouble(),
          weight: userData!['weight'].toDouble(),
        );
        userTDEE =
            userBMR! * _getActivityMultiplier(userData!['activityLevel']);
      }

      if (goal != null) {
        userGoalCalories = goal;
      }

      consumedCalories = _logService.calculateTotalCalories(logs).toInt();

      // Check if user has meal history
      hasLoggedMeals = await _checkUserHasMealHistory();

      // Check if user has cooked recipes
      hasCookedRecipes = await _checkUserHasCookedRecipes();

      // Update UI with critical data first
      setState(() => isLoading = false);

      // --- Phase 2: Load all recipes in parallel (faster) ---
      _loadRecipesInParallel();
    } catch (e) {
      print('❌ Error loading today\'s data: $e');
      setState(() => isLoading = false);
    }
  }

  // Reset lists to empty before loading (shows spinners)
  Future<void> _loadRecipesInParallel() async {
    if (_isLoadingRecipes) {
      print('⚠️ Recipes already loading, skipping...');
      return;
    }

    _isLoadingRecipes = true;

    setState(() {
      cookAgainRecipes = [];
      tryTheseRecipes = [];
      discoverProteinRecipes = [];
      userRecipes = [];
    });

    try {
      print('🔄 Starting parallel recipe loading...');

      // ✅ FIXED: Now loading community recipes AND cooked recipes
      final userRecipesFuture = _recipeService.getPublicRecipes(limit: 5);
      final cookAgainFuture = _loadCookAgainRecipes();
      final discoverFuture = _getVariedProteinRecipes();
      final tryTheseFuture = TheMealDBService.getRandomMeals(5);

      final results = await Future.wait([
        userRecipesFuture,
        cookAgainFuture,
        discoverFuture,
        tryTheseFuture,
      ], eagerError: true).timeout(
        const Duration(seconds: 30),
        onTimeout: () => [[], [], [], []],
      );

      userRecipes = (results[0] as List).cast<Map<String, dynamic>>();
      cookAgainRecipes = (results[1] as List).cast<Map<String, dynamic>>();
      discoverProteinRecipes = (results[2] as List).cast<Map<String, dynamic>>();
      tryTheseRecipes = (results[3] as List).cast<Map<String, dynamic>>();

      print('✅ All recipes loaded:');
      print('   - ${userRecipes.length} community recipes');
      print('   - ${cookAgainRecipes.length} cook again recipes');
      print('   - ${discoverProteinRecipes.length} protein recipes');
      print('   - ${tryTheseRecipes.length} try these recipes');
      
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error loading recipes: $e');
    } finally {
      _isLoadingRecipes = false;
    }
  }

  Future<List<Map<String, dynamic>>> _loadCookAgainRecipes() async {
    try {
      if (hasCookedRecipes) {
        return await _getMostCookedRecipes();
      } else if (hasLoggedMeals) {
        return await _getUserFavoriteRecipes();
      }
      return [];
    } catch (e) {
      print('❌ Error loading cook again recipes: $e');
      return [];
    }
  }

  // Check if user has logged any meals before
  Future<bool> _checkUserHasMealHistory() async {
    try {
      // Check last 30 days for any meal logs
      final logs = await _logService.getLogsForDateRange(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
      );
      return logs.isNotEmpty;
    } catch (e) {
      print('Error checking meal history: $e');
      return false;
    }
  }

  // Check if user has cooked any recipes
  Future<bool> _checkUserHasCookedRecipes() async {
    try {
      final cookedRecipes = await _cookedService.getUserCookedRecipes(limit: 1);
      return cookedRecipes.isNotEmpty;
    } catch (e) {
      print('Error checking cooked recipes: $e');
      return false;
    }
  }

  // Get user's most cooked recipes
  Future<List<Map<String, dynamic>>> _getMostCookedRecipes() async {
    try {
      final mostCooked = await _cookedService.getMostCookedRecipes(limit: 5);

      if (mostCooked.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> recipes = [];

      for (var cookedRecipe in mostCooked) {
        try {
          // ✅ FIXED: Handle both String and possible other types
          final recipeId = cookedRecipe['recipeId'] is String
              ? cookedRecipe['recipeId'] as String
              : cookedRecipe['recipeId'].toString();
              
          print('🔍 Loading cooked recipe: $recipeId');

          // ✅ TRY RECIPE SERVICE FIRST (user recipes)
          final details = await _recipeService.getRecipeById(recipeId);
          
          // If not found in user recipes, try TheMealDB
          final finalDetails = details ?? await TheMealDBService.getMealDetails(recipeId);

          if (finalDetails != null) {
            recipes.add(finalDetails);
          }
        } catch (e) {
          print('⚠️ Error loading individual cooked recipe: $e');
          continue; // Skip this recipe and continue with next
        }
      }

      print('✅ Loaded ${recipes.length} cooked recipes');
      return recipes;
    } catch (e) {
      print('❌ Error getting most cooked recipes: $e');
      return [];
    }
  }

  // Get user's favorite/frequently logged meals
  Future<List<Map<String, dynamic>>> _getUserFavoriteRecipes() async {
    try {
      final logs = await _logService.getLogsForDateRange(
        DateTime.now().subtract(const Duration(days: 60)),
        DateTime.now(),
      );

      Map<String, int> mealFrequency = {};
      Map<String, String> mealIds = {};

      for (var log in logs) {
        final mealName = log['name'] as String?;
        final mealId = log['recipeId'] as String?;

        if (mealName != null && mealId != null) {
          mealFrequency[mealName] = (mealFrequency[mealName] ?? 0) + 1;
          mealIds[mealName] = mealId;
        }
      }

      var sortedMeals = mealFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> recipes = [];

      for (var entry in sortedMeals.take(5)) {
        final mealId = mealIds[entry.key];
        if (mealId != null) {
          final details = await TheMealDBService.getMealDetails(mealId);
          if (details != null) {
            recipes.add(details);
          }
        }
      }

      return recipes;
    } catch (e) {
      print('❌ Error getting favorite recipes: $e');
      return await TheMealDBService.getRandomMeals(5);
    }
  }

  // Get varied high-protein recipes
  Future<List<Map<String, dynamic>>> _getVariedProteinRecipes() async {
    try {
      final proteinCategories = ['Chicken', 'Beef', 'Seafood', 'Pork'];

      // ✅ Rotate category every 6 hours instead of daily
      final hoursSinceEpoch =
          DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60);
      final categoryIndex = (hoursSinceEpoch ~/ 6) % proteinCategories.length;
      final selectedCategory = proteinCategories[categoryIndex];

      print('🍖 Loading protein recipes: $selectedCategory');

      final meals = await TheMealDBService.getMealsByCategory(
        selectedCategory,
        number: 50,
      );

      if (meals.isEmpty) return [];

      // ✅ Shuffle differently each time using current timestamp
      meals.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

      return meals.take(5).toList();
    } catch (e) {
      print('❌ Error getting protein recipes: $e');
      return [];
    }
  }

  // Calculate BMR using Mifflin-St Jeor equation
  double _calculateBMR({
    required String gender,
    required int age,
    required double height,
    required double weight,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Get activity multiplier
  double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'lightly active':
        return 1.375;
      case 'moderately active':
        return 1.55;
      case 'extremely active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeScreen();
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CF),
      body: SafeArea(
        child: isLoading
            ? _buildSkeletonHomeScreen()
            : RefreshIndicator(
                onRefresh: _loadTodayData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildTodayDate(),
                      _buildDailyCaloriesWidget(),
                      _buildActionButtons(),
                      _buildCookAgainSection(),
                      _buildPublicRecipesSection(),
                      _buildTryTheseRecipesSection(),
                      _buildDiscoverRecipesSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4E7C5).withOpacity(0.6),
            const Color(0xFFFFD3AD).withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Meal',
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MuseoModerno',
                    ),
                  ),
                  TextSpan(
                    text: 'Match',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MuseoModerno',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                splashRadius: 24,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayDate() {
    String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        formattedDate,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF424242),
        ),
      ),
    );
  }

  Widget _buildDailyCaloriesWidget() {
    int remaining = userGoalCalories - consumedCalories;
    double progress = consumedCalories / userGoalCalories;
    bool isOverGoal = consumedCalories > userGoalCalories;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daily Calories',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Goal - Food = Remaining',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      children: [
                        _buildCalorieRow(
                          icon: Icons.local_fire_department,
                          iconColor: const Color(0xFFFF9800),
                          label: 'Calorie Goal',
                          value: '$userGoalCalories',
                        ),
                        const SizedBox(height: 16),
                        _buildCalorieRow(
                          icon: Icons.apple,
                          iconColor: Colors.red,
                          label: 'Calorie Intake',
                          value: '$consumedCalories',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 14,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[200]!,
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: progress > 1.0 ? 1.0 : progress,
                    strokeWidth: 14,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF9800),
                    ),
                  ),
                ),
                if (isOverGoal)
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: (progress - 1.0) > 1.0 ? 1.0 : (progress - 1.0),
                      strokeWidth: 14,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${remaining.abs()}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isOverGoal
                            ? Colors.red
                            : const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverGoal ? 'Over' : 'Remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverGoal ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              title: 'What to Cook?',
              subtitle: 'Find recipes for your pantry',
              icon: Icons.restaurant,
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pushNamed(context, '/whatcanicook');
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              title: 'Food Log',
              subtitle: 'Eat. Log. Track. Repeat.',
              icon: Icons.restaurant_menu,
              color: const Color(0xFFFF9800),
              onTap: () {
                Navigator.pushNamed(context, '/logfood').then((_) {
                  _loadTodayData();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Smart title based on user history
  Widget _buildCookAgainSection() {
    // ✅ IMPORTANT: Don't show section at all if user has no history
    if (!hasCookedRecipes && !hasLoggedMeals) {
      return const SizedBox.shrink(); // Completely hidden, no skeletons
    }

    String sectionTitle = 'Cook Again';

    // ✅ If section should show but recipes are still loading, show them as loading
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: cookAgainRecipes.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cookAgainRecipes.length,
                  itemBuilder: (context, index) {
                    return _buildRecipeCard(cookAgainRecipes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPublicRecipesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Community Recipes 👥',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: userRecipes.isEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: userRecipes.length,
                  itemBuilder: (context, index) {
                    return _buildRecipeCard(userRecipes[index]);
                  },
                ),
        ),
      ],
    );
  }

  // Try These Recipes section - shows random meals
  Widget _buildTryTheseRecipesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Try These Recipes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: tryTheseRecipes.isEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tryTheseRecipes.length,
                  itemBuilder: (context, index) {
                    return _buildRecipeCard(tryTheseRecipes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDiscoverRecipesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Discover High-Protein Recipes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: discoverProteinRecipes.isEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: discoverProteinRecipes.length,
                  itemBuilder: (context, index) {
                    return _buildRecipeCard(discoverProteinRecipes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSkeletonHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Skeleton Header
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4E7C5).withOpacity(0.6),
                  const Color(0xFFFFD3AD).withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Container(
                width: 150,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Skeleton Date
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Skeleton Daily Calories Widget
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Skeleton Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 100,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 70,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 100,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Skeleton Recipe Sections
          _buildSkeletonRecipeSection('Cook Again'),
          _buildSkeletonRecipeSection('Try These Recipes'),
          _buildSkeletonRecipeSection('Discover High-Protein Recipes'),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSkeletonRecipeSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            width: 180,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => _buildSkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton Image
          Container(
            height: 90,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skeleton Title
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Skeleton Author
                  Container(
                    height: 11,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Skeleton Cook Time
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Skeleton Bottom Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 11,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 11,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
  try {
    print('🔍 === DEBUGGING RECIPE CARD ===');
    print('Recipe ID: ${recipe['id']}');
    
    // Debug each field one by one
    print('Checking title...');
    print('  title type: ${recipe['title'].runtimeType}');
    print('  title value: ${recipe['title']}');
    
    print('Checking name...');
    print('  name type: ${recipe['name']?.runtimeType}');
    print('  name value: ${recipe['name']}');
    
    print('Checking author...');
    print('  author type: ${recipe['author']?.runtimeType}');
    print('  author value: ${recipe['author']}');
    
    print('Checking userName...');
    print('  userName type: ${recipe['userName']?.runtimeType}');
    print('  userName value: ${recipe['userName']}');
    
    print('Checking image...');
    print('  image type: ${recipe['image']?.runtimeType}');
    print('  image value: ${recipe['image']}');
    
    print('Checking readyInMinutes...');
    print('  readyInMinutes type: ${recipe['readyInMinutes']?.runtimeType}');
    print('  readyInMinutes value: ${recipe['readyInMinutes']}');
    
    print('Checking calories...');
    print('  calories type: ${recipe['calories']?.runtimeType}');
    print('  calories value: ${recipe['calories']}');
    
    print('Checking rating...');
    print('  rating type: ${recipe['rating']?.runtimeType}');
    print('  rating value: ${recipe['rating']}');
    
    print('✅ All fields checked!');
    
    // NOW try to extract - this will show exactly which line fails
    String title = 'Recipe Name';
    try {
      if (recipe['title'] != null) {
        if (recipe['title'] is String) {
          title = recipe['title'] as String;
          print('✅ Title extracted as String: $title');
        } else if (recipe['title'] is List) {
          final titleList = recipe['title'] as List;
          title = titleList.isNotEmpty ? titleList[0].toString() : 'Recipe Name';
          print('⚠️ Title was List, extracted: $title');
        } else {
          title = recipe['title'].toString();
          print('⚠️ Title was ${recipe['title'].runtimeType}, converted: $title');
        }
      } else if (recipe['name'] != null) {
        if (recipe['name'] is String) {
          title = recipe['name'] as String;
          print('✅ Name extracted as String: $title');
        } else if (recipe['name'] is List) {
          final nameList = recipe['name'] as List;
          title = nameList.isNotEmpty ? nameList[0].toString() : 'Recipe Name';
          print('⚠️ Name was List, extracted: $title');
        } else {
          title = recipe['name'].toString();
          print('⚠️ Name converted: $title');
        }
      }
    } catch (e) {
      print('❌ ERROR extracting title: $e');
      title = 'Error';
    }
    
    String author = 'Author';
    try {
      if (recipe['author'] != null) {
        if (recipe['author'] is String) {
          author = recipe['author'] as String;
        } else if (recipe['author'] is List) {
          final authorList = recipe['author'] as List;
          author = authorList.isNotEmpty ? authorList[0].toString() : 'Author';
        } else {
          author = recipe['author'].toString();
        }
      } else if (recipe['userName'] != null) {
        author = recipe['userName'].toString();
      }
      print('✅ Author extracted: $author');
    } catch (e) {
      print('❌ ERROR extracting author: $e');
      author = 'Error';
    }
    
    int cookTime = 0;
    try {
      if (recipe['readyInMinutes'] != null) {
        if (recipe['readyInMinutes'] is int) {
          cookTime = recipe['readyInMinutes'] as int;
        } else if (recipe['readyInMinutes'] is String) {
          cookTime = int.tryParse(recipe['readyInMinutes'] as String) ?? 0;
        } else {
          cookTime = int.tryParse(recipe['readyInMinutes'].toString()) ?? 0;
        }
      }
      print('✅ CookTime extracted: $cookTime');
    } catch (e) {
      print('❌ ERROR extracting cookTime: $e');
    }
    
    int calories = 0;
    try {
      if (recipe['nutrition'] != null && recipe['nutrition'] is Map) {
        final nutrition = recipe['nutrition'] as Map;
        if (nutrition['calories'] != null) {
          final caloriesVal = nutrition['calories'];
          if (caloriesVal is int) {
            calories = caloriesVal;
          } else {
            calories = int.tryParse(caloriesVal.toString()) ?? 0;
          }
        }
      } else if (recipe['calories'] != null) {
        if (recipe['calories'] is int) {
          calories = recipe['calories'] as int;
        } else {
          calories = int.tryParse(recipe['calories'].toString()) ?? 0;
        }
      }
      print('✅ Calories extracted: $calories');
    } catch (e) {
      print('❌ ERROR extracting calories: $e');
    }
    
    double rating = 4.5;
    try {
      if (recipe['rating'] != null) {
        if (recipe['rating'] is double) {
          rating = recipe['rating'] as double;
        } else if (recipe['rating'] is int) {
          rating = (recipe['rating'] as int).toDouble();
        } else {
          rating = double.tryParse(recipe['rating'].toString()) ?? 4.5;
        }
      }
      print('✅ Rating extracted: $rating');
    } catch (e) {
      print('❌ ERROR extracting rating: $e');
    }
    
    String image = '';
    try {
      if (recipe['image'] != null) {
        if (recipe['image'] is String) {
          image = recipe['image'] as String;
        } else if (recipe['image'] is List) {
          final imgList = recipe['image'] as List;
          image = imgList.isNotEmpty ? imgList[0].toString() : '';
        } else {
          image = recipe['image'].toString();
        }
      } else if (recipe['strMealThumb'] != null) {
        image = recipe['strMealThumb'].toString();
      }
      print('✅ Image extracted: $image');
    } catch (e) {
      print('❌ ERROR extracting image: $e');
    }
    
    print('🎉 All extractions complete!');

    return GestureDetector(
      onTap: () {
        print('📍 Tapping recipe: ${recipe['id']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailsScreen(recipeId: recipe['id'].toString()),
          ),
        ).then((_) {
          _loadTodayData();
        });
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      height: 90,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        width: 160,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      height: 90,
                      width: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (cookTime > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$cookTime mins',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (calories > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$calories kcal',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF424242),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ FATAL ERROR building recipe card: $e');
    print('❌ Stack trace: $stackTrace');
    print('❌ Full recipe data: $recipe');
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Error: $e',
            style: TextStyle(fontSize: 10, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() => _selectedIndex = 0);
              _loadTodayData();
              break;
            case 1:
              Navigator.pushNamed(context, '/recipes').then((_) {
                setState(() => _selectedIndex = 0);
              });
              break;
            case 2:
              Navigator.pushNamed(context, '/upload').then((_) {
                setState(() => _selectedIndex = 0);
                _loadTodayData();
              });
              break;
            case 3:
              Navigator.pushNamed(context, '/history').then((_) {
                setState(() => _selectedIndex = 0);
              });
              break;
            case 4:
              Navigator.pushNamed(context, '/profile').then((_) {
                setState(() => _selectedIndex = 0);
              });
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
              color: _selectedIndex == 0
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu,
              color: _selectedIndex == 1
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history,
              color: _selectedIndex == 3
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Log History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 4
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
