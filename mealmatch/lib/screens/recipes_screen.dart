import 'package:flutter/material.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  bool showFavorites = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> allRecipes = [];
  List<Map<String, dynamic>> displayedRecipes = [];
  bool isLoadingMore = false;
  bool allLoaded = false;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _generateDummyRecipes();
    _loadInitialRecipes();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          !allLoaded) {
        _loadMoreRecipes();
      }
    });
  }

  void _generateDummyRecipes() {
    allRecipes = List.generate(40, (index) {
      return {
        'id': index,
        'name': 'Recipe ${index + 1}',
        'kcal': '100 kcal',
        'time': '10 mins',
        'isFavorite': false,
      };
    });
  }

  void _loadInitialRecipes() {
    setState(() {
      displayedRecipes = allRecipes.take(20).toList();
      allLoaded = displayedRecipes.length >= allRecipes.length;
    });
  }

  Future<void> _loadMoreRecipes() async {
    setState(() => isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 1));

    final nextCount = displayedRecipes.length + 5;
    if (nextCount >= allRecipes.length) {
      setState(() {
        displayedRecipes = allRecipes;
        isLoadingMore = false;
        allLoaded = true;
      });
    } else {
      setState(() {
        displayedRecipes = allRecipes.take(nextCount).toList();
        isLoadingMore = false;
      });
    }
  }

  void _toggleFavorite(int id) {
    setState(() {
      final recipe = allRecipes.firstWhere((element) => element['id'] == id);
      recipe['isFavorite'] = !recipe['isFavorite'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = showFavorites
        ? displayedRecipes.where((r) => r['isFavorite']).toList()
        : displayedRecipes;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6D7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: filteredRecipes.isEmpty && showFavorites
                  ? const Center(
                      child: Text(
                        "You have no favorite recipes yet.\nTry liking some recipes!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount: filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = filteredRecipes[index];
                                return _buildRecipeCard(recipe);
                              },
                            ),

                            const SizedBox(height: 16),

                            if (isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),

                            if (!showFavorites && allLoaded && !isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "- No more results -",
                                    style: TextStyle(color: Colors.grey),
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
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for recipes',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.filter_list, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab("Discover", !showFavorites, () {
            setState(() => showFavorites = false);
          }),
          const SizedBox(width: 24),
          _buildTab("Favorites", showFavorites, () {
            setState(() => showFavorites = true);
          }),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(width: 80, height: 2, color: const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      "Insert Picture Here",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                // child: ClipRRect(
                //   borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                //   child: Image.asset('assets/images/recipe${recipe['id']}.jpg', fit: BoxFit.cover),
                // ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: Icon(
                      recipe['isFavorite']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe['isFavorite']
                          ? Colors.red
                          : Colors.grey.shade400,
                    ),
                    onPressed: () => _toggleFavorite(recipe['id']),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe['kcal'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      recipe['time'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          setState(() {
            _selectedIndex = index;
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
