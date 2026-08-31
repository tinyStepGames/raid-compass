class TarkovItemCategory {
  const TarkovItemCategory({
    required this.id,
    required this.name,
    required this.englishName,
    required this.normalizedName,
    required this.imageLink,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final String englishName;
  final String normalizedName;
  final String? imageLink;
  final int itemCount;

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name;
    }

    if (englishName.trim().isNotEmpty) {
      return englishName;
    }

    return normalizedName;
  }

  TarkovItemCategory copyWithItemCount(int value) {
    return TarkovItemCategory(
      id: id,
      name: name,
      englishName: englishName,
      normalizedName: normalizedName,
      imageLink: imageLink,
      itemCount: value,
    );
  }

  factory TarkovItemCategory.fromJson(Map<String, dynamic> json) {
    return TarkovItemCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
      imageLink: _nullableString(json['imageLink']),
    );
  }
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}
