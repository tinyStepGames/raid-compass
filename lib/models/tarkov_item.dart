class TarkovItem {
  const TarkovItem({
    required this.id,
    required this.name,
    required this.shortName,
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
  final String shortName;
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
    if (sellOffers.isEmpty) {
      return null;
    }

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

  factory TarkovItem.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['sellFor'];

    return TarkovItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '蜷咲ｧｰ荳肴・',
      shortName: json['shortName'] as String? ?? '',
      basePrice: _toInt(json['basePrice']) ?? 0,
      width: _toInt(json['width']) ?? 1,
      height: _toInt(json['height']) ?? 1,
      average24hPrice: _toInt(json['avg24hPrice']),
      iconLink: json['iconLink'] as String?,
      wikiLink: json['wikiLink'] as String?,
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
    final vendor = json['vendor'];

    return SellOffer(
      vendorName: vendor is Map<String, dynamic>
          ? vendor['name'] as String? ?? '荳肴・'
          : '荳肴・',
      price: _toInt(json['price']) ?? 0,
      priceRoubles: _toInt(json['priceRUB']) ?? _toInt(json['price']) ?? 0,
      currency: json['currency'] as String? ?? 'RUB',
    );
  }
}

int? _toInt(Object? value) {
  return switch (value) {
    int number => number,
    double number => number.round(),
    String text => int.tryParse(text),
    _ => null,
  };
}
