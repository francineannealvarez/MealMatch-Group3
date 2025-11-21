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
  final String? localImagePath;
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
    required this.createdAt,
  });

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
      'createdAt': createdAt.toIso8601String(),
    };
  }

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
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class InstructionStepModel {
  final int stepNumber;
  final String text;
  final String? timer;

  InstructionStepModel({required this.stepNumber, required this.text, this.timer});

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
