import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> downloadData(HttpClient client, String url) async {
  stdout.writeln('Downloading $url');

  final request = await client.getUrl(Uri.parse(url));
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');

  final response = await request.close();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
  }

  final body = await utf8.decoder.bind(response).join();
  final decoded = jsonDecode(body);

  if (decoded is! Map) {
    throw const FormatException('Root JSON value is not an object.');
  }

  final data = decoded['data'];

  if (data is! Map) {
    throw const FormatException('JSON does not contain a data object.');
  }

  return data.map((key, value) => MapEntry(key.toString(), value));
}

String translatedName(
  Map<String, dynamic> translations,
  Object? key,
  String fallback,
) {
  final translationKey = key?.toString();

  if (translationKey == null || translationKey.isEmpty) {
    return fallback;
  }

  final value = translations[translationKey]?.toString();

  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  return value;
}

int integerValue(Object? value, [int fallback = 0]) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => int.tryParse(text) ?? fallback,
    _ => fallback,
  };
}

Map<String, dynamic>? bestSellOffer(Object? value) {
  if (value is! List) {
    return null;
  }

  Map<String, dynamic>? best;
  var bestPrice = 0;

  for (final rawOffer in value) {
    if (rawOffer is! Map) {
      continue;
    }

    final offer = rawOffer.map((key, value) => MapEntry(key.toString(), value));

    final price = integerValue(offer['priceRUB']);

    if (price > bestPrice) {
      bestPrice = price;
      best = offer;
    }
  }

  return best;
}

List<String> stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) => entry.toString())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> buildCategoryOutput(
  Object? source,
  Map<String, dynamic> japanese,
  Map<String, dynamic> english,
) {
  if (source is! Map) {
    return const [];
  }

  final output = <Map<String, dynamic>>[];

  for (final entry in source.entries) {
    if (entry.value is! Map) {
      continue;
    }

    final category = (entry.value as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final id = category['id']?.toString() ?? entry.key.toString();
    final normalizedName = category['normalizedName']?.toString() ?? id;

    final englishName = translatedName(
      english,
      category['name'],
      normalizedName,
    );

    final japaneseName = translatedName(
      japanese,
      category['name'],
      englishName,
    );

    output.add({
      'id': id,
      'name': japaneseName,
      'englishName': englishName,
      'normalizedName': normalizedName,
      'imageLink': category['imageLink']?.toString(),
    });
  }

  output.sort((first, second) {
    final firstName = first['englishName']?.toString() ?? '';
    final secondName = second['englishName']?.toString() ?? '';

    return firstName.toLowerCase().compareTo(secondName.toLowerCase());
  });

  return output;
}

double? decimalValue(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String text => double.tryParse(text),
    _ => null,
  };
}

Map<String, dynamic>? buildAmmoProperties(Object? source) {
  if (source is! Map) {
    return null;
  }

  final properties = source.map(
    (key, value) => MapEntry(key.toString(), value),
  );

  if (properties['propertiesType']?.toString() != 'ItemPropertiesAmmo') {
    return null;
  }

  return {
    'caliber': properties['caliber']?.toString(),
    'stackMaxSize': integerValue(properties['stackMaxSize']),
    'tracer': properties['tracer'] == true,
    'tracerColor': properties['tracerColor']?.toString(),
    'ammoType': properties['ammoType']?.toString(),
    'projectileCount': integerValue(properties['projectileCount'], 1),
    'damage': integerValue(properties['damage']),
    'armorDamage': integerValue(properties['armorDamage']),
    'fragmentationChance': decimalValue(properties['fragmentationChance']),
    'ricochetChance': decimalValue(properties['ricochetChance']),
    'penetrationChance': decimalValue(properties['penetrationChance']),
    'penetrationPower': integerValue(properties['penetrationPower']),
    'penetrationPowerDeviation': decimalValue(
      properties['penetrationPowerDeviation'],
    ),
    'accuracyModifier': decimalValue(properties['accuracyModifier']),
    'recoilModifier': decimalValue(properties['recoilModifier']),
    'initialSpeed': decimalValue(properties['initialSpeed']),
    'lightBleedModifier': decimalValue(properties['lightBleedModifier']),
    'heavyBleedModifier': decimalValue(properties['heavyBleedModifier']),
    'durabilityBurnFactor': decimalValue(properties['durabilityBurnFactor']),
    'heatFactor': decimalValue(properties['heatFactor']),
    'staminaBurnPerDamage': decimalValue(properties['staminaBurnPerDamage']),
  };
}

