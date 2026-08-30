import 'package:flutter_test/flutter_test.dart';
import 'package:raid_compass/models/tarkov_item.dart';

void main() {
  group('TarkovItem search aliases', () {
    test('Salewa can be found by Japanese nickname', () {
      final item = TarkovItem.fromJson({
        'id': 'salewa',
        'name': 'Salewa first aid kit',
        'englishName': 'Salewa first aid kit',
        'shortName': 'Salewa',
        'normalizedName': 'salewa-first-aid-kit',
        'width': 1,
        'height': 2,
        'sellFor': <Object>[],
      });

      expect(item.matches('Salewa'), isTrue);
      expect(item.matches('\u30b5\u30ec\u30ef'), isTrue);
      expect(item.matches('\u30b5\u30ea\u30ef'), isTrue);
    });

    test('Graphics card can be found by common nicknames', () {
      final item = TarkovItem.fromJson({
        'id': 'gpu',
        'name': 'Graphics card',
        'englishName': 'Graphics card',
        'shortName': 'GPU',
        'normalizedName': 'graphics-card',
        'width': 2,
        'height': 1,
        'sellFor': <Object>[],
      });

      expect(
        item.matches(
          '\u30b0\u30e9\u30d5\u30a3\u30c3\u30af'
          '\u30dc\u30fc\u30c9',
        ),
        isTrue,
      );
      expect(item.matches('\u30b0\u30e9\u30dc'), isTrue);
      expect(item.matches('GPU'), isTrue);
    });

    test('Custom alias can be used for search', () {
      final item = TarkovItem.fromJson({
        'id': 'custom-item',
        'name': 'Graphics card',
        'englishName': 'Graphics card',
        'shortName': 'GPU',
        'normalizedName': 'graphics-card',
        'width': 2,
        'height': 1,
        'sellFor': <Object>[],
      });

      const customAlias = '\u30d3\u30c3\u30c8\u30b3\u30a4\u30f3\u7528';

      expect(
        item.matches(customAlias, customAliases: const [customAlias]),
        isTrue,
      );
    });
  });
}
