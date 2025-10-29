// 📁 lib/utils/text_utils.dart

class TextUtils {
  /// Converts text to Title Case
  /// Examples:
  /// "BANANA OATMEAL" → "Banana Oatmeal"
  /// "chicken rice" → "Chicken Rice"
  /// "NISSIN CUP NOODLES" → "Nissin Cup Noodles"

  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    text = text.trim();

    // Words that should stay lowercase (articles, prepositions)
    final lowercaseWords = {'and', 'or', 'with', 'in', 'of', 'the', 'a', 'an'};

    final words = text.split(' ');
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      // Keep acronyms (2-3 letter all-caps words)
      if (word.length <= 3 && word == word.toUpperCase()) {
        result.add(word);
        continue;
      }

      // First word always capitalized
      if (i == 0) {
        result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
        continue;
      }

      // Small words stay lowercase (unless first word)
      if (lowercaseWords.contains(word.toLowerCase())) {
        result.add(word.toLowerCase());
        continue;
      }

      // Normal title case
      result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
    }

    return result.join(' ');
  }

  /// Normalize brand names
  static String normalizeBrand(String brand) {
    if (brand.isEmpty) return brand;

    // Common brand name fixes
    final brandLower = brand.toLowerCase();

    // Keep known brands in their official format
    if (brandLower.contains('nissin')) return 'Nissin';
    if (brandLower.contains('lucky me')) return 'Lucky Me!';
    if (brandLower.contains('payless')) return 'Payless';
    if (brandLower.contains('jack n jill')) return "Jack 'n Jill";
    if (brandLower.contains('monde')) return 'Monde Nissin';
    if (brandLower.contains('liwayway')) return 'Liwayway';

    // International brands
    if (brandLower.contains('maggi')) return 'Maggi';
    if (brandLower.contains('knorr')) return 'Knorr';
    if (brandLower.contains('del monte')) return 'Del Monte';
    if (brandLower.contains('san miguel')) return 'San Miguel';
    if (brandLower.contains('coca cola') || brandLower.contains('coca-cola'))
      return 'Coca-Cola';
    if (brandLower.contains('pepsi')) return 'Pepsi';
    if (brandLower.contains('nestle')) return 'Nestlé';

    // Default to title case
    return toTitleCase(brand);
  }
}
