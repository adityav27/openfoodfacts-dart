import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:test/test.dart';

void main() {
  group('TsvHelper.extractTSVLine', () {
    test('parses complete valid TSV line with all fields', () {
      final line =
          "0000105000011\t[{'lang': main, 'text': Chamomile Herbal Tea}, {'lang': en, 'text': Chamomile Herbal Tea}]\t1 g\tLagg's\tunknown\t1\t";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.barcode, '0000105000011');
      expect(product.quantity, '1 g');
      expect(product.brands, "Lagg's");
      expect(product.nutriscore, isNull); // 'unknown' cleaned to null
      expect(product.novaGroup, 1);
      expect(product.ecoscoreGrade, isNull); // empty string cleaned to null
      expect(product.productNameInLanguages, isNotNull);
      expect(
        product.productNameInLanguages!.length,
        1,
      ); // only 'en', 'main' is skipped
      expect(
        product.productNameInLanguages![OpenFoodFactsLanguage.ENGLISH],
        'Chamomile Herbal Tea',
      );
    });

    test(
      'parses line with accented characters and special chars in product name',
      () {
        final line =
            "0000101209159\t[{'lang': main, 'text': Véritable pâte à tartiner noisettes chocolat noir}, {'lang': fr, 'text': Véritable pâte à tartiner noisettes chocolat noir}]\t350 g\tBovetti\te\t\t";

        final product = TsvHelper.extractTSVLine(line);

        expect(product, isNotNull);
        expect(product!.barcode, '0000101209159');
        expect(product.quantity, '350 g');
        expect(product.brands, 'Bovetti');
        expect(product.nutriscore, 'e');
        expect(product.novaGroup, isNull); // empty string cleaned to null
        expect(product.ecoscoreGrade, isNull); // empty string cleaned to null
        expect(product.productNameInLanguages, isNotNull);
        expect(
          product.productNameInLanguages!.length,
          1,
        ); // only 'fr', 'main' is skipped
        expect(
          product.productNameInLanguages![OpenFoodFactsLanguage.FRENCH],
          'Véritable pâte à tartiner noisettes chocolat noir',
        );
      },
    );

    test('parses line with percentage and special symbols in product name', () {
      final line =
          "0000111048403\t[{'lang': main, 'text': 100% Pure Canola Oil}, {'lang': en, 'text': 100% Pure Canola Oil}]\t\tCanola Harvest\tb\t2\tunknown";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.barcode, '0000111048403');
      expect(product.quantity, isNull); // empty string cleaned to null
      expect(product.brands, 'Canola Harvest');
      expect(product.nutriscore, 'b');
      expect(product.novaGroup, 2);
      expect(product.ecoscoreGrade, isNull); // 'unknown' cleaned to null
      expect(product.productNameInLanguages, isNotNull);
      expect(
        product.productNameInLanguages![OpenFoodFactsLanguage.ENGLISH],
        '100% Pure Canola Oil',
      );
    });

    test(
      'parses line with multiple language variants including non-standard tags',
      () {
        final line =
            "0000111301201\t[{'lang': main, 'text': Canola Harvest® Original Vegetable Oil Spread Tub}, {'lang': en, 'text': Canola Harvest® Original Vegetable Oil Spread Tub}, {'lang': la, 'text': Original Buttery Spread}]\t1 Serving(s) (14 G)\tCanola Harvest\te\t4\t";

        final product = TsvHelper.extractTSVLine(line);

        expect(product, isNotNull);
        expect(product!.barcode, '0000111301201');
        expect(product.quantity, '1 Serving(s) (14 G)');
        expect(product.brands, 'Canola Harvest');
        expect(product.nutriscore, 'e');
        expect(product.novaGroup, 4);
        expect(product.productNameInLanguages, isNotNull);
        expect(
          product.productNameInLanguages!.length,
          2,
        ); // 'en' and 'la', 'main' is skipped
        expect(
          product.productNameInLanguages![OpenFoodFactsLanguage.ENGLISH],
          'Canola Harvest® Original Vegetable Oil Spread Tub',
        );
      },
    );

    test('handles line with all empty optional fields', () {
      final line =
          "0000130008136\t[{'lang': main, 'text': Escalope de dinde}, {'lang': fr, 'text': Escalope de dinde}]\t300 g\t\tunknown\t\t";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.barcode, '0000130008136');
      expect(product.quantity, '300 g');
      expect(product.brands, isNull); // empty string cleaned to null
      expect(product.nutriscore, isNull); // 'unknown' cleaned to null
      expect(product.novaGroup, isNull); // empty string cleaned to null
      expect(product.ecoscoreGrade, isNull); // empty string cleaned to null
      expect(product.productNameInLanguages, isNotNull);
    });

    test('returns null for line with insufficient columns', () {
      final line = "0000101209159\tNot enough\tcolumns";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNull);
    });

    test('returns null for line with too many columns', () {
      final line =
          "code\tname\tqty\tbrand\tnutri\tnova\tecoscore\textra\textra2";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNull);
    });

    test('handles line with empty product name JSON array', () {
      final line = "0000123456789\t\t1 g\tBrand\ta\t1\ta";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.productNameInLanguages, isNull);
    });

    test('parses nova_group as integer correctly', () {
      final lines = [
        "code1\t[{'lang': main, 'text': Name}]\tqty\tbrand\tnuval\t1\tgrade",
        "code2\t[{'lang': main, 'text': Name}]\tqty\tbrand\tnuval\t2\tgrade",
        "code3\t[{'lang': main, 'text': Name}]\tqty\tbrand\tnuval\t3\tgrade",
        "code4\t[{'lang': main, 'text': Name}]\tqty\tbrand\tnuval\t4\tgrade",
      ];

      final products = lines.map(TsvHelper.extractTSVLine).toList();

      expect(products[0]!.novaGroup, 1);
      expect(products[1]!.novaGroup, 2);
      expect(products[2]!.novaGroup, 3);
      expect(products[3]!.novaGroup, 4);
    });

    test('handles malformed nova_group (non-numeric) gracefully', () {
      final line =
          "code\t[{'lang': main, 'text': Name}]\tqty\tbrand\tnuval\tabc\tgrade";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.novaGroup, isNull); // int.tryParse returns null
    });

    test('handles trimmed whitespace in column values', () {
      final line =
          "  0000123456789  \t[{'lang': main, 'text': Trimmed Product}]\t  500 ml  \t  Brand Name  \t  a  \t  \t  b  ";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.barcode, '0000123456789');
      expect(product.quantity, '500 ml');
      expect(product.brands, 'Brand Name');
      expect(product.nutriscore, 'a');
      expect(product.ecoscoreGrade, 'b');
    });

    test('skips main language tag and uses actual language codes', () {
      final line =
          "code\t[{'lang': main, 'text': Main Text}, {'lang': fr, 'text': French Text}]\t\t\t\t\t";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.productNameInLanguages, isNotNull);
      expect(
        product.productNameInLanguages!.length,
        1,
      ); // only 'fr', 'main' is skipped
      expect(
        product.productNameInLanguages![OpenFoodFactsLanguage.FRENCH],
        'French Text',
      );
    });

    test('handles product names with dashes and complex punctuation', () {
      final line =
          "code\t[{'lang': en, 'text': Product Name - With Dashes & Symbols/Special}]\t\t\t\t\t";

      final product = TsvHelper.extractTSVLine(line);

      expect(product, isNotNull);
      expect(product!.productNameInLanguages, isNotNull);
      expect(
        product.productNameInLanguages![OpenFoodFactsLanguage.ENGLISH],
        'Product Name - With Dashes & Symbols/Special',
      );
    });
  });
}
