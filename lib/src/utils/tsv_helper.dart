import '../model/product.dart';
import 'language_helper.dart';

/// Utility for parsing Open Food Facts TSV database export lines.
/// Designed for streaming 4M+ line datasets with minimal memory overhead.
class TsvHelper {
  static const String _tabSeparator = '\t';
  static const String _unknownValue = 'unknown';
  static final RegExp _langTextPattern = RegExp(
    r"\{'lang':\s*(\w+)\s*,\s*'text':\s*(.+?)\s*\}",
  );

  /// Extracts a single [Product] from a TSV line.
  /// Returns null if the line format is invalid.
  /// Optimized for high-throughput streaming scenarios.
  static Product? extractTSVLine(String tsvLine) {
    final columns = tsvLine.split(_tabSeparator);

    if (columns.length != 7) {
      return null;
    }

    final barcode = _cleanValue(columns[0]);
    final productNameInLanguages = _parseProductNames(columns[1]);
    final quantity = _cleanValue(columns[2]);
    final brands = _cleanValue(columns[3]);
    final nutriscore = _cleanValue(columns[4]);
    final novaGroup = columns[5].isEmpty
        ? null
        : int.tryParse(columns[5].trim());
    final ecoscoreGrade = _cleanValue(columns[6]);

    final product = Product(
      barcode: barcode,
      productNameInLanguages: productNameInLanguages,
      quantity: quantity,
      brands: brands,
      nutriscore: nutriscore,
      ecoscoreGrade: ecoscoreGrade,
    );

    if (novaGroup != null) {
      product.novaGroup = novaGroup;
    }

    return product;
  }

  static String? _cleanValue(String value) {
    if (value.isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _unknownValue) return null;
    return trimmed;
  }

  /// Parses malformed JSON array of product names with language tags.
  /// Input format: [{'lang': en, 'text': Product Name}, ...]
  /// Uses regex to extract lang/text pairs without full JSON parsing.
  static Map<OpenFoodFactsLanguage, String>? _parseProductNames(
    String rawJson,
  ) {
    if (rawJson.isEmpty) return null;

    final matches = _langTextPattern.allMatches(rawJson);
    if (matches.isEmpty) return null;

    final result = <OpenFoodFactsLanguage, String>{};

    for (final match in matches) {
      final langCode = match.group(1);
      final text = match.group(2)?.trim();

      if (langCode == null || text == null || text.isEmpty) continue;

      // 'main' is redundant with actual language codes; skip it
      if (langCode == 'main') continue;

      final language = _mapLanguageCode(langCode);
      if (language != null) {
        result[language] = text;
      }
    }

    return result.isEmpty ? null : result;
  }

  static OpenFoodFactsLanguage? _mapLanguageCode(String code) {
    final language = LanguageHelper.fromJson(code);
    return language != OpenFoodFactsLanguage.UNDEFINED ? language : null;
  }
}
