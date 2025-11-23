// lib/models/user_recipe.dart

class UserRecipe {
  final String? id;
  final String userId;
  final String name;
  final int servings;
  final String prepTime;
  final String cookTime;
  final List<String> ingredients;
  final List<InstructionStepModel> instructions;
  final Map<String, double> nutrients;
  final String? localImagePath; // Local paths only work temporarily
  final int? calories; // Calculated calories field
  final DateTime createdAt;

  UserRecipe({
    this.id,
    required this.userId,
    required this.name,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.instructions,
    required this.nutrients,
    this.localImagePath,
    this.calories, // ✅ ADDED
    required this.createdAt,
  });

  // toMap with calories calculation
  Map<String, dynamic> toMap() {
    final totalMinutes = _parseTimeToMinutes(prepTime) + _parseTimeToMinutes(cookTime);

    return {
      'userId': userId,
      'name': name,
      'servings': servings,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'readyInMinutes': totalMinutes,
      'ingredients': ingredients,
      'instructions': instructions.map((x) => x.toMap()).toList(),
      'nutrients': nutrients,
      'nutrition': nutrients,
      'localImagePath': localImagePath,
      'image': localImagePath ?? '',
      'calories': calories ?? _calculateCalories(), 
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int _parseTimeToMinutes(String time) {
    try {
      if (time.contains(':')) {
        final parts = time.split(':');
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        return (hours * 60) + minutes;
      } else {
        return int.tryParse(time) ?? 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Calculate calories from nutrients
  int _calculateCalories() {
    final protein = nutrients['Protein'] ?? 0.0;
    final carbs = nutrients['Carbs'] ?? 0.0;
    final fat = nutrients['Fat'] ?? 0.0;
    return ((protein * 4) + (carbs * 4) + (fat * 9)).round();
  }

  // fromMap with calories handling
  factory UserRecipe.fromMap(Map<String, dynamic> map, String id) {
    return UserRecipe(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? map['title'] ?? '',
      servings: map['servings']?.toInt() ?? 1,
      prepTime: map['prepTime'] ?? '00:00',
      cookTime: map['cookTime'] ?? '00:00',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<InstructionStepModel>.from(
        (map['instructions'] ?? []).map((x) => InstructionStepModel.fromMap(x)),
      ),
      nutrients: Map<String, double>.from(map['nutrients'] ?? {}),
      localImagePath: map['localImagePath'],
      calories: map['calories']?.toInt(), 
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class InstructionStepModel {
  final int stepNumber;
  final String text;
  final String? timer;

  InstructionStepModel({
    required this.stepNumber,
    required this.text,
    this.timer,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'text': text,
      'timer': timer,
    };
  }

  factory InstructionStepModel.fromMap(Map<String, dynamic> map) {
    return InstructionStepModel(
      stepNumber: map['stepNumber'] ?? 0,
      text: map['text'] ?? '',
      timer: map['timer'],
    );
  }
}