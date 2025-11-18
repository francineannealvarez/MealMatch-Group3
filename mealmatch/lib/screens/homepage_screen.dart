import 'package:flutter/material.dart';
import '../services/calorielog_history_service.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:mealmatch/services/themealdb_service.dart'; 
import 'package:mealmatch/services/cooked_recipes_service.dart';
import 'package:mealmatch/screens/recipe_details_screen.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LogService _logService = LogService();
  final FirebaseService _firebaseService = FirebaseService();
  final CookedRecipesService _cookedService = CookedRecipesService();
  int _selectedIndex = 0;

  int userGoalCalories = 2000;
  int consumedCalories = 0;
  bool isLoading = true;

  // Recipe lists
  List<Map<String, dynamic>> cookAgainRecipes = [];
  List<Map<String, dynamic>> discoverProteinRecipes = [];

  // User stats for metabolism card
  Map<String, dynamic>? userData;
  double? userBMR;
  double? userTDEE;

  // Track if user has meal history
  bool hasLoggedMeals = false;
  bool hasCookedRecipes = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  // ✅ OPTIMIZED: Load data more efficiently
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
        userTDEE = userBMR! * _getActivityMultiplier(userData!['activityLevel']);
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
      
      // --- Phase 2: Load recipes in background (slower) ---
      _loadRecipesInBackground();
      
    } catch (e) {
      print('Error loading today\'s data: $e');
      setState(() => isLoading = false);
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

  Future<void> _loadRecipesInBackground() async {
    try {
      if (hasCookedRecipes) {
        // Load recipes based on what user has actually cooked
        cookAgainRecipes = await _getMostCookedRecipes();
      } else if (hasLoggedMeals) {
        // Fallback to meal log history
        cookAgainRecipes = await _getUserFavoriteRecipes();
      } else {
        // Load suggested recipes for new users
        cookAgainRecipes = await TheMealDBService.getRandomMeals(5);
      }
      
      // Load protein recipes with variety
      discoverProteinRecipes = await _getVariedProteinRecipes();
      
      // Update UI with recipes
      if (mounted) setState(() {});
      
    } catch (e) {
      print('Error loading recipes: $e');
    }
  }

  // Get user's most cooked recipes
  Future<List<Map<String, dynamic>>> _getMostCookedRecipes() async {
    try {
      final mostCooked = await _cookedService.getMostCookedRecipes(limit: 5);
      
      List<Map<String, dynamic>> recipes = [];
      
      for (var cookedRecipe in mostCooked) {
        final recipeId = cookedRecipe['recipeId'] as String;
        final details = await TheMealDBService.getMealDetails(recipeId);
        if (details != null) {
          recipes.add(details);
        }
      }
      
      // If not enough recipes, fill with random ones
      if (recipes.length < 5) {
        final randomMeals = await TheMealDBService.getRandomMeals(5 - recipes.length);
        recipes.addAll(randomMeals);
      }
      
      return recipes;
      
    } catch (e) {
      print('Error getting most cooked recipes: $e');
      return await TheMealDBService.getRandomMeals(5);
    }
  }


  // Get user's favorite/frequently logged meals
  Future<List<Map<String, dynamic>>> _getUserFavoriteRecipes() async {
    try {
      // Get last 60 days of logs
      final logs = await _logService.getLogsForDateRange(
        DateTime.now().subtract(const Duration(days: 60)),
        DateTime.now(),
      );
      
      // Count meal frequencies
      Map<String, int> mealFrequency = {};
      Map<String, String> mealIds = {}; // Store meal IDs
      
      for (var log in logs) {
        final mealName = log['name'] as String?;
        final mealId = log['recipeId'] as String?;
        
        if (mealName != null && mealId != null) {
          mealFrequency[mealName] = (mealFrequency[mealName] ?? 0) + 1;
          mealIds[mealName] = mealId;
        }
      }
      
      // Get top 5 most frequent meals
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
      
      // If not enough recipes, fill with random ones
      if (recipes.length < 5) {
        final randomMeals = await TheMealDBService.getRandomMeals(5 - recipes.length);
        recipes.addAll(randomMeals);
      }
      
      return recipes;
      
    } catch (e) {
      print('Error getting favorite recipes: $e');
      // Fallback to random meals
      return await TheMealDBService.getRandomMeals(5);
    }
  }

  // Get varied high-protein recipes
  Future<List<Map<String, dynamic>>> _getVariedProteinRecipes() async {
    try {
      // Rotate through different protein categories
      final proteinCategories = ['Chicken', 'Beef', 'Seafood', 'Pork'];
      final selectedCategory = proteinCategories[DateTime.now().day % proteinCategories.length];
      
      return await TheMealDBService.getMealsByCategory(selectedCategory, number: 5);
      
    } catch (e) {
      print('Error getting protein recipes: $e');
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
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
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
      child: Center(
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
    // Show different titles based on what data we have
    String sectionTitle;
    if (hasCookedRecipes) {
      sectionTitle = 'Cook Again'; // User has cooked recipes
    } else if (hasLoggedMeals) {
      sectionTitle = 'Based on Your Logs'; // User has meal logs
    } else {
      sectionTitle = 'Try These Recipes'; // New user
    }
    
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Loading recipes...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
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

  // --- UPDATED: Now uses real data ---
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: discoverProteinRecipes.length, // <-- UPDATED
            itemBuilder: (context, index) {
              return _buildRecipeCard(
                discoverProteinRecipes[index],
              ); // <-- UPDATED
            },
          ),
        ),
      ],
    );
  }

  // --- NEW: Replaced the old placeholder ---
  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    // Extract fake data from the service
    final String title = recipe['title'] ?? 'Recipe Name';
    final String author = recipe['author'] ?? 'Author';
    final int cookTime = recipe['readyInMinutes'] ?? 0;
    final int calories = recipe['nutrition']?['calories'] ?? 0;
    final double rating = recipe['rating']?.toDouble() ?? 4.5;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailsScreen(recipeId: recipe['id'].toString()),
          ),
        ).then((_) {
          // Refresh when coming back from recipe details
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
              child: Image.network(
                recipe['image'] ?? '',
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
                    const Spacer(), // Pushes the bottom row down
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
