class TarkovItem {
  const TarkovItem({
    required this.id,
    required this.name,
    required this.englishName,
    required this.shortName,
    required this.normalizedName,
    this.types = const [],
    this.categoryIds = const [],
    this.handbookCategoryIds = const [],
    required this.basePrice,
    required this.width,
    required this.height,
    required this.average24hPrice,
    required this.iconLink,
    this.gridImageLink,
    this.image512pxLink,
    required this.wikiLink,
    this.ammo,
    required this.sellOffers,
  });

  final String id;
  final String name;
  final String englishName;
  final String shortName;
  final String normalizedName;
  final List<String> types;
  final List<String> categoryIds;
  final List<String> handbookCategoryIds;
  final int basePrice;
  final int width;
  final int height;
  final int? average24hPrice;
  final String? iconLink;
  final String? gridImageLink;
  final String? image512pxLink;
  final String? wikiLink;
  final TarkovAmmoProperties? ammo;
  final List<SellOffer> sellOffers;

  bool get isAmmo => ammo != null;

  int get slotCount {
    final slots = width * height;
    return slots <= 0 ? 1 : slots;
  }

  int? get pricePerSlot {
    final price = average24hPrice;

    if (price == null || price <= 0) {
      return null;
    }

    return price ~/ slotCount;
  }

  SellOffer? get bestSellOffer {
    final validOffers = sellOffers
        .where((offer) => offer.priceRoubles > 0)
        .toList();

    if (validOffers.isEmpty) {
      return null;
    }

    validOffers.sort(
      (first, second) => second.priceRoubles.compareTo(first.priceRoubles),
    );

    return validOffers.first;
  }

  bool matches(String query, {Iterable<String> customAliases = const []}) {
    final searchTerms = _createSearchTerms(query);

    if (searchTerms.isEmpty) {
      return false;
    }

    final candidates = [
      name,
      englishName,
      shortName,
      normalizedName,
      ...customAliases,
    ].map(_normalizeSearchText).where((value) => value.isNotEmpty);

    return searchTerms.any(
      (term) => candidates.any((candidate) => candidate.contains(term)),
    );
  }

  factory TarkovItem.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['sellFor'];
    final rawAmmo = json['ammo'];

    return TarkovItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '名称不明',
      englishName: json['englishName'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
      types: _toStringList(json['types']),
      categoryIds: _toStringList(json['categories']),
      handbookCategoryIds: _toStringList(json['handbookCategories']),
      basePrice: _toInt(json['basePrice']) ?? 0,
      width: _toInt(json['width']) ?? 1,
      height: _toInt(json['height']) ?? 1,
      average24hPrice: _toInt(json['avg24hPrice']),
      iconLink: _nullableString(json['iconLink']),
      gridImageLink: _nullableString(json['gridImageLink']),
      image512pxLink: _nullableString(json['image512pxLink']),
      wikiLink: _nullableString(json['wikiLink']),
      ammo: rawAmmo is Map
          ? TarkovAmmoProperties.fromJson(
              rawAmmo.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      sellOffers: rawOffers is List
          ? rawOffers
                .whereType<Map<String, dynamic>>()
                .map(SellOffer.fromJson)
                .toList()
          : const [],
    );
  }
}

class TarkovAmmoProperties {
  const TarkovAmmoProperties({
    required this.caliber,
    required this.stackMaxSize,
    required this.tracer,
    required this.tracerColor,
    required this.ammoType,
    required this.projectileCount,
    required this.damage,
    required this.armorDamage,
    required this.fragmentationChance,
    required this.ricochetChance,
    required this.penetrationChance,
    required this.penetrationPower,
    required this.penetrationPowerDeviation,
    required this.accuracyModifier,
    required this.recoilModifier,
    required this.initialSpeed,
    required this.lightBleedModifier,
    required this.heavyBleedModifier,
    required this.durabilityBurnFactor,
    required this.heatFactor,
    required this.staminaBurnPerDamage,
  });

  final String? caliber;
  final int stackMaxSize;
  final bool tracer;
  final String? tracerColor;
  final String? ammoType;
  final int projectileCount;
  final int damage;
  final int armorDamage;
  final double? fragmentationChance;
  final double? ricochetChance;
  final double? penetrationChance;
  final int penetrationPower;
  final double? penetrationPowerDeviation;
  final double? accuracyModifier;
  final double? recoilModifier;
  final double? initialSpeed;
  final double? lightBleedModifier;
  final double? heavyBleedModifier;
  final double? durabilityBurnFactor;
  final double? heatFactor;
  final double? staminaBurnPerDamage;

