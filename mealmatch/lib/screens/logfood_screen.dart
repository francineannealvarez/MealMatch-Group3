// 📁 lib/screens/logfood_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/food_api_service.dart';
import '../models/fooditem.dart';
import 'modifyfood_screen.dart';

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
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore.collection('meal_logs').add({
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
    final meal = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 100, 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
          .map(
            (meal) => PopupMenuItem<String>(
              value: meal,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(meal, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          )
          .toList(),
    );

    if (meal != null) {
      setState(() => _selectedMeal = meal);
    }
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
              ).then((_) => _loadRecentFoodsFromLogs());
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
                if (meal == null) {
                  meal = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx - 70,
                      details.globalPosition.dy + 30,
                      details.globalPosition.dx,
                      0,
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                        .map(
                          (m) => PopupMenuItem<String>(
                            value: m,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  m,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

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
class FavoritesTab extends StatelessWidget {
  final String userId;
  final String? selectedMeal;

  const FavoritesTab({
    super.key,
    required this.userId,
    required this.selectedMeal,
  });

  Future<void> _addRecipeToMeal(
    BuildContext context,
    String recipeName,
    String? meal,
  ) async {
    if (meal == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Meal'),
          content: const Text(
            'Please select a meal category before adding food.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('meal_logs').add({
      'userId': user!.uid,
      'category': meal,
      'foodName': recipeName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade600,
        content: Text('$recipeName added to $meal!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No favorites yet.'));
        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? 'Unnamed'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.orange),
                onPressed: () =>
                    _addRecipeToMeal(context, data['name'], selectedMeal),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// === My Recipes Tab ===
class MyRecipesTab extends StatelessWidget {
  final String userId;
  final String? selectedMeal;

  const MyRecipesTab({
    super.key,
    required this.userId,
    required this.selectedMeal,
  });

  Future<void> _addRecipeToMeal(
    BuildContext context,
    String recipeName,
    String? meal,
  ) async {
    if (meal == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Meal'),
          content: const Text(
            'Please select a meal category before adding food.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('meal_logs').add({
      'userId': user!.uid,
      'category': meal,
      'foodName': recipeName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade600,
        content: Text('$recipeName added to $meal!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 80, color: Colors.orange),
                SizedBox(height: 16),
                Text("Mom’s Meatloaf Isn’t In The Database (Yet)."),
              ],
            ),
          );
        }
        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? 'Unnamed'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.orange),
                onPressed: () =>
                    _addRecipeToMeal(context, data['name'], selectedMeal),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
