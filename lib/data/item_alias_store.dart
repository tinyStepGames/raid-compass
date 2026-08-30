import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemAliasStore {
  static const String _storageKey = 'item_aliases_v1';

  Future<Map<String, List<String>>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(_storageKey);

    if (source == null || source.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! Map) {
        return {};
      }

      final result = <String, List<String>>{};

      for (final entry in decoded.entries) {
        if (entry.value is! List) {
          continue;
        }

        final aliases = (entry.value as List)
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();

        if (aliases.isNotEmpty) {
          aliases.sort(
            (first, second) =>
                first.toLowerCase().compareTo(second.toLowerCase()),
          );

          result[entry.key.toString()] = aliases;
        }
      }

      return result;
    } on FormatException {
      return {};
    }
  }

  Future<void> addAlias(String itemId, String alias) async {
    final normalizedAlias = alias.trim();

    if (itemId.isEmpty || normalizedAlias.isEmpty) {
      return;
    }

    final aliases = await loadAll();
    final itemAliases = aliases.putIfAbsent(itemId, () => []);

    final alreadyExists = itemAliases.any(
      (value) => value.toLowerCase() == normalizedAlias.toLowerCase(),
    );

    if (!alreadyExists) {
      itemAliases.add(normalizedAlias);
      itemAliases.sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    }

    await _save(aliases);
  }

  Future<void> removeAlias(String itemId, String alias) async {
    final aliases = await loadAll();
    final itemAliases = aliases[itemId];

    if (itemAliases == null) {
      return;
    }

    itemAliases.removeWhere(
      (value) => value.toLowerCase() == alias.trim().toLowerCase(),
    );

    if (itemAliases.isEmpty) {
      aliases.remove(itemId);
    }

    await _save(aliases);
  }

  Future<void> _save(Map<String, List<String>> aliases) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_storageKey, jsonEncode(aliases));
  }
}
