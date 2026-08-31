import 'package:shared_preferences/shared_preferences.dart';

class ItemFavoriteStore {
  static const String _storageKey = 'favorite_item_ids_v1';

  Future<Set<String>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final storedIds = preferences.getStringList(_storageKey);

    if (storedIds == null) {
      return <String>{};
    }

    return storedIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> setFavorite(String itemId, {required bool favorite}) async {
    final normalizedId = itemId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    final itemIds = await loadAll();

    if (favorite) {
      itemIds.add(normalizedId);
    } else {
      itemIds.remove(normalizedId);
    }

    final sortedIds = itemIds.toList()..sort();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setStringList(_storageKey, sortedIds);
  }
}
