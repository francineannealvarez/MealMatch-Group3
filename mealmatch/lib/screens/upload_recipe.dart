// lib/screens/upload_recipes_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class UploadRecipesScreen extends StatefulWidget {
  const UploadRecipesScreen({super.key});

  @override
  State<UploadRecipesScreen> createState() => _UploadRecipesScreenState();
}

class _UploadRecipesScreenState extends State<UploadRecipesScreen> {
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  String prepTime = '00:00';
  String cookTime = '00:00';

  List<InstructionStep> instructions = [
    InstructionStep(stepNumber: 1, text: '', timer: null),
  ];

  final Map<String, double> nutrients = {
    'Protein': 0,
    'Carbs': 0,
    'Fat': 0,
    'Fiber': 0,
    'Sugar': 0,
    'Sodium': 0,
  };

  final Map<String, Color> nutrientColors = {
    'Protein': const Color(0xFFFDD835),
    'Carbs': const Color(0xFFFF9800),
    'Fat': const Color(0xFFEF5350),
    'Fiber': const Color(0xFF8BC34A),
    'Sugar': const Color(0xFF42A5F5),
    'Sodium': const Color(0xFF9C27B0),
  };

  void _addInstructionStep() {
    setState(() {
      instructions.add(
        InstructionStep(
          stepNumber: instructions.length + 1,
          text: '',
          timer: null,
        ),
      );
    });
  }

  void _deleteInstructionStep(int index) {
    setState(() {
      instructions.removeAt(index);
      for (int i = 0; i < instructions.length; i++) {
        instructions[i].stepNumber = i + 1;
      }
    });
  }

  void _showIngredientsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Add Ingredients'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: const Center(
              child: Text(
                'Ingredients list will be added here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTimePicker(BuildContext context, String type, {int? stepIndex}) {
    int minutes = 0;
    int seconds = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Text(
                          stepIndex != null
                              ? 'Set Step Timer'
                              : 'Set ${type == 'prep' ? 'Prep' : 'Cook'} Timer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B5F3B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          color: const Color(0xFF6B5F3B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  minutes = (minutes + 1) % 60;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_up, size: 32),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                minutes.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  minutes = (minutes - 1) % 60;
                                  if (minutes < 0) minutes = 59;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, size: 32),
                            ),
                            const Text('MM'),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  seconds = (seconds + 1) % 60;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_up, size: 32),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                seconds.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  seconds = (seconds - 1) % 60;
                                  if (seconds < 0) seconds = 59;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down, size: 32),
                            ),
                            const Text('SS'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E42),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          final timeString =
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                          if (stepIndex != null) {
                            instructions[stepIndex].timer = timeString;
                          } else if (type == 'prep') {
                            prepTime = timeString;
                          } else {
                            cookTime = timeString;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Add Timer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (stepIndex != null) {
                            instructions[stepIndex].timer = null;
                          } else if (type == 'prep') {
                            prepTime = '00:00';
                          } else {
                            cookTime = '00:00';
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Remove Timer',
                        style: TextStyle(color: Colors.grey),
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

  void _showNutrientDialog(String nutrient) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Add $nutrient'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: 'g',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E42),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  nutrients[nutrient] = double.tryParse(controller.text) ?? 0;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Calculate total calories based on macronutrients
  // Formula:
  // - Protein: 4 calories per gram
  // - Carbohydrates: 4 calories per gram
  // - Fat: 9 calories per gram
  // - Fiber, Sugar, Sodium: These are already counted in Carbs/other macros,
  //   so they don't add additional calories to avoid double counting
  int get totalCalories {
    return ((nutrients['Protein']! * 4) + // Protein contribution
            (nutrients['Carbs']! * 4) + // Carbohydrate contribution
            (nutrients['Fat']! * 9)) // Fat contribution
        .round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC34A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UPLOAD IMAGE LOGIC HERE
              Center(
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Recipe Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5F3B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipeNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Number of Servings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5F3B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _servingsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5F3B),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _showIngredientsDialog,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BC34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Ingredients',
                      style: TextStyle(
                        color: Color(0xFF6B5F3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _timeCard('Prep Time', prepTime, () {
                      _showTimePicker(context, 'prep');
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeCard('Cook Time', cookTime, () {
                      _showTimePicker(context, 'cook');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5F3B),
                ),
              ),
              const SizedBox(height: 8),

              ...instructions.asMap().entries.map((entry) {
                int index = entry.key;
                InstructionStep step = entry.value;

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Step ${step.stepNumber}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B5F3B),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _showTimePicker(
                                    context,
                                    'step',
                                    stepIndex: index,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: step.timer != null
                                        ? const Color(0xFFF59E42)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: step.timer != null
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        step.timer ?? '00:00',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: step.timer != null
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (instructions.length > 1) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _deleteInstructionStep(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            maxLines: 3,
                            onChanged: (value) {
                              step.text = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter instruction for this step...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),

              GestureDetector(
                onTap: _addInstructionStep,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BC34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Instructions',
                      style: TextStyle(
                        color: Color(0xFF6B5F3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nutrition Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B5F3B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: NutritionChartPainter(
                              protein: nutrients['Protein']!,
                              carbs: nutrients['Carbs']!,
                              fat: nutrients['Fat']!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: nutrients.keys.map((key) {
                              return _nutrientRow(
                                key,
                                nutrients[key]!,
                                nutrientColors[key]!,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Calories: $totalCalories',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B5F3B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No implementation yet'),
                        backgroundColor: Color(0xFFF59E42),
                      ),
                    );
                  },
                  child: const Text(
                    'Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeCard(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B5F3B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B5F3B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientRow(String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B5F3B)),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B5F3B),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showNutrientDialog(name),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFEF5350),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class InstructionStep {
  int stepNumber;
  String text;
  String? timer;

  InstructionStep({required this.stepNumber, required this.text, this.timer});
}

class NutritionChartPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  NutritionChartPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final total = protein + carbs + fat;
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(center, radius - 10, paint);
      return;
    }

    double startAngle = -math.pi / 2;

    // Protein (Yellow)
    if (protein > 0) {
      final proteinAngle = (protein / total) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFFFDD835)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        proteinAngle,
        false,
        paint,
      );
      startAngle += proteinAngle;
    }

    // Carbs (Orange)
    if (carbs > 0) {
      final carbsAngle = (carbs / total) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        carbsAngle,
        false,
        paint,
      );
      startAngle += carbsAngle;
    }

    // Fat (Red)
    if (fat > 0) {
      final fatAngle = (fat / total) * 2 * math.pi;
      final paint = Paint()
        ..color = const Color(0xFFEF5350)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        fatAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(NutritionChartPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat;
  }
}