  bool get hasBallisticData => damage > 0 || penetrationPower > 0;

  factory TarkovAmmoProperties.fromJson(Map<String, dynamic> json) {
    return TarkovAmmoProperties(
      caliber: _nullableString(json['caliber']),
      stackMaxSize: _toInt(json['stackMaxSize']) ?? 0,
      tracer: _toBool(json['tracer']),
      tracerColor: _nullableString(json['tracerColor']),
      ammoType: _nullableString(json['ammoType']),
      projectileCount: _toInt(json['projectileCount']) ?? 1,
      damage: _toInt(json['damage']) ?? 0,
      armorDamage: _toInt(json['armorDamage']) ?? 0,
      fragmentationChance: _toDouble(json['fragmentationChance']),
      ricochetChance: _toDouble(json['ricochetChance']),
      penetrationChance: _toDouble(json['penetrationChance']),
      penetrationPower: _toInt(json['penetrationPower']) ?? 0,
      penetrationPowerDeviation: _toDouble(json['penetrationPowerDeviation']),
      accuracyModifier: _toDouble(json['accuracyModifier']),
      recoilModifier: _toDouble(json['recoilModifier']),
      initialSpeed: _toDouble(json['initialSpeed']),
      lightBleedModifier: _toDouble(json['lightBleedModifier']),
      heavyBleedModifier: _toDouble(json['heavyBleedModifier']),
      durabilityBurnFactor: _toDouble(json['durabilityBurnFactor']),
      heatFactor: _toDouble(json['heatFactor']),
      staminaBurnPerDamage: _toDouble(json['staminaBurnPerDamage']),
    );
  }
}

class SellOffer {
  const SellOffer({
    required this.vendorName,
    required this.price,
    required this.priceRoubles,
    required this.currency,
  });

  final String vendorName;
  final int price;
  final int priceRoubles;
  final String currency;

  factory SellOffer.fromJson(Map<String, dynamic> json) {
    return SellOffer(
      vendorName: json['vendorName'] as String? ?? '不明',
      price: _toInt(json['price']) ?? 0,
      priceRoubles: _toInt(json['priceRUB']) ?? _toInt(json['price']) ?? 0,
      currency: json['currency'] as String? ?? 'RUB',
    );
  }
}

const Map<String, List<String>> _itemSearchAliases = {
  'サレワ': ['salewa'],
  'サリワ': ['salewa'],
  'グラボ': ['graphics card', 'グラフィックボード', 'gpu'],
  'gpu': ['graphics card', 'グラフィックボード'],
  'ガスアナ': ['gas analyzer', 'ガスアナライザー'],
  'フラドラ': ['secure flash drive', 'flash drive'],
  'テトリス': ['tetriz'],
  'ムンシャ': ['fierce hatchling moonshine', 'moonshine'],
  'インテリ': ['folder with intelligence', 'intelligence'],
  '注射器': ['medical bloodset', 'disposable syringe'],
};

Set<String> _createSearchTerms(String query) {
  final normalizedQuery = _normalizeSearchText(query);

  if (normalizedQuery.isEmpty) {
    return const {};
  }

  final terms = <String>{normalizedQuery};

  // Expand built-in aliases by partial match from two characters.
  final canExpandPartialAlias = normalizedQuery.runes.length >= 2;

  for (final entry in _itemSearchAliases.entries) {
    final groupTerms = <String>{
      _normalizeSearchText(entry.key),
      ...entry.value
          .map(_normalizeSearchText)
          .where((value) => value.isNotEmpty),
    };

    final belongsToGroup =
        groupTerms.contains(normalizedQuery) ||
        (canExpandPartialAlias &&
            groupTerms.any((value) => value.contains(normalizedQuery)));

    if (belongsToGroup) {
      terms.addAll(groupTerms);
    }
  }

  return terms;
}

String _normalizeSearchText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s　_\-/・]+'), '');
}

List<String> _toStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((entry) => entry.toString())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String? _nullableString(Object? value) {
  final text = value?.toString();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

double? _toDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String text => double.tryParse(text),
    _ => null,
  };
}

bool _toBool(Object? value) {
  return switch (value) {
    bool state => state,
    int number => number != 0,
    String text => text.toLowerCase() == 'true' || text == '1',
    _ => false,
  };
}

int? _toInt(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => int.tryParse(text),
    _ => null,
  };
}
