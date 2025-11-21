import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'dart:math' as math;
import '../models/user_recipe.dart';
import '../services/recipe_service.dart';

class UploadRecipeScreen extends StatefulWidget {
  const UploadRecipeScreen({super.key});

  @override
  State<UploadRecipeScreen> createState() => _UploadRecipeScreenState();
}

class _UploadRecipeScreenState extends State<UploadRecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController(text: '4');

  String prepTime = '00:00';
  String cookTime = '00:00';

  List<String> ingredients = [];
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

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _recipeNameController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showIngredientsDialog() {
    final TextEditingController ingredientController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Add Ingredient'),
          content: TextField(
            controller: ingredientController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., 2 cups flour',
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
                backgroundColor: const Color(0xFF8BC34A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (ingredientController.text.trim().isNotEmpty) {
                  setState(() {
                    ingredients.add(ingredientController.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

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
                        // MINUTES
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() => minutes = (minutes + 1) % 60);
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
                        // SECONDS
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() => seconds = (seconds + 1) % 60);
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
    final TextEditingController controller = TextEditingController(
      text: nutrients[nutrient]!.toStringAsFixed(1),
    );

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
              hintText: 'Enter grams',
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

  int get totalCalories {
    return ((nutrients['Protein']! * 4) +
            (nutrients['Carbs']! * 4) +
            (nutrients['Fat']! * 9))
        .round();
  }

  // --- SAVE TO FIREBASE LOGIC ---
  // ✅ IMPROVED: Upload recipe with better validation and error handling
  Future<void> _uploadRecipe() async {
    // ✅ IMPROVED: Enhanced validation
    if (_recipeNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter recipe name');
      return;
    }

    if (ingredients.isEmpty) {
      _showErrorSnackBar('Please add at least one ingredient');
      return;
    }

    // ✅ ADDED: Check if any instruction is empty
    if (instructions.any((step) => step.text.trim().isEmpty)) {
      _showErrorSnackBar('Please fill in all instruction steps');
      return;
    }

    // ✅ ADDED: Validate servings
    final servings = int.tryParse(_servingsController.text);
    if (servings == null || servings < 1) {
      _showErrorSnackBar('Please enter a valid number of servings');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // ✅ IMPROVED: Create UserRecipe model
      final newRecipe = UserRecipe(
        userId: user.uid,
        name: _recipeNameController.text.trim(),
        servings: servings,
        prepTime: prepTime,
        cookTime: cookTime,
        ingredients: ingredients,
        instructions: instructions
            .map((step) => InstructionStepModel(
                  stepNumber: step.stepNumber,
                  text: step.text,
                  timer: step.timer,
                ))
            .toList(),
        nutrients: nutrients,
        localImagePath: _selectedImage?.path, // ⚠️ NOTE: This is temporary storage
        createdAt: DateTime.now(),
      );

      // ✅ CHANGED: Call RecipeService instead of FirebaseService
      final result = await _recipeService.saveUserRecipe(newRecipe);

      if (mounted) {
        if (result['success'] == true) {
          // ✅ IMPROVED: Show success message
          _showSuccessSnackBar(result['message'] ?? 'Recipe uploaded successfully!');
          
          // ✅ IMPROVED: Reset form
          _resetForm();
          
          // ✅ IMPROVED: Navigate back with success indicator
          Navigator.pop(context, true); // Pass true to indicate success
        } else {
          // ✅ IMPROVED: Show error from service
          _showErrorSnackBar(result['message'] ?? 'Failed to upload recipe');
        }
      }
    } catch (e) {
      print('❌ Upload error: $e'); // ✅ ADDED: Better error logging
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ✅ ADDED: Helper method to reset form
  void _resetForm() {
    _recipeNameController.clear();
    _servingsController.text = '4';
    setState(() {
      prepTime = '00:00';
      cookTime = '00:00';
      ingredients = [];
      instructions = [InstructionStep(stepNumber: 1, text: '', timer: null)];
      nutrients.updateAll((key, value) => 0);
      _selectedImage = null;
    });
  }

  // ✅ ADDED: Helper method for error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ ADDED: Helper method for success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Upload Recipe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE UPLOAD
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Tap to Upload Image',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 14)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Recipe Name',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5F3B))),
              const SizedBox(height: 8),
              TextField(
                controller: _recipeNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Number of Servings',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5F3B))),
              const SizedBox(height: 8),
              TextField(
                controller: _servingsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 20),

              // INGREDIENTS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ingredients',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B5F3B))),
                  Text('${ingredients.length} added',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),

              // ADD BUTTON
              GestureDetector(
                onTap: _showIngredientsDialog,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFF8BC34A), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Add Ingredient',
                        style: TextStyle(
                            color: Color(0xFF6B5F3B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              
              // INGREDIENT LIST
              if (ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...ingredients.asMap().entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() {
                            ingredients.removeAt(entry.key);
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _timeCard('Prep Time', prepTime,
                        () => _showTimePicker(context, 'prep')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeCard('Cook Time', cookTime,
                        () => _showTimePicker(context, 'cook')),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Instructions',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B5F3B))),
              const SizedBox(height: 8),

              ...instructions.asMap().entries.map((entry) {
                int index = entry.key;
                InstructionStep step = entry.value;
                return Container(
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
                                color: Color(0xFF6B5F3B)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showTimePicker(context, 'step',
                                stepIndex: index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: step.timer != null
                                    ? const Color(0xFFF59E42)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 16,
                                      color: step.timer != null
                                          ? Colors.white
                                          : Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    step.timer ?? '00:00',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: step.timer != null
                                            ? Colors.white
                                            : Colors.grey.shade600),
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
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        controller: TextEditingController(text: step.text)
                          ..selection = TextSelection.fromPosition(
                              TextPosition(offset: step.text.length)),
                        onChanged: (value) => step.text = value,
                        decoration: InputDecoration(
                          hintText: 'Enter instruction for this step...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              GestureDetector(
                onTap: _addInstructionStep,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFF8BC34A), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Add Instruction',
                        style: TextStyle(
                            color: Color(0xFF6B5F3B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition chart
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
                    const Text('Nutrition Info',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B5F3B))),
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
                              return _nutrientRow(key, nutrients[key]!,
                                  nutrientColors[key]!);
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
                ),
                child: Text('Calories: $totalCalories',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B5F3B))),
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
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _isUploading ? null : _uploadRecipe,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Upload Recipe',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B5F3B),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(time,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B5F3B))),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B5F3B)))),
          Text('${value.toStringAsFixed(1)}g',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B5F3B))),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showNutrientDialog(name),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Color(0xFFEF5350), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Classes ---
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

  NutritionChartPainter(
      {required this.protein, required this.carbs, required this.fat});

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

    void drawSection(double value, Color color) {
      if (value > 0) {
        final sweepAngle = (value / total) * 2 * math.pi;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10),
            startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
      }
    }

    drawSection(protein, const Color(0xFFFDD835));
    drawSection(carbs, const Color(0xFFFF9800));
    drawSection(fat, const Color(0xFFEF5350));
  }

  @override
  bool shouldRepaint(NutritionChartPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat;
  }
}
