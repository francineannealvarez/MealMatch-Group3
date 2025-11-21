import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

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
        title: const Text(
          'User Manual',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: Colors.teal[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "User's Manual",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      number: '1',
                      title: 'Introduction',
                      content:
                          'MealMatch is a mobile application that simplifies cooking and promotes healthier eating. It helps users discover recipes based on available ingredients, log their meals, and track calorie intake.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '2',
                      title: 'System Requirements',
                      content: null,
                      bulletPoints: [
                        'Android 8.0 (Oreo) or higher / iOS 13 or higher',
                        'At least 100 MB free storage',
                        'Internet connection',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '3',
                      title: 'Installation Guide',
                      content: null,
                      bulletPoints: [
                        'Download MealMatch from the App Store or Google Play Store.',
                        'Open the app and allow required permissions.',
                        'Wait until installation is complete.',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '4',
                      title: 'Account Setup',
                      content:
                          'Open the app and tap Sign Up.\nEnter the following details:',
                      bulletPoints: [
                        'Preferred Name',
                        'Goal (Lose, Maintain, Gain, or Healthy Eating)',
                        'Activity Level (Not Very Active, Lightly Active, Active, Very Active)',
                        'Basic Info (Sex, Age, Height, Weight)',
                        'Dietary Preferences & Food Restrictions',
                        'Email & Password',
                      ],
                      additionalContent:
                          'Confirm your account.\nProceed to Home/Dashboard.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '5',
                      title: 'Navigating the App Home/Dashboard',
                      content:
                          'Displays Calorie Goal, Food Logged, Remaining Calories\n\nPanels: Meal Matcher, Log Food, Recent Recipes, Weight Progress\n\nIngredient-based recipe search "What Can I Cook?" complete/partial match\n\nRecipe steps, calories, ratings, and smart timers',
                    ),
                    const SizedBox(height: 16),

                    _buildSubSection('Log Food:', [
                      'Select meal (Breakfast/Lunch/Dinner/Snack)',
                      'Search food or choose from Favorites, My Recipes, or Recent',
                      'Adjust servings and log calories',
                    ]),
                    const SizedBox(height: 16),

                    _buildSubSection('Log History:', [
                      'View previous daily food logs',
                      'Displays calories per meal and daily total',
                    ]),
                    const SizedBox(height: 16),

                    _buildSubSection('User Profile:', [
                      'Avatar, name, progress, uploaded recipes',
                    ]),
                    const SizedBox(height: 16),

                    _buildSubSection('Settings:', [
                      'Edit profile, modify goals',
                      'Change password, delete account',
                    ]),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '6',
                      title: 'Features Explained',
                      content: null,
                      bulletPoints: [
                        'Food Calorie Tracker – look up calories of specific foods',
                        'Daily Calorie Calculator – goal tracking in real time',
                        'Recipe Posting & Saving – upload and save recipes',
                        'Smart Timer – assists during cooking steps',
                        'Discover Recipes – based on filters and preferences',
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '7',
                      title: 'Troubleshooting & FAQs',
                      content: null,
                    ),
                    const SizedBox(height: 12),

                    _buildFAQ(
                      'Q: I forgot my password. What do I do?',
                      'A: Go to Login > Forgot Password and follow instructions.',
                    ),
                    const SizedBox(height: 12),

                    _buildFAQ(
                      'Q: Why can\'t I see recipes offline?',
                      'A: An internet connection is required to access recipe data.',
                    ),
                    const SizedBox(height: 12),

                    _buildFAQ(
                      'Q: Can I adjust my calorie goal later?',
                      'A: Yes, go to Settings > Modify Goals.',
                    ),
                    const SizedBox(height: 12),

                    _buildFAQ(
                      'Q: How do I delete my account?',
                      'A: Go to Settings > Delete Account.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '8',
                      title: 'Contact & Support',
                      content: 'For questions or issues, please contact:',
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'support@mealmatch.com',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    String? content,
    List<String>? bulletPoints,
    String? additionalContent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$number. ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (content != null) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
        if (bulletPoints != null) ...[
          const SizedBox(height: 8),
          ...bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (additionalContent != null) ...[
          const SizedBox(height: 8),
          Text(
            additionalContent,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubSection(String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
