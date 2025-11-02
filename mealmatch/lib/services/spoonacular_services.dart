// lib/services/spoonacular_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularService {
  static const String apiKey = "a1aa205f625c4824b06636c8125379b5";
  static const String base = "https://api.spoonacular.com/recipes";

  /// ✅ Backwards compatibility alias
  static Future<List<Map<String, dynamic>>> searchRecipesByIngredients(
      List<String> ingredients,
      {int number = 10}) async {
    return findByIngredients(ingredients, number: number);
  }

  /// ✅ Main method for searching recipes
  static Future<List<Map<String, dynamic>>> findByIngredients(
      List<String> ingredients,
      {int number = 10}) async {
    if (ingredients.isEmpty) return [];

    final query = ingredients
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(',');

    final uri = Uri.parse(
        "$base/findByIngredients?apiKey=$apiKey&ingredients=$query&number=$number&ranking=1");

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception("Spoonacular error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> decoded = jsonDecode(res.body);

    return decoded.map((item) {
      final missed = (item['missedIngredients'] as List<dynamic>? ?? [])
          .map((m) => (m['name'] ?? "").toString())
          .toList();
      final used = (item['usedIngredients'] as List<dynamic>? ?? [])
          .map((u) => (u['name'] ?? "").toString())
          .toList();

      return {
        'id': item['id'],
        'title': item['title'],
        'image': item['image'],
        'usedIngredientCount': used.length,
        'missedIngredientCount': missed.length,
        'missedIngredients': missed,
        'usedIngredients': used,
      };
    }).toList();
  }

  /// ✅ Fetch full recipe info
  static Future<Map<String, dynamic>> getRecipeInformation(int id) async {
    final uri = Uri.parse(
        "$base/$id/information?apiKey=$apiKey&includeNutrition=true");

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
          "Spoonacular details error ${res.statusCode}: ${res.body}");
    }

    final data = jsonDecode(res.body);

    // ✅ Get instructions cleanly
    String instructions = "";
    try {
      if (data["instructions"] != null && data["instructions"].toString().isNotEmpty) {
        instructions = data["instructions"];
      } else if (data["analyzedInstructions"] is List &&
          data["analyzedInstructions"].isNotEmpty) {
        final steps = data["analyzedInstructions"][0]["steps"] ?? [];
        instructions = steps.map((s) => s["step"].toString()).join("\n\n");
      }
    } catch (_) {}

    // ✅ Try to find calories
    String calories = "";
    try {
      final nutrients = data['nutrition']['nutrients'] as List<dynamic>;
      final cal = nutrients.firstWhere(
        (n) => n['name'].toString().toLowerCase() == 'calories',
        orElse: () => null,
      );
      if (cal != null) {
        calories = "${cal['amount']} ${cal['unit']}";
      }
    } catch (_) {}

    return {
      'id': data['id'],
      'title': data['title'],
      'image': data['image'],
      'servings': data['servings'],
      'readyInMinutes': data['readyInMinutes'],
      'ingredients':
          (data['extendedIngredients'] as List<dynamic>? ?? [])
              .map((g) => g['originalString'] ?? g['original'] ?? g['name'])
              .map((g) => g.toString())
              .toList(),
      'instructions': instructions,
      'calories': calories,
    };
  }
}
