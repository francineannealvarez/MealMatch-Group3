// 📁 lib/screens/logfood_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const LogFood());
}

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

class FoodItem {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double servingsamount;
  final String servingsize;

  FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.servingsamount,
    required this.servingsize,
  });

  factory FoodItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      servingsamount: (data['servingsamount'] ?? 0).toDouble(),
      servingsize: data['servingsize'] ?? '',
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
  int _selectedBottomNav = 0;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Selected meal category
  String? _selectedMeal;
  final List<String> _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  // Recent foods cache
  List<FoodItem> _recentFoods = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  // Load recent foods on init
  Future<void> _loadRecentFoods() async {
    final recent = await _getRecentFoodsFromLogs();
    setState(() {
      _recentFoods = recent;
      _isLoadingRecent = false;
    });
  }

  // Stream to get all foods from Firestore
  Stream<List<FoodItem>> _getAllFoods() {
    return _firestore.collection('foods').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FoodItem.fromDoc(doc)).toList();
    });
  }

  // Get recent foods from meal logs
  Future<List<FoodItem>> _getRecentFoodsFromLogs() async {
    try {
      // Get recent meal logs
      final mealLogsQuery = await _firestore
          .collection('meal_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (mealLogsQuery.docs.isEmpty) {
        print('No meal logs found');
        return [];
      }

      print('Found ${mealLogsQuery.docs.length} meal logs');

      // Get unique food names
      final uniqueFoodNames = <String>{};
      final recentFoodNames = <String>[];

      for (var doc in mealLogsQuery.docs) {
        final data = doc.data();
        final foodName = data['foodName'] as String?;
        print('Meal log: $foodName');

        if (foodName != null && !uniqueFoodNames.contains(foodName)) {
          uniqueFoodNames.add(foodName);
          recentFoodNames.add(foodName);
          if (recentFoodNames.length >= 7) break;
        }
      }

      print('Unique food names: $recentFoodNames');

      // Fetch full food details
      final recentFoods = <FoodItem>[];
      for (var foodName in recentFoodNames) {
        final foodQuery = await _firestore
            .collection('foods')
            .where('name', isEqualTo: foodName)
            .limit(1)
            .get();

        if (foodQuery.docs.isNotEmpty) {
          recentFoods.add(FoodItem.fromDoc(foodQuery.docs.first));
          print('Added to recent: $foodName');
        }
      }

      print('Total recent foods: ${recentFoods.length}');
      return recentFoods;
    } catch (e) {
      print('Error getting recent foods: $e');
      return [];
    }
  }

  // Search foods
  List<FoodItem> _filterFoods(List<FoodItem> foods, String query) {
    if (query.isEmpty) return foods;
    return foods
        .where(
          (food) =>
              food.name.toLowerCase().contains(query.toLowerCase()) ||
              food.brand.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Show meal selection dialog
  void _showMealSelectionDialog(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealOptions.map((meal) {
            return ListTile(
              title: Text(meal),
              onTap: () {
                Navigator.pop(context);
                _addFoodToMeal(food, meal);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Add food to meal log
  Future<void> _addFoodToMeal(FoodItem food, String mealCategory) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore.collection('meal_logs').add({
        'category': mealCategory,
        'foodName': food.name,
        'calories': food.calories,
        'carbs': food.carbs,
        'fats': food.fat,
        'proteins': food.protein,
        'servings': food.servingsamount,
        'servingSize': food.servingsize,
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr,
        'brand': food.brand,
      });

      // Reload recent foods after adding
      await _loadRecentFoods();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food.name} added to $mealCategory!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding food: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle add button click
  void _handleAddFood(FoodItem food) {
    if (_selectedMeal == null) {
      // Show meal selection dialog if no meal is selected
      _showMealSelectionDialog(food);
    } else {
      // Add directly to selected meal
      _addFoodToMeal(food, _selectedMeal!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            _showMealDropdown();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedMeal ?? 'Select a Meal',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: Column(
        children: [
          // Tabs
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search for a food',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          // Food Lists with StreamBuilder
          Expanded(
            child: StreamBuilder<List<FoodItem>>(
              stream: _getAllFoods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No foods found. Add foods to Firestore!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final allFoods = _filterFoods(
                  snapshot.data!,
                  _searchController.text,
                );

                // Filter recent foods based on search
                final filteredRecentFoods = _filterFoods(
                  _recentFoods,
                  _searchController.text,
                );

                // Get suggestions (exclude recent foods)
                final recentFoodIds = _recentFoods.map((f) => f.id).toSet();
                final suggestions = allFoods
                    .where((food) => !recentFoodIds.contains(food.id))
                    .toList();

                return ListView(
                  children: [
                    if (_isLoadingRecent)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filteredRecentFoods.isNotEmpty) ...[
                      _buildSectionHeader('Recent'),
                      ...filteredRecentFoods.map(
                        (food) => _buildFoodItem(food),
                      ),
                    ],

                    if (suggestions.isNotEmpty) ...[
                      _buildSectionHeader('Suggestions'),
                      ...suggestions.map((food) => _buildFoodItem(food)),
                    ],

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          currentIndex: _selectedBottomNav,
          onTap: (index) {
            setState(() {
              _selectedBottomNav = index;
            });

            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/home');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/recipes');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/add');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/history');
                break;
              case 4:
                Navigator.pushReplacementNamed(context, '/profile');
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
                _selectedBottomNav == 0 ? Icons.home : Icons.home_outlined,
                color: _selectedBottomNav == 0
                    ? const Color(0xFF4CAF50)
                    : Colors.grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.restaurant_menu,
                color: _selectedBottomNav == 1
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
                color: _selectedBottomNav == 3
                    ? const Color(0xFF4CAF50)
                    : Colors.grey,
              ),
              label: 'Log History',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _selectedBottomNav == 4
                    ? const Color(0xFF4CAF50)
                    : Colors.grey,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Show meal dropdown menu
  void _showMealDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealOptions.map((meal) {
            return ListTile(
              title: Text(
                meal,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              onTap: () {
                setState(() {
                  _selectedMeal = meal;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
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
              color: Colors.black,
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

  Widget _buildFoodItem(FoodItem food) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '${food.calories.toStringAsFixed(0)} cal, ${food.brand}, ${food.servingsamount} ${food.servingsize}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: GestureDetector(
          onTap: () => _handleAddFood(food),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
