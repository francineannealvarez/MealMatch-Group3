import 'package:flutter/material.dart';
import '../services/calorielog_history_service.dart';
import '../models/meal_log.dart';

class LogHistoryPage extends StatefulWidget {
  const LogHistoryPage({super.key});

  @override
  State<LogHistoryPage> createState() => _LogHistoryPageState();
}

class _LogHistoryPageState extends State<LogHistoryPage> {
  final LogService _logService = LogService();

  String selectedFilter = 'Today';
  DateTime? customStartDate;
  DateTime? customEndDate;
  DateTime? expandedDate;
  final DateTime accountCreationDate = DateTime(2025, 8, 4);

  Map<String, Map<String, List<MealLog>>> foodLogsCache = {};
  bool isLoading = true;
  int userGoalCalories = 2000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load real data from backend
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // Load user's calorie goal from Firebase using LogService
    final goal = await _logService.getUserCalorieGoal();
    if (goal != null) {
      userGoalCalories = goal;
    }

    // Load today's data by default
    await _loadLogsForDate(DateTime.now());

    setState(() => isLoading = false);
  }

  // Load logs for specific date from backend
  Future<void> _loadLogsForDate(DateTime date) async {
    String dateKey = _getDateKey(date);

    // Check cache first to avoid unnecessary API calls
    if (foodLogsCache.containsKey(dateKey)) return;

    try {
      // Direct call to LogService
      final grouped = await _logService.getLogsGroupedByCategory(date);

      setState(() {
        foodLogsCache[dateKey] = grouped;
      });
    } catch (e) {
      print('Error loading logs for $dateKey: $e');
      // Initialize empty if error
      setState(() {
        foodLogsCache[dateKey] = {
          'Breakfast': [],
          'Lunch': [],
          'Dinner': [],
          'Snacks': [],
        };
      });
    }
  }

  Future<void> _loadLogsForDateRange(DateTime start, DateTime end) async {
    setState(() => isLoading = true);

    try {
      // Use LogService.getLogsInRange() instead of loading each date individually
      final logs = await _logService.getLogsInRange(start, end);

      // Group logs by date
      Map<String, List<MealLog>> logsByDate = {};
      for (var log in logs) {
        String dateKey = _getDateKey(log.timestamp);
        if (!logsByDate.containsKey(dateKey)) {
          logsByDate[dateKey] = [];
        }
        logsByDate[dateKey]!.add(log);
      }

      // Now group each date's logs by category
      for (var entry in logsByDate.entries) {
        String dateKey = entry.key;
        List<MealLog> dateLogs = entry.value;

        Map<String, List<MealLog>> grouped = {
          'Breakfast': [],
          'Lunch': [],
          'Dinner': [],
          'Snacks': [],
        };

        for (var log in dateLogs) {
          if (grouped.containsKey(log.category)) {
            grouped[log.category]!.add(log);
          }
        }

        setState(() {
          foodLogsCache[dateKey] = grouped;
        });
      }
    } catch (e) {
      print('Error loading date range: $e');
    }

    setState(() => isLoading = false);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _getTotalCalories(DateTime date) {
    String dateKey = _getDateKey(date);

    if (!foodLogsCache.containsKey(dateKey)) return 0;

    // Use LogService.calculateTotalCalories()
    List<MealLog> allLogs = [];
    foodLogsCache[dateKey]!.forEach((mealType, logs) {
      allLogs.addAll(logs);
    });

    return _logService.calculateTotalCalories(allLogs).toInt();
  }

  String formatDateShort(DateTime d) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String formatDateDisplay(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  List<DateTime> _getFilteredDates() {
    if (selectedFilter == 'Today') {
      return [DateTime.now()];
    } else if (selectedFilter == 'This Week') {
      List<DateTime> dates = [];
      DateTime now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        dates.add(now.subtract(Duration(days: i)));
      }
      return dates;
    } else if (selectedFilter == 'Custom Date' &&
        customStartDate != null &&
        customEndDate != null) {
      List<DateTime> dates = [];
      DateTime current = customStartDate!;
      while (current.isBefore(customEndDate!) ||
          current.isAtSameMomentAs(customEndDate!)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
      return dates;
    }
    return [DateTime.now()];
  }

  void _showCustomDateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime displayMonth = DateTime.now();
        DateTime? tempStartDate = customStartDate;
        DateTime? tempEndDate = customEndDate;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setDialogState(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month - 1,
                              );
                            });
                          },
                        ),
                        Text(
                          '${_getMonthName(displayMonth.month)} ${displayMonth.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setDialogState(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCalendar(displayMonth, tempStartDate, tempEndDate, (
                      date,
                    ) {
                      setDialogState(() {
                        if (tempStartDate == null || tempEndDate != null) {
                          tempStartDate = date;
                          tempEndDate = null;
                        } else {
                          if (date.isBefore(tempStartDate!)) {
                            tempEndDate = tempStartDate;
                            tempStartDate = date;
                          } else {
                            tempEndDate = date;
                          }
                        }
                      });
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'Account created: ${formatDateDisplay(accountCreationDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 40,
                                child: Text(
                                  'From',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tempStartDate != null
                                        ? formatDateShort(tempStartDate!)
                                        : 'MM/DD/YYYY',
                                    style: TextStyle(
                                      color: tempStartDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(
                                width: 40,
                                child: Text(
                                  'To',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tempEndDate != null
                                        ? formatDateShort(tempEndDate!)
                                        : 'MM/DD/YYYY',
                                    style: TextStyle(
                                      color: tempEndDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: tempStartDate != null && tempEndDate != null
                            ? () {
                                setState(() {
                                  customStartDate = tempStartDate;
                                  customEndDate = tempEndDate;
                                  selectedFilter = 'Custom Date';
                                  expandedDate = null;
                                });
                                Navigator.pop(context);
                                _loadLogsForDateRange(
                                  customStartDate!,
                                  customEndDate!,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildCalendar(
    DateTime month,
    DateTime? startDate,
    DateTime? endDate,
    Function(DateTime) onDateSelected,
  ) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(6, (weekIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 40, height: 40);
              }

              final date = DateTime(month.year, month.month, dayNumber);
              final isBeforeCreation = date.isBefore(accountCreationDate);
              final isSelected =
                  (startDate != null &&
                      date.year == startDate.year &&
                      date.month == startDate.month &&
                      date.day == startDate.day) ||
                  (endDate != null &&
                      date.year == endDate.year &&
                      date.month == endDate.month &&
                      date.day == endDate.day);

              final isInRange =
                  startDate != null &&
                  endDate != null &&
                  date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  date.isBefore(endDate.add(const Duration(days: 1)));

              return GestureDetector(
                onTap: isBeforeCreation ? null : () => onDateSelected(date),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBeforeCreation
                        ? Colors.grey.shade200
                        : isSelected
                        ? const Color(0xFF4CAF50)
                        : isInRange
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: isBeforeCreation
                          ? Colors.grey.shade400
                          : isSelected
                          ? Colors.white
                          : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  // Helper to check if two dates are same
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // uses LogService.deleteMealLog()
  Future<void> _removeFoodItem(MealLog log) async {
    try {
      // Use LogService method
      await _logService.deleteMealLog(log.id);

      // Remove from cache
      String dateKey = _getDateKey(log.timestamp);
      if (foodLogsCache.containsKey(dateKey)) {
        foodLogsCache[dateKey]![log.category]!.remove(log);
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food item deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDateSummaryCard(DateTime date) {
    bool isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    int consumed = _getTotalCalories(date);
    int goal = userGoalCalories;
    int remaining = goal - consumed;
    bool isExpanded =
        expandedDate != null &&
        expandedDate!.year == date.year &&
        expandedDate!.month == date.month &&
        expandedDate!.day == date.day;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              if (!isExpanded) {
                await _loadLogsForDate(date);
              }
              setState(() {
                if (isExpanded) {
                  expandedDate = null;
                } else {
                  expandedDate = date;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Today' : formatDateDisplay(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$goal cal - $consumed cal = $remaining cal',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedMealsList(date, isToday),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedMealsList(DateTime date, bool isToday) {
    String dateKey = _getDateKey(date);
    Map<String, List<MealLog>> meals =
        foodLogsCache[dateKey] ??
        {'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': []};

    return Column(
      children: [
        _buildMealCard(
          'Breakfast',
          '🍞',
          const Color(0xFFFFA726),
          meals['Breakfast']!,
          date,
          isToday,
        ),
        _buildMealCard(
          'Lunch',
          '☀️',
          const Color(0xFFFFB74D),
          meals['Lunch']!,
          date,
          isToday,
        ),
        _buildMealCard(
          'Dinner',
          '🍽️',
          const Color(0xFF8D6E63),
          meals['Dinner']!,
          date,
          isToday,
        ),
        _buildMealCard(
          'Snacks',
          '🍎',
          const Color(0xFFE57373),
          meals['Snacks']!,
          date,
          isToday,
        ),
      ],
    );
  }

  Widget _buildMealCard(
    String title,
    String emoji,
    Color color,
    List<MealLog> logs,
    DateTime date,
    bool isToday,
  ) {
    int totalCals = _logService.calculateTotalCalories(logs).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCals',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${logs.length} Items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No food logged yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ...logs.map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  log.foodName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Show verified badge if food is verified
                              if (log.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 10,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        log.source == 'USDA' ? 'USDA' : 'OFF',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                log.serving,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (log.brand.isNotEmpty)
                                Text(
                                  ', ${log.brand}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              Text(
                                ' • ${log.calories.toInt()} cal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      GestureDetector(
                        onTap: () => _removeFoodItem(log),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D9),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'x',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 12),
          if (isToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/logfood').then((_) {
                    _loadLogsForDate(date);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5D08C),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'ADD FOOD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> displayDates = _getFilteredDates();
    bool showSummaryList = selectedFilter != 'Today';
    DateTime currentDate = expandedDate ?? DateTime.now();

    String dateKey = _getDateKey(currentDate);
    Map<String, List<MealLog>> meals =
        foodLogsCache[dateKey] ??
        {'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': []};

    bool isToday = _isSameDate(currentDate, DateTime.now());

    // Show loading indicator while fetching data
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFE9B1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFA726),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Daily Calorie',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFE9B1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA726),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Daily Calorie',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: Column(
        children: [
          if (!showSummaryList || expandedDate != null) ...[
            Container(
              color: const Color(0xFFFFA726),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCalorieBox('Goal', '$userGoalCalories', false),
                      const Text(
                        '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      _buildCalorieBox(
                        'Consumed',
                        '${_getTotalCalories(currentDate)}',
                        false,
                      ),
                      const Text(
                        '=',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      _buildCalorieBox(
                        'Remaining',
                        '${userGoalCalories - _getTotalCalories(currentDate)}',
                        userGoalCalories - _getTotalCalories(currentDate) < 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isToday ? 'Today' : formatDateDisplay(currentDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E42),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateDisplay(
                            isToday ? DateTime.now() : currentDate,
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                  onSelected: (String value) {
                    if (value == 'Custom Date') {
                      _showCustomDateDialog();
                    } else {
                      setState(() {
                        selectedFilter = value;
                        expandedDate = null;
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Today',
                          child: Text('Today'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'This Week',
                          child: Text('This Week'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Custom Date',
                          child: Text('Custom Date'),
                        ),
                      ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: showSummaryList
                ? ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: displayDates.length,
                    itemBuilder: (context, index) {
                      return _buildDateSummaryCard(displayDates[index]);
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _buildMealCard(
                        'Breakfast',
                        '🍞',
                        const Color(0xFFFFA726),
                        meals['Breakfast']!,
                        currentDate,
                        isToday,
                      ),
                      _buildMealCard(
                        'Lunch',
                        '☀️',
                        const Color(0xFFFFB74D),
                        meals['Lunch']!,
                        currentDate,
                        isToday,
                      ),
                      _buildMealCard(
                        'Dinner',
                        '🍽️',
                        const Color(0xFF8D6E63),
                        meals['Dinner']!,
                        currentDate,
                        isToday,
                      ),
                      _buildMealCard(
                        'Snacks',
                        '🍎',
                        const Color(0xFFE57373),
                        meals['Snacks']!,
                        currentDate,
                        isToday,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBox(String label, String value, bool isNegative) {
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isNegative ? Colors.red : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    int selectedIndex = 3;
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
}
