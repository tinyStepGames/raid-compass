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
      expect(item.matches('サレワ'), isTrue);
      expect(item.matches('サリワ'), isTrue);
    });

    test('Graphics card can be found by Japanese nickname', () {
      final item = TarkovItem.fromJson({
        'id': 'gpu',
        'name': 'グラフィックボード',
        'englishName': 'Graphics card',
        'shortName': 'GPU',
        'normalizedName': 'graphics-card',
        'width': 2,
        'height': 1,
        'sellFor': <Object>[],
      });

      expect(item.matches('グラフィックボード'), isTrue);
      expect(item.matches('グラボ'), isTrue);
      expect(item.matches('GPU'), isTrue);
    });
  });
}
