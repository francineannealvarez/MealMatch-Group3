// lib/screens/homepage_screen.dart

import 'package:flutter/material.dart';
import '../services/calorielog_history_service.dart';
import '../services/firebase_service.dart';
//import '../models/meal_log.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LogService _logService = LogService();
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;

  int userGoalCalories = 2000;
  int consumedCalories = 0;
  bool isLoading = true;

  // NEW: User stats for metabolism card
  Map<String, dynamic>? userData;
  double? userBMR;
  double? userTDEE;

  late Future<Map<String, dynamic>?> _deletionCheckFuture;
  bool _deletionDialogShown = false; // Prevent multiple dialogs

  @override
  void initState() {
    super.initState();
    _deletionCheckFuture = _firebaseService.checkDeletionStatus();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() => isLoading = true);

    try {
      // Load user data for metabolism calculations
      userData = await _logService.getUserData();

      // Calculate BMR and TDEE if we have user data
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

      // Load user's calorie goal
      final goal = await _firebaseService.getUserCalorieGoal();
      if (goal != null) {
        userGoalCalories = goal;
      }

      // Load today's logs
      final logs = await _logService.getTodayLogs();
      consumedCalories = _logService.calculateTotalCalories(logs).toInt();
    } catch (e) {
      print('Error loading today\'s data: $e');
    }

    setState(() => isLoading = false);
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
    // Wrap everything in FutureBuilder
    return FutureBuilder<Map<String, dynamic>?>(
      future: _deletionCheckFuture,
      builder: (context, snapshot) {
        // Show loading while checking deletion status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF5CF),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            ),
          );
        }

        // Check if account is scheduled for deletion
        final deletionStatus = snapshot.data;
        if (deletionStatus != null && 
            deletionStatus['isScheduled'] == true && 
            !_deletionDialogShown) {
          // Show dialog after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_deletionDialogShown) {
              _deletionDialogShown = true;
              _showDeletionWarningDialog(deletionStatus);
            }
          });
        }

        // Show normal home screen
        return _buildHomeScreen();
      },
    );
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
                      _buildSearchBar(),
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

  // Deletion warning dialog
  void _showDeletionWarningDialog(Map<String, dynamic> deletionStatus) {
    final daysRemaining = deletionStatus['daysRemaining'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFFFF5CF),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Account Deletion Scheduled',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account is scheduled for permanent deletion in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}.',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Would you like to cancel the deletion and restore your account?',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Continue with deletion - sign out
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );

                await _firebaseService.signOut();
                
                if (!mounted) return;
                Navigator.pop(context);
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Continue Deletion',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading immediately
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => WillPopScope(
                    onWillPop: () async => false,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    ),
                  ),
                );

                try {
                  // Cancel deletion
                  final result = await _firebaseService.cancelAccountDeletion();

                  if (!mounted) return;

                  // Close loading
                  Navigator.pop(context);
                  // Close the deletion dialog
                  Navigator.pop(context);

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(child: Text('Account restored successfully!')),
                          ],
                        ),
                        backgroundColor: Color(0xFF4CAF50),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to restore account. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Restore Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search for recipes with any ingredients',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: Icon(Icons.search, color: Colors.grey),
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
          fontSize: 16,
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

  Widget _buildCookAgainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Cook Again',
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
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildRecipeCard();
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildRecipeCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard() {
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
          Container(
            height: 90,
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
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  const Text(
                    'Recipe Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Author',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Cooking time - Food Type',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Must Have Ingredients:',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Color(0xFFFF9800),
                          ),
                          SizedBox(width: 2),
                          Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Ratings',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
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
              Navigator.pushNamed(context, '/logfood').then((_) {
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