Future<void> main() async {
  const baseUrl = 'https://json.tarkov.dev/regular';

  final client = HttpClient()..userAgent = 'RaidCompassDataBuilder/1.0';

  try {
    final itemData = await downloadData(client, '$baseUrl/items');
    final japanese = await downloadData(client, '$baseUrl/items_ja');
    final english = await downloadData(client, '$baseUrl/items_en');
    final traders = await downloadData(client, '$baseUrl/traders');
    final traderJapanese = await downloadData(client, '$baseUrl/traders_ja');

    final rawItems = itemData['items'];

    if (rawItems is! Map) {
      throw const FormatException(
        'The item data does not contain an items object.',
      );
    }

    final items = rawItems.map((key, value) => MapEntry(key.toString(), value));

    final itemCategories = buildCategoryOutput(
      itemData['itemCategories'],
      japanese,
      english,
    );

    final handbookCategories = buildCategoryOutput(
      itemData['handbookCategories'],
      japanese,
      english,
    );

    stdout.writeln('Item categories: ${itemCategories.length}');
    stdout.writeln('Handbook categories: ${handbookCategories.length}');

    stdout.writeln('Processing ${items.length} items...');

    final outputItems = <Map<String, dynamic>>[];
    var processed = 0;

    for (final entry in items.entries) {
      processed++;

      if (entry.value is! Map) {
        continue;
      }

      final item = (entry.value as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final normalizedName = item['normalizedName']?.toString() ?? entry.key;

      final englishName = translatedName(english, item['name'], normalizedName);

      final japaneseName = translatedName(japanese, item['name'], englishName);

      final englishShortName = translatedName(english, item['shortName'], '');

      final japaneseShortName = translatedName(
        japanese,
        item['shortName'],
        englishShortName,
      );

      final bestOffer = bestSellOffer(item['sellToTrader']);
      final sellFor = <Map<String, dynamic>>[];

      if (bestOffer != null) {
        final traderId = bestOffer['trader']?.toString() ?? '';
        final rawTrader = traders[traderId];

        Map<String, dynamic>? trader;

        if (rawTrader is Map) {
          trader = rawTrader.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }

        final vendorName = trader == null
            ? traderId
            : translatedName(
                traderJapanese,
                trader['name'],
                trader['normalizedName']?.toString() ?? traderId,
              );

        sellFor.add({
          'vendorName': vendorName,
          'price': integerValue(bestOffer['price']),
          'priceRUB': integerValue(bestOffer['priceRUB']),
          'currency': bestOffer['currency']?.toString() ?? 'RUB',
        });
      }

      outputItems.add({
        'id': item['id']?.toString() ?? entry.key,
        'name': japaneseName,
        'englishName': englishName,
        'shortName': japaneseShortName,
        'types': stringList(item['types']),
        'categories': stringList(item['categories']),
        'handbookCategories': stringList(item['handbookCategories']),
        'normalizedName': normalizedName,
        'basePrice': integerValue(item['basePrice']),
        'avg24hPrice': item['avg24hPrice'],
        'width': integerValue(item['width'], 1),
        'height': integerValue(item['height'], 1),
        'iconLink': item['iconLink']?.toString(),
        'gridImageLink': item['gridImageLink']?.toString(),
        'image512pxLink': item['image512pxLink']?.toString(),
        'wikiLink': item['wikiLink']?.toString(),
        'ammo': buildAmmoProperties(item['properties']),
        'sellFor': sellFor,
      });

      if (processed % 500 == 0) {
        stdout.writeln('Processed $processed / ${items.length}');
      }
    }

    outputItems.sort((first, second) {
      final firstName = first['englishName']?.toString() ?? '';
      final secondName = second['englishName']?.toString() ?? '';

      return firstName.toLowerCase().compareTo(secondName.toLowerCase());
    });

    final output = {
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'json.tarkov.dev',
      'gameMode': 'regular',
      'itemCategories': itemCategories,
      'handbookCategories': handbookCategories,
      'items': outputItems,
    };

    final outputDirectory = Directory('assets/data');
    await outputDirectory.create(recursive: true);

    final outputFile = File('assets/data/items.json');
    await outputFile.writeAsString(
      jsonEncode(output),
      encoding: utf8,
      flush: true,
    );

    final size = await outputFile.length();

    stdout.writeln('');
    stdout.writeln('Completed.');
    stdout.writeln('Items: ${outputItems.length}');
    stdout.writeln('Output: ${outputFile.absolute.path}');
    stdout.writeln('Size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
  } finally {
    client.close(force: true);
  }
}
