import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:raid_compass/data/item_alias_store.dart';
import 'package:raid_compass/models/tarkov_item.dart';

class TarkovApi {
  TarkovApi({ItemAliasStore? aliasStore})
    : _aliasStore = aliasStore ?? ItemAliasStore();

  final ItemAliasStore _aliasStore;

  List<TarkovItem>? _cachedItems;
  Map<String, List<String>>? _cachedAliases;

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

  Future<List<TarkovItem>> _loadItems() async {
    final cachedItems = _cachedItems;

    if (cachedItems != null) {
      return cachedItems;
    }

    try {
      final source = await rootBundle.loadString('assets/data/items.json');

      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid root object.');
      }

      final rawItems = decoded['items'];

      if (rawItems is! List) {
        throw const FormatException('Items list is missing.');
      }

      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(TarkovItem.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);

      _cachedItems = items;

      return items;
    } on FlutterError catch (error) {
      throw TarkovApiException(
        'ローカルアイテムデータを読み込めませんでした。',
        details: error.message,
      );
    } on FormatException catch (error) {
      throw TarkovApiException('ローカルアイテムデータが破損しています。', details: error.message);
    }
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
