import 'package:flutter_test/flutter_test.dart';
import 'package:raid_compass/models/tarkov_item.dart';

void main() {
  group('TarkovItem ammo parsing', () {
    test('parses bundled ammo properties', () {
      final item = TarkovItem.fromJson({
        'id': 'ammo-test',
        'name': 'テスト弾薬',
        'englishName': 'Test ammunition',
        'shortName': 'TEST',
        'normalizedName': 'test-ammunition',
        'basePrice': 100,
        'width': 1,
        'height': 1,
        'ammo': {
          'caliber': 'Caliber556x45NATO',
          'stackMaxSize': 60,
          'tracer': true,
          'tracerColor': 'red',
          'ammoType': 'bullet',
          'projectileCount': 1,
          'damage': 42,
          'armorDamage': 52,
          'fragmentationChance': 0.2,
          'ricochetChance': 0.38,
          'penetrationChance': 0.7,
          'penetrationPower': 44,
          'penetrationPowerDeviation': 0.05,
          'accuracyModifier': 0,
          'recoilModifier': -5,
          'initialSpeed': 960,
          'lightBleedModifier': 0.1,
          'heavyBleedModifier': 0.05,
          'durabilityBurnFactor': 1.2,
          'heatFactor': 1.1,
          'staminaBurnPerDamage': 0.15,
        },
        'sellFor': <Map<String, dynamic>>[],
      });

      expect(item.isAmmo, isTrue);
      expect(item.ammo, isNotNull);
      expect(item.ammo!.caliber, 'Caliber556x45NATO');
      expect(item.ammo!.damage, 42);
      expect(item.ammo!.penetrationPower, 44);
      expect(item.ammo!.armorDamage, 52);
      expect(item.ammo!.initialSpeed, 960);
      expect(item.ammo!.tracer, isTrue);
      expect(item.ammo!.hasBallisticData, isTrue);
    });

    test('keeps ammo null for ordinary items', () {
      final item = TarkovItem.fromJson({
        'id': 'ordinary-item',
        'name': '通常アイテム',
        'englishName': 'Ordinary item',
        'shortName': 'ITEM',
        'normalizedName': 'ordinary-item',
        'basePrice': 100,
        'width': 1,
        'height': 1,
        'sellFor': <Map<String, dynamic>>[],
      });

      expect(item.isAmmo, isFalse);
      expect(item.ammo, isNull);
    });
  });
}
