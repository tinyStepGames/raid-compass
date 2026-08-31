import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:raid_compass/data/item_alias_store.dart';
import 'package:raid_compass/data/item_favorite_store.dart';
import 'package:raid_compass/models/tarkov_item.dart';
import 'package:raid_compass/models/tarkov_item_category.dart';

class TarkovApi {
  TarkovApi({ItemAliasStore? aliasStore, ItemFavoriteStore? favoriteStore})
    : _aliasStore = aliasStore ?? ItemAliasStore(),
      _favoriteStore = favoriteStore ?? ItemFavoriteStore();

  final ItemAliasStore _aliasStore;
  final ItemFavoriteStore _favoriteStore;

  Map<String, dynamic>? _cachedDatabase;
  List<TarkovItem>? _cachedItems;
  List<TarkovItemCategory>? _cachedHandbookCategories;
  Map<String, List<String>>? _cachedAliases;
  Set<String>? _cachedFavoriteItemIds;

  Future<List<TarkovItem>> searchItems(String searchText) async {
    final query = searchText.trim();

    if (query.isEmpty) {
      return const [];
    }

    final items = await _loadItems();
    final aliases = await _loadAliases();

    final results =
        items.where((item) {
          return item.matches(
            query,
            customAliases: aliases[item.id] ?? const [],
          );
        }).toList()..sort((first, second) {
          final firstPrice = first.average24hPrice ?? 0;
          final secondPrice = second.average24hPrice ?? 0;

          return secondPrice.compareTo(firstPrice);
        });

    return results.length > 100
        ? results.take(100).toList(growable: false)
        : results;
  }

  Future<List<TarkovItemCategory>> getHandbookCategories() async {
    final cachedCategories = _cachedHandbookCategories;

    if (cachedCategories != null) {
      return cachedCategories;
    }

    final database = await _loadDatabase();
    final items = await _loadItems();
    final rawCategories = database['handbookCategories'];

    if (rawCategories is! List) {
      throw const TarkovApiException('ローカルカテゴリデータが見つかりません。');
    }

    final counts = <String, int>{};

    for (final item in items) {
      for (final categoryId in item.handbookCategoryIds) {
        counts.update(categoryId, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final categories = rawCategories
        .whereType<Map<String, dynamic>>()
        .map(TarkovItemCategory.fromJson)
        .where((category) => category.id.isNotEmpty)
        .map((category) => category.copyWithItemCount(counts[category.id] ?? 0))
        .where((category) => category.itemCount > 0)
        .toList();

    categories.sort((first, second) {
      return first.displayName.toLowerCase().compareTo(
        second.displayName.toLowerCase(),
      );
    });

    _cachedHandbookCategories = List.unmodifiable(categories);

    return _cachedHandbookCategories!;
  }

  Future<List<TarkovItem>> getItemsForHandbookCategory(
    String categoryId,
  ) async {
    if (categoryId.trim().isEmpty) {
      return const [];
    }

    final items = await _loadItems();

    final results = items
        .where((item) => item.handbookCategoryIds.contains(categoryId))
        .toList();

    results.sort((first, second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List.unmodifiable(results);
  }

  Future<Set<String>> favoriteItemIds() async {
    final cachedIds = _cachedFavoriteItemIds;

    if (cachedIds != null) {
      return Set.unmodifiable(cachedIds);
    }

    final itemIds = await _favoriteStore.loadAll();
    _cachedFavoriteItemIds = Set<String>.of(itemIds);

    return Set.unmodifiable(itemIds);
  }

  Future<List<TarkovItem>> getFavoriteItems() async {
    final favoriteIds = await favoriteItemIds();

    if (favoriteIds.isEmpty) {
      return const [];
    }

    final items = await _loadItems();

    final favoriteItems = items
        .where((item) => favoriteIds.contains(item.id))
        .toList();

    favoriteItems.sort((first, second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List.unmodifiable(favoriteItems);
  }

  Future<void> setItemFavorite(String itemId, {required bool favorite}) async {
    await _favoriteStore.setFavorite(itemId, favorite: favorite);

    final itemIds = await _favoriteStore.loadAll();
    _cachedFavoriteItemIds = Set<String>.of(itemIds);
  }

  Future<List<String>> aliasesFor(String itemId) async {
    final aliases = await _loadAliases();

    return List.unmodifiable(aliases[itemId] ?? const []);
  }

  Future<void> addAlias(String itemId, String alias) async {
    await _aliasStore.addAlias(itemId, alias);
    _cachedAliases = await _aliasStore.loadAll();
  }

  Future<void> removeAlias(String itemId, String alias) async {
    await _aliasStore.removeAlias(itemId, alias);
    _cachedAliases = await _aliasStore.loadAll();
  }

  Future<Map<String, List<String>>> _loadAliases() async {
    final cachedAliases = _cachedAliases;

    if (cachedAliases != null) {
      return cachedAliases;
    }

    final aliases = await _aliasStore.loadAll();
    _cachedAliases = aliases;

    return aliases;
  }

  Future<Map<String, dynamic>> _loadDatabase() async {
    final cachedDatabase = _cachedDatabase;

    if (cachedDatabase != null) {
      return cachedDatabase;
    }

    try {
      final source = await rootBundle.loadString('assets/data/items.json');

      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid root object.');
      }

      _cachedDatabase = decoded;

      return decoded;
    } on FlutterError catch (error) {
      throw TarkovApiException(
        'ローカルアイテムデータを読み込めませんでした。',
        details: error.message,
      );
    } on FormatException catch (error) {
      throw TarkovApiException('ローカルアイテムデータが破損しています。', details: error.message);
    }
  }

  Future<List<TarkovItem>> _loadItems() async {
    final cachedItems = _cachedItems;

    if (cachedItems != null) {
      return cachedItems;
    }

    final database = await _loadDatabase();
    final rawItems = database['items'];

    if (rawItems is! List) {
      throw const TarkovApiException('ローカルアイテム一覧が見つかりません。');
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(TarkovItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);

    _cachedItems = items;

    return items;
  }

  void close() {}
}

class TarkovApiException implements Exception {
  const TarkovApiException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() {
    if (details == null || details!.isEmpty) {
      return message;
    }

    return '$message\n$details';
  }
}
