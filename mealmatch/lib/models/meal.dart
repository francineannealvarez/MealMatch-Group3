class Meal {
  final String id;
  final String name;
  final String thumbnail;
  final String category;
  final String area;
  final String instructions;
  final List<String> ingredients;
  final List<String> measures;

  Meal({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
    required this.measures,
  });

  /// Returned by filter.php (no details)
  factory Meal.fromFilter(Map<String, dynamic> json) {
    return Meal(
      id: json['idMeal'],
      name: json['strMeal'],
      thumbnail: json['strMealThumb'],
      category: "",
      area: "",
      instructions: "",
      ingredients: [],
      measures: [],
    );
  }

  /// Returned by lookup.php
  factory Meal.fromJson(Map<String, dynamic> json) {
    List<String> ingredientList = [];
    List<String> measureList = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json["strIngredient$i"];
      final measure = json["strMeasure$i"];

      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty) {
        ingredientList.add(ingredient);
        measureList.add(measure ?? "");
      }
    }

    return Meal(
      id: json['idMeal'],
      name: json['strMeal'],
      thumbnail: json['strMealThumb'] ?? "",
      category: json['strCategory'] ?? "",
      area: json['strArea'] ?? "",
      instructions: json['strInstructions'] ?? "",
      ingredients: ingredientList,
      measures: measureList,
    );
  }
}
