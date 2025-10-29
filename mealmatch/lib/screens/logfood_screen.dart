// 📁 lib/screens/food_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fooditem.dart';

class ModifyFoodScreen extends StatefulWidget {
  final FoodItem food;
  final String? preselectedMeal;

  const ModifyFoodScreen({super.key, required this.food, this.preselectedMeal});

  @override
  State<ModifyFoodScreen> createState() => _ModifyFoodScreenState();
}

class _ModifyFoodScreenState extends State<ModifyFoodScreen> {
  late String _selectedMeal;
  late double _numberOfServings;
  late String _selectedServingSize;

  // Common serving size options
  final List<String> _servingSizeOptions = [
    '100 g',
    '1 cup',
    '1 piece',
    '1 serving',
    '1 bowl',
    '1 plate',
    '50 g',
    '150 g',
    '200 g',
  ];

  final List<String> _mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.preselectedMeal ?? 'Breakfast';
    _numberOfServings = 1.0;
    _selectedServingSize = widget.food.servingsize;
  }

  // Calculate nutrition based on servings
  double get _calculatedCalories => widget.food.calories * _numberOfServings;
  double get _calculatedCarbs => widget.food.carbs * _numberOfServings;
  double get _calculatedProtein => widget.food.protein * _numberOfServings;
  double get _calculatedFat => widget.food.fat * _numberOfServings;

  Future<void> _addFoodToMeal() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore.collection('meal_logs').add({
        'category': _selectedMeal,
        'foodName': widget.food.name,
        'calories': _calculatedCalories,
        'carbs': _calculatedCarbs,
        'fats': _calculatedFat,
        'proteins': _calculatedProtein,
        'servingsize': '$_numberOfServings x $_selectedServingSize',
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateStr,
        'brand': widget.food.brand,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.food.name} added to $_selectedMeal!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding food: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Food', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name and Calories Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.food.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_calculatedCalories.toStringAsFixed(0)} cal',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Meal Selection
            _buildSelectionRow(
              'Meal',
              _selectedMeal,
              Colors.orange,
              () => _showMealPicker(),
            ),

            const Divider(height: 1),

            // Number of Servings
            _buildServingRow('Number of Servings', _numberOfServings, (value) {
              setState(() {
                _numberOfServings = value;
              });
            }),

            const Divider(height: 1),

            // Serving Size Dropdown
            _buildServingSizePicker(),

            const Divider(height: 1),

            const SizedBox(height: 20),

            // Nutrition Info Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition info',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Pie Chart
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: [
                          PieChartSectionData(
                            value: _calculatedCarbs,
                            color: Colors.green,
                            title: '',
                            radius: 100,
                          ),
                          PieChartSectionData(
                            value: _calculatedProtein,
                            color: Colors.yellow.shade700,
                            title: '',
                            radius: 100,
                          ),
                          PieChartSectionData(
                            value: _calculatedFat,
                            color: Colors.orange,
                            title: '',
                            radius: 100,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Macros Legend
                  _buildMacroRow(
                    Colors.green,
                    'Carbohydrates',
                    '${_calculatedCarbs.toStringAsFixed(1)} g',
                  ),
                  const SizedBox(height: 12),
                  _buildMacroRow(
                    Colors.yellow.shade700,
                    'Protein',
                    '${_calculatedProtein.toStringAsFixed(1)} g',
                  ),
                  const SizedBox(height: 12),
                  _buildMacroRow(
                    Colors.orange,
                    'Fat',
                    '${_calculatedFat.toStringAsFixed(1)} g',
                  ),
                ],
              ),
            ),

            // Add Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addFoodToMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add this food',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20), // ← Add extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow(
    String label,
    String value,
    Color valueColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServingRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (value > 0.5) onChanged(value - 0.5);
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.orange,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 0.5),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServingSizePicker() {
    return InkWell(
      onTap: _showServingSizePicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Serving size', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  _selectedServingSize,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServingSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    const Text(
                      'Select Serving Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable list
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _servingSizeOptions.map((size) {
                    final isSelected = size == _selectedServingSize;

                    return ListTile(
                      title: Text(
                        size,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.orange)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedServingSize = size;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showMealPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
        );
      },
    );
  }

  Widget _buildMacroRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
