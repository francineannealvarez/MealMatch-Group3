// lib/models/user_recipe.dart
// ✅ UPDATED: Added calories field and improved model

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
  final String? localImagePath; // ⚠️ NOTE: Local paths only work temporarily
  final int? calories; // ✅ ADDED: Calculated calories field
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

  // ✅ IMPROVED: toMap with calories calculation
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'servings': servings,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'ingredients': ingredients,
      'instructions': instructions.map((x) => x.toMap()).toList(),
      'nutrients': nutrients,
      'localImagePath': localImagePath,
      'calories': calories ?? _calculateCalories(), // ✅ ADDED: Auto-calculate if null
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ✅ ADDED: Calculate calories from nutrients
  int _calculateCalories() {
    final protein = nutrients['Protein'] ?? 0.0;
    final carbs = nutrients['Carbs'] ?? 0.0;
    final fat = nutrients['Fat'] ?? 0.0;
    return ((protein * 4) + (carbs * 4) + (fat * 9)).round();
  }

  // ✅ IMPROVED: fromMap with calories handling
  factory UserRecipe.fromMap(Map<String, dynamic> map, String id) {
    return UserRecipe(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      servings: map['servings']?.toInt() ?? 1,
      prepTime: map['prepTime'] ?? '00:00',
      cookTime: map['cookTime'] ?? '00:00',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<InstructionStepModel>.from(
        (map['instructions'] ?? []).map((x) => InstructionStepModel.fromMap(x)),
      ),
      nutrients: Map<String, double>.from(map['nutrients'] ?? {}),
      localImagePath: map['localImagePath'],
      calories: map['calories']?.toInt(), // ✅ ADDED: Load calories if exists
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

// ✅ NO CHANGES: InstructionStepModel remains the same
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