import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Recipe Activity',
      'description': 'Someone liked your recipe!',
      'details':
          'Sarah Johnson liked your "Creamy Garlic Pasta" recipe! Your recipe now has 127 likes total. Keep sharing delicious recipes with the community!',
      'timestamp': '2 hours ago',
      'icon': Icons.emoji_events_outlined,
      'iconColor': const Color(0xFFFFC107),
      'isUnread': true,
    },
    {
      'id': 2,
      'title': 'Recipe Activity',
      'description': 'Your recipe just got a new rating!',
      'details':
          'Michael Chen rated your "Spicy Thai Curry" recipe 5 stars! ⭐⭐⭐⭐⭐\n\nYour recipe now has an average rating of 4.8 stars from 43 reviews. Great job!',
      'timestamp': '3 hours ago',
      'icon': Icons.emoji_events_outlined,
      'iconColor': const Color(0xFFFFC107),
      'isUnread': true,
    },
    {
      'id': 3,
      'title': 'Recipe Activity',
      'description': 'Your recipe was added to someone\'s favorites.',
      'details':
          'Emma Wilson added your "Healthy Quinoa Bowl" to her favorites collection! Your recipe has been favorited 89 times. It\'s clearly a community favorite!',
      'timestamp': '5 hours ago',
      'icon': Icons.favorite_border,
      'iconColor': const Color(0xFFFF8A65),
      'isUnread': true,
    },
    {
      'id': 4,
      'title': 'Recipe Activity',
      'description': 'A user commented on your recipe.',
      'details':
          'Alex Martinez commented on your "Mediterranean Salmon":\n\n"This recipe is absolutely amazing! Made it for dinner last night and my family loved it. The lemon herb seasoning was perfect. Thanks for sharing!"',
      'timestamp': '7 hours ago',
      'icon': Icons.chat_bubble_outline,
      'iconColor': const Color(0xFF4DD0E1),
      'isUnread': true,
    },
    {
      'id': 5,
      'title': 'Calorie Tracker Update',
      'description': 'You\'ve hit your daily calorie goal.',
      'details':
          'Congratulations! You\'ve successfully reached your daily calorie goal of 2,000 calories.\n\nToday\'s breakdown:\n• Breakfast: 450 cal\n• Lunch: 650 cal\n• Dinner: 700 cal\n• Snacks: 200 cal\n\nKeep up the great work maintaining your healthy eating habits!',
      'timestamp': '1 day ago',
      'icon': Icons.bolt_outlined,
      'iconColor': const Color(0xFF4DD0E1),
      'isUnread': true,
    },
    {
      'id': 6,
      'title': 'Calorie Tracker Update',
      'description': 'You\'re close to reaching your calorie target today.',
      'details':
          'You\'re doing great! You\'ve consumed 1,750 calories so far.\n\nYou have 250 calories remaining to reach your daily goal of 2,000 calories. Consider a light snack or small meal to meet your target.',
      'timestamp': '1 day ago',
      'icon': Icons.bolt_outlined,
      'iconColor': const Color(0xFF4DD0E1),
      'isUnread': true,
    },
    {
      'id': 7,
      'title': 'Calorie Tracker Update',
      'description':
          'Your daily calorie goal is not yet met—check out recipes to fill the gap.',
      'details':
          'You still have 400 calories left to reach your daily goal of 2,000 calories.\n\nWhy not try one of these healthy recipes:\n• Grilled Chicken Salad (350 cal)\n• Veggie Stir Fry (280 cal)\n• Greek Yogurt Parfait (220 cal)',
      'timestamp': '2 days ago',
      'icon': Icons.bolt_outlined,
      'iconColor': const Color(0xFF4DD0E1),
      'isUnread': false,
    },
    {
      'id': 8,
      'title': 'Calorie Tracker Update',
      'description': 'Still room in your calories—why not try a new recipe?',
      'details':
          'You have 300 calories remaining for today. Perfect opportunity to try something new!\n\nRecommended recipes:\n• Protein Smoothie Bowl (290 cal)\n• Turkey Lettuce Wraps (180 cal)\n• Fruit & Nut Mix (150 cal)',
      'timestamp': '2 days ago',
      'icon': Icons.restaurant_outlined,
      'iconColor': const Color(0xFFFFB74D),
      'isUnread': false,
    },
    {
      'id': 9,
      'title': 'Reminders',
      'description': 'Don\'t forget to log your meals today.',
      'details':
          'Friendly reminder to log all your meals today!\n\nTracking your meals helps you:\n• Stay aware of your calorie intake\n• Maintain your healthy eating streak\n• Reach your nutrition goals faster\n• Build consistent healthy habits',
      'timestamp': '8 hours ago',
      'icon': Icons.lightbulb_outline,
      'iconColor': const Color(0xFFFFE082),
      'isUnread': false,
    },
    {
      'id': 10,
      'title': 'Reminders',
      'description': 'You haven\'t logged any meals yet.',
      'details':
          'It\'s already 2:00 PM and you haven\'t logged any meals today.\n\nRemember, consistent tracking is key to reaching your health goals. Take a moment to log what you\'ve eaten so far.',
      'timestamp': '10 hours ago',
      'icon': Icons.lightbulb_outline,
      'iconColor': const Color(0xFFFFE082),
      'isUnread': false,
    },
    {
      'id': 11,
      'title': 'Reminders',
      'description': 'Haven\'t cooked anything today? Try a new recipe!',
      'details':
          'Looking for cooking inspiration?\n\nWe have some amazing new recipes that match your preferences:\n• 20-Minute Teriyaki Chicken Bowl\n• One-Pot Vegetarian Chili\n• Mediterranean Stuffed Peppers',
      'timestamp': '12 hours ago',
      'icon': Icons.restaurant_menu,
      'iconColor': const Color(0xFFFFB74D),
      'isUnread': false,
    },
    {
      'id': 12,
      'title': 'Reminders',
      'description': 'Keep your streak! Log a meal to continue your progress.',
      'details':
          'You\'re on a 14-day meal logging streak! 🔥\n\nDon\'t break your amazing streak now. Log at least one meal today to keep your streak alive.',
      'timestamp': '18 hours ago',
      'icon': Icons.access_alarm,
      'iconColor': const Color(0xFF4DB6AC),
      'isUnread': false,
    },
    {
      'id': 13,
      'title': 'Weekly Summary',
      'description': 'Your weekly meal summary is ready.',
      'details':
          'Week of Nov 11-17, 2025\n\n📊 Meals Logged: 19 out of 21\n🔥 Calories Avg: 1,950 per day\n✅ Days on Target: 5 out of 7\n⭐ Favorite Meal: Grilled Chicken Salad',
      'timestamp': '3 days ago',
      'icon': Icons.calendar_today_outlined,
      'iconColor': const Color(0xFF7E57C2),
      'isUnread': false,
    },
    {
      'id': 14,
      'title': 'Weekly Summary',
      'description':
          'Your healthy meal streak this week is impressive—view summary.',
      'details':
          'Outstanding Week! 🌟\n\nYou logged healthy meals every single day this week.\n\n✓ 7-day meal logging streak\n✓ Average 1,920 calories/day\n✓ Met your protein goals 6 out of 7 days',
      'timestamp': '3 days ago',
      'icon': Icons.insights_outlined,
      'iconColor': const Color(0xFF26A69A),
      'isUnread': false,
    },
    {
      'id': 15,
      'title': 'Streak Update',
      'description':
          'You kept your streak going! Great job logging meals today.',
      'details':
          'Streak Status: 15 Days! 🔥🔥🔥\n\nYou\'ve successfully logged your meals for 15 consecutive days. Your consistency is paying off!',
      'timestamp': '1 day ago',
      'icon': Icons.local_fire_department_outlined,
      'iconColor': const Color(0xFFFF7043),
      'isUnread': false,
    },
    {
      'id': 16,
      'title': 'Streak Update',
      'description': 'New streak milestone unlocked — keep it up!',
      'details':
          '🎉 MILESTONE ACHIEVED! 🎉\n\nYou\'ve unlocked the "Consistency Champion" badge for maintaining a 2-week meal logging streak!',
      'timestamp': '2 days ago',
      'icon': Icons.emoji_events_outlined,
      'iconColor': const Color(0xFFFFC107),
      'isUnread': false,
    },
    {
      'id': 17,
      'title': 'Streak Update',
      'description': 'Almost lost your streak! Log a meal to keep it alive.',
      'details':
          '⚠️ Streak Alert! ⚠️\n\nYour 12-day streak is at risk! You have until 11:59 PM tonight to log at least one meal.',
      'timestamp': '4 days ago',
      'icon': Icons.error_outline,
      'iconColor': const Color(0xFFFFA726),
      'isUnread': false,
    },
  ];

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isUnread'] = false;
      }
    });
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isUnread'] = false;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  void _showDetailsDialog(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                  color: (notification['iconColor'] as Color).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'] as IconData,
                  color: notification['iconColor'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['details'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  notification['timestamp'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => n['isUnread'] == true)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, unreadCount),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'re all caught up!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _notifications.isEmpty ? null : _markAllAsRead,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Mark All as Read',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _notifications.isEmpty ? null : _clearAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFFFF9800),
                ),
              ),
              const Center(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                    fontFamily: 'MuseoModerno',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$unreadCount unread',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = notification['isUnread'] as bool;
    final id = notification['id'] as int;

    return InkWell(
      onTap: () => _showDetailsDialog(notification),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isUnread
              ? Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (notification['iconColor'] as Color).withOpacity(
                      0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'] as IconData,
                    color: notification['iconColor'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['timestamp'] as String,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUnread)
                  TextButton(
                    onPressed: () => _markAsRead(id),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: const Text(
                      'Mark as Read',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => _deleteNotification(id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
