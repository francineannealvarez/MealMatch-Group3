import 'package:flutter/material.dart';

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
  final String name;
  final String brand;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double servingsamount;
  final String servingsize;

  FoodItem({
    required this.name,
    required this.brand,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.servingsamount,
    required this.servingsize,
  });
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

  final List<FoodItem> recentFoods = [
    FoodItem(
      name: 'Chickenjoy Thigh',
      brand: 'Jollibee',
      calories: 380,
      carbs: 15,
      protein: 25,
      fat: 22,
      servingsamount: 1.00,
      servingsize: 'pc',
    ),
    FoodItem(
      name: 'Dark Chocolate',
      brand: 'Schogetten',
      calories: 30,
      carbs: 3,
      protein: 1,
      fat: 2,
      servingsamount: 1.00,
      servingsize: 'pc',
    ),
    FoodItem(
      name: 'Meatloaf',
      brand: 'Argentina',
      calories: 80,
      carbs: 2,
      protein: 6,
      fat: 5,
      servingsamount: 56,
      servingsize: 'g',
    ),
    FoodItem(
      name: 'White rice, cooked',
      brand: '',
      calories: 204,
      carbs: 44,
      protein: 4,
      fat: 0.4,
      servingsamount: 1.00,
      servingsize: 'cup',
    ),
    FoodItem(
      name: 'Boiled eggs',
      brand: '',
      calories: 72,
      carbs: 44,
      protein: 4,
      fat: 0.4,
      servingsamount: 1.00,
      servingsize: 'egg',
    ),
  ];

  final List<FoodItem> suggestions = [
    FoodItem(
      name: 'Chicken breast, cooked, skinless',
      brand: '',
      calories: 211,
      carbs: 0,
      protein: 39,
      fat: 5,
      servingsamount: 100,
      servingsize: 'g',
    ),
    FoodItem(
      name: 'Banana',
      brand: '',
      calories: 105,
      carbs: 27,
      protein: 1,
      fat: 0.3,
      servingsamount: 1,
      servingsize: 'medium',
    ),
    FoodItem(
      name: 'Boiled eggs',
      brand: '',
      calories: 72,
      carbs: 0.6,
      protein: 6,
      fat: 5,
      servingsamount: 1,
      servingsize: 'egg',
    ),
    FoodItem(
      name: 'White rice, cooked',
      brand: '',
      calories: 204,
      carbs: 44,
      protein: 4,
      fat: 0.4,
      servingsamount: 1,
      servingsize: 'cup',
    ),
    FoodItem(
      name: 'Orange',
      brand: '',
      calories: 62,
      carbs: 15.4,
      protein: 1.2,
      fat: 0.2,
      servingsamount: 1,
      servingsize: 'medium',
    ),
    FoodItem(
      name: 'Meatloaf',
      brand: 'Argentina',
      calories: 80,
      carbs: 2,
      protein: 6,
      fat: 5,
      servingsamount: 56,
      servingsize: 'g',
    ),
    FoodItem(
      name: 'Salmon, smoked, sliced',
      brand: '',
      calories: 134,
      carbs: 0,
      protein: 20,
      fat: 5,
      servingsamount: 100,
      servingsize: 'g',
    ),
    FoodItem(
      name: 'Potato salad',
      brand: '',
      calories: 143,
      carbs: 11,
      protein: 2,
      fat: 10,
      servingsamount: 120,
      servingsize: 'g',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select a Meal',
              style: TextStyle(
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

          // Food Lists
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('Recent'),
                ...recentFoods.map((food) => _buildFoodItem(food)),

                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Show more',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                _buildSectionHeader('Suggestions'),
                ...suggestions.map((food) => _buildFoodItem(food)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNav,
        onTap: (index) {
          setState(() {
            _selectedBottomNav = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Log History',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
          '${food.calories} cal, ${food.brand}, ${food.servingsamount} ${food.servingsize}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
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
