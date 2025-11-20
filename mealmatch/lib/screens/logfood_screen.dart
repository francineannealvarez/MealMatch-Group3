// 📁 lib/screens/logfood_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_api_service.dart';
import '../models/fooditem.dart';
import 'modifyfood_screen.dart';
import '../services/favorites_service.dart';
import '../services/themealdb_service.dart';

class LogFood extends StatelessWidget {
  const LogFood({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF9E6),
      ),
      home: const SelectMealScreen(),
    );
  }
}

class SelectMealScreen extends StatefulWidget {
  const SelectMealScreen({super.key});

  @override
  State<SelectMealScreen> createState() => _SelectMealScreenState();
}

class _SelectMealScreenState extends State<SelectMealScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FoodApiService _apiService = FoodApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedMeal;
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String _searchMessage = 'Search for foods to get started';

  List<FoodItem> _recentFoods = [];
  bool _isLoadingRecent = true;

  int _userGoalCalories = 2000;
  int _todayConsumedCalories = 0;
  bool _hasShownInitialWarning = false;

  List<Widget> _buildQuickMealOptions() {
    final meals = [
      {'name': 'Breakfast', 'icon': Icons.wb_sunny_outlined},
      {'name': 'Lunch', 'icon': Icons.restaurant_outlined},
      {'name': 'Dinner', 'icon': Icons.dinner_dining_outlined},
      {'name': 'Snacks', 'icon': Icons.cookie_outlined},
    ];

    return meals.map((meal) {
      return InkWell(
        onTap: () {
          Navigator.pop(context, meal['name'] as String);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.shade200, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  meal['icon'] as IconData,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  meal['name'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRecentFoodsFromLogs();
    _loadCalorieData();
  }

  Future<void> _loadCalorieData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('calorieGoal')) {
          _userGoalCalories = data['calorieGoal'] as int;
        }
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final todayLogs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .where('date', isEqualTo: dateStr)
          .get();

      int totalCalories = 0;
      for (var doc in todayLogs.docs) {
        final data = doc.data();
        totalCalories += (data['calories'] as num).toInt();
      }

      setState(() {
        _todayConsumedCalories = totalCalories;
      });

      if (_todayConsumedCalories > _userGoalCalories &&
          !_hasShownInitialWarning) {
        _hasShownInitialWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCalorieWarningDialog();
        });
      }
    } catch (e) {
      print('Error loading calorie data: $e');
    }
  }

  void _showCalorieWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Over Your Goal!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have gone over your calorie goal for today.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Goal:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_userGoalCalories cal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Consumed:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_todayConsumedCalories cal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Over by:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${_todayConsumedCalories - _userGoalCalories} cal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to continue adding food?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // prev screen
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close warning
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _loadRecentFoodsFromLogs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final mealLogsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (mealLogsQuery.docs.isEmpty) {
        setState(() => _isLoadingRecent = false);
        return;
      }

      final seenFoods = <String>{};
      final recentFoods = <FoodItem>[];

      for (var doc in mealLogsQuery.docs) {
        final data = doc.data();
        final foodName = data['foodName'] as String?;
        if (foodName != null && !seenFoods.contains(foodName)) {
          seenFoods.add(foodName);
          recentFoods.add(FoodItem.fromMealLog(doc));
          if (recentFoods.length >= 7) break;
        }
      }

      setState(() {
        _recentFoods = recentFoods;
        _isLoadingRecent = false;
      });
    } catch (e) {
      print('Error loading recent foods: $e');
      setState(() => _isLoadingRecent = false);
    }
  }

  Future<void> _searchApiFood(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchMessage = 'Search for foods to get started';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchMessage = 'Searching...';
    });

    try {
      final results = await _apiService.searchAllSources(query);

      setState(() {
        _searchResults = results
            .map((data) => FoodItem.fromApiData(data))
            .toList();
        _isSearching = false;
        _searchMessage = results.isEmpty
            ? 'No results found. Try different keywords.'
            : '';
      });
    } catch (e) {
      print('❌ API search error: $e');
      setState(() {
        _isSearching = false;
        _searchMessage = 'Error searching. Check your internet connection.';
      });
    }
  }

  Future<void> _addFoodToMeal(FoodItem food, String mealCategory) async {
    if (_todayConsumedCalories > _userGoalCalories) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFF9E6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.orange, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Still Over Goal!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You\'re already over your calorie goal today.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_todayConsumedCalories cal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Adding:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${food.calories.toInt()} cal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.grey.shade300),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_todayConsumedCalories + food.calories.toInt()} cal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Continue adding this food?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Anyway',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      if (shouldContinue != true) return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .add({
            'userId': user.uid,
            'category': mealCategory,
            'foodName': food.name,
            'calories': food.calories,
            'carbs': food.carbs,
            'fats': food.fat,
            'proteins': food.protein,
            'serving': food.servingsize,
            'timestamp': FieldValue.serverTimestamp(),
            'date': dateStr,
            'brand': food.brand,
            'isVerified': food.isVerified,
            'source': food.source,
          });

      setState(() {
        _todayConsumedCalories += food.calories.toInt();
      });

      _loadRecentFoodsFromLogs();

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${food.name} added to $mealCategory!',
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMealSelectDialog() async {
    final meal = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orange.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Select a Meal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1.5, color: Colors.orange),
            ..._buildMealOptions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (meal != null) {
      setState(() => _selectedMeal = meal);
    }
  }

  List<Widget> _buildMealOptions() {
    final meals = [
      {'name': 'Breakfast', 'icon': Icons.breakfast_dining_outlined},
      {'name': 'Lunch', 'icon': Icons.lunch_dining_outlined},
      {'name': 'Dinner', 'icon': Icons.dinner_dining_outlined},
      {'name': 'Snacks', 'icon': Icons.cookie_outlined},
    ];

    return meals.map((meal) {
      final isSelected = _selectedMeal == meal['name'];
      return InkWell(
        onTap: () {
          Navigator.pop(context, meal['name'] as String);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.orange.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  meal['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  meal['name'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.orange.shade800 : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.orange.shade700,
                  size: 26,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildAllTab(),
      FavoritesTab(userId: _auth.currentUser!.uid, selectedMeal: _selectedMeal),
      MyRecipesTab(userId: _auth.currentUser!.uid, selectedMeal: _selectedMeal),
    ];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showMealSelectDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedMeal ?? 'Select a Meal',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.orange),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF9E6),
        elevation: 0.3,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFF9E6),
            child: Row(
              children: [
                _buildTab('All', 0),
                _buildTab('Favorites', 1),
                _buildTab('My Recipes', 2),
              ],
            ),
          ),
          Expanded(child: tabs[_selectedTab]),
        ],
      ),
    );
  }

  // === All Tab ===
  Widget _buildAllTab() => Column(
    children: [
      Padding(padding: const EdgeInsets.all(16.0), child: _buildSearchBar()),
      Expanded(
        child: ListView(
          children: [
            if (_searchResults.isNotEmpty) ...[
              _buildSectionHeader('Search Results'),
              ..._searchResults.map((food) => _buildFoodItem(food)),
              const Divider(height: 32, thickness: 2),
            ],
            if (!_isLoadingRecent && _recentFoods.isNotEmpty) ...[
              _buildSectionHeader('Recently Logged'),
              ..._recentFoods.map((food) => _buildFoodItem(food)),
            ],
            if (_searchResults.isEmpty && _recentFoods.isEmpty && !_isSearching)
              _buildEmptyMessage(),
          ],
        ),
      ),
    ],
  );

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search 380,000+ foods (press Enter)',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                )
              : _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _searchMessage = 'Search for foods to get started';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        onSubmitted: _searchApiFood,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    bool isAdded = false;

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModifyFoodScreen(
                    food: food,
                    preselectedMeal: _selectedMeal,
                  ),
                ),
              ).then((_) {
                _loadRecentFoodsFromLogs();
                _loadCalorieData();
              });
            },
            title: Text(
              food.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              '${food.calories.toStringAsFixed(0)} cal${food.brand.isNotEmpty ? ', ${food.brand}' : ''}, ${food.servingsize}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            trailing: GestureDetector(
              onTapDown: (details) async {
                String? meal = _selectedMeal;
                meal ??= await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Add to Meal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1.5,
                          color: Colors.orange,
                        ),
                        ..._buildQuickMealOptions(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );

                if (meal != null) {
                  await _addFoodToMeal(food, meal);
                  setStateLocal(() => isAdded = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setStateLocal(() => isAdded = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAdded ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAdded ? Icons.check : Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchMessage,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// === Favorites Tab ===
class FavoritesTab extends StatefulWidget {
  final String userId;
  final String? selectedMeal;

  const FavoritesTab({
    super.key,
    required this.userId,
    required this.selectedMeal,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  List<Map<String, dynamic>> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      // Get favorite recipe IDs
      final favoriteIds = await FavoritesService.loadFavoriteIds();

      // Fetch full recipe data for each ID
      final recipes = <Map<String, dynamic>>[];
      for (String id in favoriteIds) {
        final details = await TheMealDBService.getMealDetails(id);
        if (details != null) {
          recipes.add(details);
        }
      }

      setState(() {
        _favoriteRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRecipeToMeal(
    String recipeId,
    String recipeName,
    int calories,
    String? meal,
  ) async {
    if (meal == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFFFFF9E6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.orange, width: 2),
          ),
          title: const Text('Select Meal'),
          content: const Text(
            'Please select a meal category before adding food.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .add({
            'userId': user.uid,
            'category': meal,
            'foodName': recipeName,
            'calories': calories,
            'timestamp': FieldValue.serverTimestamp(),
            'date': dateStr,
            'recipeId': recipeId,
          });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green.shade600,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$recipeName added to $meal!',
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_favoriteRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'No Favorites Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start adding your favorite recipes\nto see them here!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/recipes');
                },
                icon: const Icon(Icons.explore, size: 22),
                label: const Text(
                  'Discover Recipes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _favoriteRecipes[index];
          final recipeId = recipe['id'].toString();
          final recipeName = recipe['title'] ?? 'Recipe';
          final calories = recipe['nutrition']?['calories'] ?? 0;
          final image = recipe['image'] ?? '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 30),
                      ),
              ),
              title: Text(
                recipeName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$calories cal',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: () async {
                  await _addRecipeToMeal(
                    recipeId,
                    recipeName,
                    calories,
                    widget.selectedMeal,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// === My Recipes Tab ===
class MyRecipesTab extends StatefulWidget {
  final String userId;
  final String? selectedMeal;

  const MyRecipesTab({
    super.key,
    required this.userId,
    required this.selectedMeal,
  });

  @override
  State<MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends State<MyRecipesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recipes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to load recipes with a timeout
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: widget.userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      final recipes = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _addRecipeToMeal(
    String recipeName,
    int? calories,
    String? meal,
  ) async {
    if (meal == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFFFFF9E6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.orange, width: 2),
          ),
          title: const Text('Select Meal'),
          content: const Text(
            'Please select a meal category before adding food.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .add({
            'userId': user.uid,
            'category': meal,
            'foodName': recipeName,
            'calories': calories ?? 0,
            'timestamp': FieldValue.serverTimestamp(),
            'date': dateStr,
          });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green.shade600,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$recipeName added to $meal!',
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Loading your recipes...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to Load Recipes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadRecipes,
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 24),
              const Text(
                "Inay's Pansit isn't in the database (yet)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create and save your own custom recipes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text(
                  'Create Recipe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List of recipes
    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          final recipeName = recipe['name'] ?? 'Unnamed Recipe';
          final calories = recipe['calories'] as int?;
          final image = recipe['image'] as String?;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.orange.shade100,
                        child: Icon(
                          Icons.restaurant,
                          size: 30,
                          color: Colors.orange.shade700,
                        ),
                      ),
              ),
              title: Text(
                recipeName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                calories != null ? '$calories cal' : 'Custom recipe',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: () async {
                  await _addRecipeToMeal(
                    recipeName,
                    calories,
                    widget.selectedMeal,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
