class TarkovItem {
  const TarkovItem({
    required this.id,
    required this.name,
    required this.englishName,
    required this.shortName,
    required this.normalizedName,
    required this.basePrice,
    required this.width,
    required this.height,
    required this.average24hPrice,
    required this.iconLink,
    required this.wikiLink,
    required this.sellOffers,
  });

  final String id;
  final String name;
  final String englishName;
  final String shortName;
  final String normalizedName;
  final int basePrice;
  final int width;
  final int height;
  final int? average24hPrice;
  final String? iconLink;
  final String? wikiLink;
  final List<SellOffer> sellOffers;

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

    return TarkovItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '名称不明',
      englishName: json['englishName'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
      basePrice: _toInt(json['basePrice']) ?? 0,
      width: _toInt(json['width']) ?? 1,
      height: _toInt(json['height']) ?? 1,
      average24hPrice: _toInt(json['avg24hPrice']),
      iconLink: _nullableString(json['iconLink']),
      wikiLink: _nullableString(json['wikiLink']),
      sellOffers: rawOffers is List
          ? rawOffers
                .whereType<Map<String, dynamic>>()
                .map(SellOffer.fromJson)
                .toList()
          : const [],
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

  for (final entry in _itemSearchAliases.entries) {
    final normalizedKey = _normalizeSearchText(entry.key);
    final normalizedAliases = entry.value
        .map(_normalizeSearchText)
        .where((value) => value.isNotEmpty)
        .toSet();

    final belongsToGroup =
        normalizedKey == normalizedQuery ||
        normalizedAliases.contains(normalizedQuery);

    if (!belongsToGroup) {
      continue;
    }

    terms.add(normalizedKey);
    terms.addAll(normalizedAliases);
  }

  return terms;
}

String _normalizeSearchText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s　_\-/・]+'), '');
}

String? _nullableString(Object? value) {
  final text = value?.toString();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

int? _toInt(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => int.tryParse(text),
    _ => null,
  };
}
