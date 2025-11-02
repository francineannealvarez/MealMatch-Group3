class Recipe {
  final int id;
  final String title;
  final String image;
  final double calories;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.calories,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'] ?? 'Unknown',
      image: json['image'] ?? '',
      calories: (json['nutrition']?['nutrients']?[0]?['amount'] ?? 0).toDouble(),
    );
  }
}
