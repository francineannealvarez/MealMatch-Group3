import 'package:flutter/material.dart';

class WhatCanICookScreen extends StatefulWidget {
  const WhatCanICookScreen({super.key});

  @override
  State<WhatCanICookScreen> createState() => _WhatCanICookScreenState();
}

class _WhatCanICookScreenState extends State<WhatCanICookScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isFiltered = false;
  bool isLoading = false;
  String searchQuery = '';

  Map<String, List<String>> selectedIngredients = {
    'Protein / Meat': [],
    'Vegetables': [],
    'Grains & Carbs': [],
    'Sauces & Condiments': [],
    'Dairy & Eggs': [],
    'Spices & Herbs': [],
  };

  Map<String, bool> expandedCategories = {
    'Protein / Meat': false,
    'Vegetables': false,
    'Grains & Carbs': false,
    'Sauces & Condiments': false,
    'Dairy & Eggs': false,
    'Spices & Herbs': false,
  };

  final Map<String, List<String>> ingredientOptions = {
    'Protein / Meat': ['Chicken', 'Pork', 'Beef', 'Fish', 'Eggs', 'Tofu'],
    'Vegetables': [
      'Tomato',
      'Onion',
      'Garlic',
      'Carrot',
      'Cabbage',
      'Potato',
      'Bell Pepper',
    ],
    'Grains & Carbs': ['Rice', 'Noodles', 'Pasta', 'Bread'],
    'Sauces & Condiments': [
      'Soy Sauce',
      'Vinegar',
      'Tomato Sauce',
      'Oyster Sauce',
    ],
    'Dairy & Eggs': ['Milk', 'Cheese', 'Butter', 'Eggs'],
    'Spices & Herbs': ['Salt', 'Pepper', 'Bay Leaf', 'Ginger'],
  };

  final Map<String, IconData> categoryIcons = {
    'Protein / Meat': Icons.set_meal,
    'Vegetables': Icons.local_florist,
    'Grains & Carbs': Icons.grain,
    'Sauces & Condiments': Icons.liquor,
    'Dairy & Eggs': Icons.water_drop,
    'Spices & Herbs': Icons.eco,
  };

  // sample data demo
  final List<Map<String, dynamic>> completeMatches = [
    {
      'name': 'Chicken Adobo',
      'author': 'Maria Santos',
      'cookingTime': '45 mins',
      'foodType': 'Filipino',
      'calories': '320',
      'ratings': '4.8',
      'ingredients': ['Chicken', 'Soy Sauce', 'Vinegar', 'Garlic'],
    },
    {
      'name': 'Sinigang na Baboy',
      'author': 'Juan Dela Cruz',
      'cookingTime': '1 hour',
      'foodType': 'Filipino',
      'calories': '280',
      'ratings': '4.7',
      'ingredients': ['Pork', 'Tamarind', 'Tomato', 'Onion'],
    },
  ];

  final List<Map<String, dynamic>> partialMatches = [
    {
      'name': 'Beef Caldereta',
      'author': 'Ana Reyes',
      'cookingTime': '1.5 hours',
      'foodType': 'Filipino',
      'calories': '450',
      'ratings': '4.9',
      'ingredients': ['Beef', 'Tomato Sauce', 'Potato', 'Carrot'],
      'missingIngredients': ['Liver Spread', 'Bell Pepper'],
    },
    {
      'name': 'Pancit Canton',
      'author': 'Pedro Garcia',
      'cookingTime': '30 mins',
      'foodType': 'Filipino',
      'calories': '380',
      'ratings': '4.6',
      'ingredients': ['Noodles', 'Cabbage', 'Carrot'],
      'missingIngredients': ['Soy Sauce'],
    },
  ];

  void _toggleIngredient(String category, String ingredient) {
    setState(() {
      if (selectedIngredients[category]!.contains(ingredient)) {
        selectedIngredients[category]!.remove(ingredient);
      } else {
        selectedIngredients[category]!.add(ingredient);
      }
      isFiltered = false;
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      expandedCategories[category] = !expandedCategories[category]!;
    });
  }

  int _getTotalSelectedCount() {
    int total = 0;
    selectedIngredients.forEach((key, value) {
      total += value.length;
    });
    return total;
  }

  List<String> _getFilteredCategories() {
    if (searchQuery.isEmpty) {
      return ingredientOptions.keys.toList();
    }

    List<String> filteredCategories = [];
    ingredientOptions.forEach((category, ingredients) {
      bool hasMatch = ingredients.any(
        (ingredient) =>
            ingredient.toLowerCase().contains(searchQuery.toLowerCase()),
      );
      if (hasMatch) {
        filteredCategories.add(category);
      }
    });
    return filteredCategories;
  }

  List<String> _getFilteredIngredients(String category) {
    if (searchQuery.isEmpty) {
      return ingredientOptions[category]!;
    }

    return ingredientOptions[category]!
        .where(
          (ingredient) =>
              ingredient.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      if (value.isNotEmpty) {
        ingredientOptions.forEach((category, ingredients) {
          bool hasMatch = ingredients.any(
            (ingredient) =>
                ingredient.toLowerCase().contains(value.toLowerCase()),
          );
          if (hasMatch) {
            expandedCategories[category] = true;
          }
        });
      }
    });
  }

  Future<void> _filterRecipes() async {
    if (_getTotalSelectedCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select ingredients first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate loading for fetching recipes
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
      isFiltered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'What Can I Cook?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finding meals based on\nyour available ingredients...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Your Available Ingredients:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search ingredients...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._getFilteredCategories().map((category) {
                          int selectedCount =
                              selectedIngredients[category]!.length;
                          bool isExpanded = expandedCategories[category]!;
                          List<String> filteredIngredients =
                              _getFilteredIngredients(category);
                          if (filteredIngredients.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              _buildCategoryHeader(
                                category,
                                selectedCount,
                                isExpanded,
                              ),
                              if (isExpanded)
                                _buildCategoryItems(
                                  category,
                                  filteredIngredients,
                                ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                        // Show message if no results
                        if (_getFilteredCategories().isEmpty ||
                            _getFilteredCategories().every(
                              (cat) => _getFilteredIngredients(cat).isEmpty,
                            ))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No ingredients found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isFiltered)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _filterRecipes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Find Recipes (${_getTotalSelectedCount()} selected)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isFiltered) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Complete Matches',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...completeMatches.map((recipe) {
                      return _buildRecipeCard(
                        recipe: recipe,
                        isPartialMatch: false,
                      );
                    }).toList(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: const Color(0xFFFFA726),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Partial Matches',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...partialMatches.map((recipe) {
                      return _buildRecipeCard(
                        recipe: recipe,
                        isPartialMatch: true,
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoryHeader(
    String category,
    int selectedCount,
    bool isExpanded,
  ) {
    return GestureDetector(
      onTap: () => _toggleCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selectedCount > 0
              ? const Color(0xFFD4E7C5)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                categoryIcons[category],
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
            ),
            Text(
              '($selectedCount selected)',
              style: TextStyle(
                fontSize: 13,
                color: selectedCount > 0
                    ? const Color(0xFF4CAF50)
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItems(String category, [List<String>? filteredList]) {
    List<String> ingredientsToShow =
        filteredList ?? ingredientOptions[category]!;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: ingredientsToShow.map((ingredient) {
          bool isSelected = selectedIngredients[category]!.contains(ingredient);

          bool isMatch =
              searchQuery.isNotEmpty &&
              ingredient.toLowerCase().contains(searchQuery.toLowerCase());

          return GestureDetector(
            onTap: () => _toggleIngredient(category, ingredient),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4E7C5) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isMatch && !isSelected
                    ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ingredient,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF424242),
                      fontWeight: isSelected || isMatch
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeCard({
    required Map<String, dynamic> recipe,
    required bool isPartialMatch,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Text(
                'Insert Picture Here',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recipe['author'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
                              Text(
                                '${recipe['cookingTime']} - ${recipe['foodType']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Ratings',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isPartialMatch && recipe['missingIngredients'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Missing: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E42),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: (recipe['missingIngredients'] as List)
                                .map((ingredient) {
                                  return Text(
                                    ingredient,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF424242),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border, size: 16),
                          label: const Text(
                            'Save',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.restaurant, size: 16),
                          label: const Text(
                            'Cook Now',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBottomNavigationBar() {
    int selectedIndex = 0;
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
        currentIndex: selectedIndex,
        onTap: (index) {
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: selectedIndex == 0 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu,
              color: selectedIndex == 1 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Recipes',
          ),
          const BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history,
              color: selectedIndex == 3 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Log History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: selectedIndex == 4 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Profile',
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
