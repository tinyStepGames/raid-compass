import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:raid_compass/models/tarkov_item.dart';

class TarkovApi {
  TarkovApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse('https://api.tarkov.dev/graphql');

  final http.Client _client;

  static const String _searchItemsQuery = r'''
    query SearchItems($name: String!) {
      items(
        name: $name
        lang: ja
        gameMode: regular
        limit: 50
      ) {
        id
        name
        shortName
        basePrice
        avg24hPrice
        width
        height
        iconLink
        wikiLink
        sellFor {
          price
          priceRUB
          currency
          vendor {
            name
          }
        }
      }
    }
  ''';

  Future<List<TarkovItem>> searchItems(String searchText) async {
    final normalizedSearchText = searchText.trim();

    if (normalizedSearchText.isEmpty) {
      return const [];
    }

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': _searchItemsQuery,
              'variables': {'name': normalizedSearchText},
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TarkovApiException(
          'サーバーエラーが発生しました。',
          details: 'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const TarkovApiException('APIから不正なデータが返されました。');
      }

      final errors = decoded['errors'];

      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        final message = firstError is Map<String, dynamic>
            ? firstError['message']?.toString()
            : firstError.toString();

        throw TarkovApiException('アイテムデータを取得できませんでした。', details: message);
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw const TarkovApiException('APIレスポンスにdataがありません。');
      }

      final rawItems = _extractItems(data['items']);

      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(TarkovItem.fromJson)
          .toList();
    } on TimeoutException {
      throw const TarkovApiException(
        '通信がタイムアウトしました。',
        details: 'インターネット接続を確認して再試行してください。',
      );
    } on http.ClientException catch (error) {
      throw TarkovApiException(
        'Tarkov.devへ接続できませんでした。',
        details: error.message,
      );
    } on FormatException {
      throw const TarkovApiException('APIレスポンスを読み取れませんでした。');
    }
  }

  List<dynamic> _extractItems(Object? value) {
    if (value is List) {
      return value;
    }

    // API側でConnection形式になった場合にも対応します。
    if (value is Map<String, dynamic>) {
      final nodes = value['nodes'];

      if (nodes is List) {
        return nodes;
      }

      final items = value['items'];

      if (items is List) {
        return items;
      }

      final edges = value['edges'];

      if (edges is List) {
        return edges
            .whereType<Map<String, dynamic>>()
            .map((edge) => edge['node'])
            .toList();
      }
    }

    return const [];
  }

  void close() {
    _client.close();
  }
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
