import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  int _selectedTab = 0;
  int _selectedIndex = 4;
  bool isLoading = true;

  String userName = 'Loading...';
  String userEmail = 'loading@example.com';
  int currentStreak = 0;
  int avgDailyCalories = 0;
  int weeklyGoalDays = 0;
  int recipeCount = 0;
  int totalLikes = 0;
  String? avatarPath; // Nullable - will be null if user hasn't set avatar yet

  List<Map<String, dynamic>> achievements = [];
  List<String> newAchievementIds = [];

  Map<String, bool> likedRecipes = {
    'egg_sandwich': false,
    'banana_oatmeal': false,
    'pinoy_spaghetti': false,
  };

  Map<String, int> likeCounts = {
    'egg_sandwich': 0,
    'banana_oatmeal': 0,
    'pinoy_spaghetti': 0,
  };

  /*int get totalLikes {
    return likeCounts.values.fold(0, (sum, count) => sum + count);
  }*/

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load data from Firebase on screen open
  }

  Future<void> _loadProfileData() async {
    if (achievements.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      // Call ProfileService to get all data from Firebase at once
      final profileData = await _profileService.getProfileData();

      // Load achievements first (before setState)
      final loadedAchievements = await _profileService.getAchievements();

      // Find new achievements
      final newAchievements = loadedAchievements
          .where((a) => a['isNew'] == true)
          .toList();

      // Update state with data from Firebase
      setState(() {
        userName = profileData['name'] ?? 'User';
        userEmail = profileData['email'] ?? 'No email';
        currentStreak = profileData['streak'] ?? 0;
        avgDailyCalories = profileData['avgCalories'] ?? 0;
        weeklyGoalDays = profileData['weeklyGoalDays'] ?? 0;
        recipeCount = profileData['recipeCount'] ?? 0;
        totalLikes = profileData['totalLikes'] ?? 0;
        avatarPath = profileData['avatar']; // Can be null
        achievements = loadedAchievements;
        isLoading = false;
      });

      // Mark new achievements as viewed after a short delay (so user can see them)
      if (newAchievements.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        final idsToMark = newAchievements
            .map((a) => a['id'] as String)
            .toList();
        await _profileService.markAchievementsAsViewed(idsToMark);

        // Update UI to remove "NEW" badges after marking
        if (mounted) {
          setState(() {
            for (var achievement in achievements) {
              if (idsToMark.contains(achievement['id'])) {
                achievement['isNew'] = false;
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: _loadProfileData, // ✅ Pull to refresh
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildTabSelector(),
                    const SizedBox(height: 16),
                    if (_selectedTab == 0) _buildProgressTab(),
                    if (_selectedTab == 1) _buildMyRecipesTab(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC107), width: 3),
            color: Colors.grey[300],
          ),
          child: ClipOval(
            child: avatarPath != null
                ? Image.asset(
                    avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarPlaceholder();
                    },
                  )
                : _buildAvatarPlaceholder(), // ✅ ADDED: Show placeholder if no avatar
          ),
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(userEmail, style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(label: 'Recipes', value: '$recipeCount'),
            const SizedBox(width: 32),
            _StatItem(label: 'Likes', value: '$totalLikes'),
            const SizedBox(width: 32),
            const _StatItem(
              label: 'Followers',
              value: '0',
            ), // TODO: Implement followers
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'No Profile',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'Progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'My Recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyGoalCard(),
          const SizedBox(height: 16),
          _buildCaloriesAndStreak(),
          const SizedBox(height: 16),
          _buildAchievementsCard(),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    double progress = weeklyGoalDays / 7.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Goal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              Text(
                '$weeklyGoalDays/7 days',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF4CAF50),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            weeklyGoalDays == 0
                ? 'Start your journey today!'
                : weeklyGoalDays == 7
                ? '🎉 Amazing! You logged every day this week!'
                : 'Keep going! ${7 - weeklyGoalDays} more day${7 - weeklyGoalDays == 1 ? '' : 's'} to go!',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesAndStreak() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avg. Daily Kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$avgDailyCalories kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avgDailyCalories == 0 ? 'No data yet' : 'Last 7 days',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$currentStreak Day${currentStreak == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentStreak == 0
                      ? 'Start logging!'
                      : currentStreak == 1
                      ? 'Great start! 🔥'
                      : currentStreak >= 7
                      ? 'On fire! 🔥🔥🔥'
                      : 'Keep it up! 🔥',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎖 Achievements',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 120, // ✅ ADDED: Minimum height to prevent layout shift
            ),
            child: achievements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No achievements yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep logging to earn badges!',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: achievements.map((achievement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAchievementBadge(
                          achievement['icon'],
                          achievement['title'],
                          achievement['isNew'],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String icon, String title, bool isNew) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          width: isNew ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                    color: isNew ? const Color(0xFF4CAF50) : Colors.black,
                  ),
                ),
                // ✅ OPTIONAL: Can add description here later if you want
              ],
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyRecipesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (recipeCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recipes yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start creating your first recipe!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
          // TODO: Replace these hardcoded recipe cards with actual Firebase data
          ...[
            _buildRecipeCard(
              'egg_sandwich',
              'Egg Sandwich',
              'Breakfast • Easy • 5 mins',
              '300 kcal',
            ),
            _buildRecipeCard(
              'banana_oatmeal',
              'Banana Oatmeal',
              'Breakfast • Easy • 3 mins',
              '284 kcal',
            ),
            _buildRecipeCard(
              'pinoy_spaghetti',
              'Pinoy Sweet Spaghetti',
              'Lunch/Snacks • Medium • 25 mins',
              '321 kcal',
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add');
            },
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            label: const Text(
              'Add New Recipe',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    String recipeId,
    String name,
    String details,
    String kcal,
  ) {
    bool isLiked = likedRecipes[recipeId] ?? false;
    int likes = likeCounts[recipeId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Container(
              width: 110,
              height: 100,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        kcal,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            likedRecipes[recipeId] = !isLiked;
                            if (likedRecipes[recipeId]!) {
                              likeCounts[recipeId] = likes + 1;
                            } else {
                              likeCounts[recipeId] = likes - 1;
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${likeCounts[recipeId]}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
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
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1: // Recipes
              Navigator.pushReplacementNamed(context, '/recipes');
              break;
            case 2: // Add
              Navigator.pushNamed(context, '/add');
              break;
            case 3: // Log History
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 4: // Profile
              if (_selectedIndex == 4) {
                _loadProfileData();
              }
              setState(() {
                _selectedIndex = 4;
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
