import 'package:flutter/material.dart';
import 'package:raid_compass/data/tarkov_api.dart';
import 'package:raid_compass/models/tarkov_item.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final TextEditingController _searchController = TextEditingController();

  final TarkovApi _api = TarkovApi();

  List<TarkovItem> _items = const [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = '検索するアイテム名を入力してください。';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.searchItems(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
      });
    } on TarkovApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = const [];
        _errorMessage = error.toString();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = const [];
        _errorMessage = '予期しないエラーが発生しました。\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '例：LEDX、Salewa、M4A1',
              suffixIcon: IconButton(
                tooltip: '検索',
                onPressed: _isLoading ? null : _search,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Tarkov.devから取得中...',
              style: TextStyle(color: Color(0xFFA8A598)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage case final message?) {
      return _ErrorState(message: message, onRetry: _search);
    }

    if (!_hasSearched) {
      return const _InitialState();
    }

    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];

          return _ItemCard(item: item, onTap: () => _showDetails(item));
        },
      ),
    );
  }

  void _showDetails(TarkovItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B201A),
      builder: (context) {
        final bestOffer = item.bestSellOffer;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _ItemImage(imageUrl: item.iconLink, size: 92)),
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.shortName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.shortName,
                    style: const TextStyle(color: Color(0xFFA8A598)),
                  ),
                ],
                const SizedBox(height: 20),
                _DetailRow(
                  label: '24時間平均',
                  value: _formatPrice(item.average24hPrice),
                ),
                _DetailRow(
                  label: '1マス当たり',
                  value: _formatPrice(item.pricePerSlot),
                ),
                _DetailRow(
                  label: 'サイズ',
                  value: '${item.width} × ${item.height}',
                ),
                _DetailRow(
                  label: '最高売却先',
                  value: bestOffer?.vendorName ?? 'データなし',
                ),
                _DetailRow(
                  label: '最高売却価格',
                  value: _formatPrice(bestOffer?.priceRoubles),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});

  final TarkovItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bestOffer = item.bestSellOffer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B201A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30352D)),
          ),
          child: Row(
            children: [
              _ItemImage(imageUrl: item.iconLink, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8E4D8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.shortName.isEmpty
                          ? '${item.width}×${item.height}マス'
                          : '${item.shortName}・'
                                '${item.width}×${item.height}マス',
                      style: const TextStyle(
                        color: Color(0xFFA8A598),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _PriceLabel(
                          label: '平均',
                          value: _formatPrice(item.average24hPrice),
                        ),
                        _PriceLabel(
                          label: '1マス',
                          value: _formatPrice(item.pricePerSlot),
                        ),
                      ],
                    ),
                    if (bestOffer != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${bestOffer.vendorName}へ '
                        '${_formatPrice(bestOffer.priceRoubles)}',
                        style: const TextStyle(
                          color: Color(0xFF7A9E65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF6F7069)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF111410),
        borderRadius: BorderRadius.circular(12),
      ),
      child: url == null || url.isEmpty
          ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF6F7069))
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF6F7069),
                );
              },
            ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: Color(0xFFA8A598), fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFFB7A56A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA8A598)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search, size: 64, color: Color(0xFFB7A56A)),
            SizedBox(height: 16),
            Text(
              'アイテムを検索',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '日本語名または英語名を入力すると、'
              '価格と最適な売却先を確認できます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA8A598), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 60, color: Color(0xFF6F7069)),
            SizedBox(height: 14),
            Text(
              '該当するアイテムがありません',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 7),
            Text(
              '別の名前や短縮名で検索してください。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA8A598)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: Color(0xFFB85C57),
            ),
            const SizedBox(height: 14),
            const Text(
              'データを取得できませんでした',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA8A598)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(int? value) {
  if (value == null || value <= 0) {
    return 'データなし';
  }

  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  return '₽$formatted';
}
