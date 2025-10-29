// 📁 lib/screens/logfood_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_api_service.dart';
import '../models/fooditem.dart';
import 'modifyfood_screen.dart';

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
  final FoodApiService _apiService = FoodApiService();

  String? _selectedMeal;
  final List<String> _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String _searchMessage = 'Search for foods to get started';

  List<FoodItem> _recentFoods = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFoodsFromLogs();
  }

  Future<void> _loadRecentFoodsFromLogs() async {
    try {
      final mealLogsQuery = await _firestore
          .collection('meal_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (mealLogsQuery.docs.isEmpty) {
        setState(() {
          _isLoadingRecent = false;
        });
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
      setState(() {
        _isLoadingRecent = false;
      });
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

      print('🎯 Total results: ${results.length}');

      setState(() {
        _searchResults = results
            .map((data) => FoodItem.fromApiData(data))
            .toList();
        _isSearching = false;
        _searchMessage = results.isEmpty
            ? 'No results found. Try different keywords.'
            : '';

        print('📋 Displaying ${_searchResults.length} items');
      });
    } catch (e) {
      print('❌ API search error: $e');
      setState(() {
        _isSearching = false;
        _searchMessage = 'Error searching. Check your internet connection.';
      });
    }
  }

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
        'serving': food.servingsize,
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr,
        'brand': food.brand,
        'isVerified': food.isVerified, // ← NEW: Save verified status
        'source': food.source, // ← NEW: Save source
      });

      await _loadRecentFoodsFromLogs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} added to $mealCategory!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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

  void _handleAddFood(FoodItem food) {
    if (_selectedMeal == null) {
      _showMealSelectionDialog(food);
    } else {
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
                              _searchMessage =
                                  'Search for foods to get started';
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
                onSubmitted: (value) => _searchApiFood(value),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

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

                if (_searchResults.isEmpty &&
                    _recentFoods.isEmpty &&
                    !_isSearching)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Try searching:\n"chicken", "rice", "banana", "energen"',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
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
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (title == 'Search Results')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ONLINE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    final isFromApi = food.id.startsWith('api_');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFromApi
            ? Border.all(color: Colors.blue.shade200, width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ModifyFoodScreen(food: food, preselectedMeal: _selectedMeal),
            ),
          ).then((_) {
            _loadRecentFoodsFromLogs();
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                food.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            // ← NEW: Verified Badge
            if (food.isVerified)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 2),
                    Text(
                      food.source == 'USDA' ? 'USDA' : 'OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${food.calories.toStringAsFixed(0)} cal${food.brand.isNotEmpty ? ', ${food.brand}' : ''}, ${food.servingsize}',
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
