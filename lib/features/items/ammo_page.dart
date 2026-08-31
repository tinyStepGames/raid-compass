import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raid_compass/data/tarkov_api.dart';
import 'package:raid_compass/models/tarkov_item.dart';

const String _allCalibers = '__all__';

const String _titleText = '\u5f3e\u85ac';
const String _nameSortText = '\u540d\u524d\u9806';
const String _penetrationSortText = '\u8cab\u901a\u529b\u9806';
const String _damageSortText = '\u30c0\u30e1\u30fc\u30b8\u9806';
const String _armorSortText =
    '\u30a2\u30fc\u30de\u30fc\u30c0\u30e1\u30fc\u30b8\u9806';
const String _speedSortText = '\u5f3e\u901f\u9806';
const String _searchHintText = '\u5f3e\u85ac\u540d\u3092\u691c\u7d22';
const String _clearSearchText = '\u691c\u7d22\u6587\u5b57\u3092\u6d88\u53bb';
const String _selectCaliberText = '\u53e3\u5f84\u3092\u9078\u629e';
const String _allCalibersText = '\u3059\u3079\u3066\u306e\u53e3\u5f84';
const String _sortText = '\u4e26\u3079\u66ff\u3048';
const String _retryText = '\u518d\u8a66\u884c';
const String _noResultsText =
    '\u6761\u4ef6\u306b\u4e00\u81f4\u3059\u308b'
    '\u5f3e\u85ac\u304c\u3042\u308a\u307e\u305b\u3093\u3002';
const String _loadErrorText =
    '\u5f3e\u85ac\u30c7\u30fc\u30bf\u3092'
    '\u8aad\u307f\u8fbc\u3081\u307e\u305b\u3093\u3067\u3057\u305f\u3002';
const String _favoriteErrorText =
    '\u304a\u6c17\u306b\u5165\u308a\u3092'
    '\u66f4\u65b0\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f';
const String _addFavoriteText =
    '\u304a\u6c17\u306b\u5165\u308a\u306b\u8ffd\u52a0';
const String _removeFavoriteText =
    '\u304a\u6c17\u306b\u5165\u308a\u304b\u3089\u524a\u9664';
const String _unknownCaliberText = '\u53e3\u5f84\u4e0d\u660e';
const String _damageText = '\u30c0\u30e1\u30fc\u30b8';
const String _penetrationText = '\u8cab\u901a';
const String _armorText = '\u30a2\u30fc\u30de\u30fc';
const String _speedText = '\u5f3e\u901f';
const String _projectileText = '\u5f3e\u4f53';
const String _tracerText = '\u66f3\u5149\u5f3e';
const String _yesText = '\u3042\u308a';
const String _countSuffix = '\u4ef6';

enum _AmmoSortOrder {
  name(_nameSortText),
  penetrationHigh(_penetrationSortText),
  damageHigh(_damageSortText),
  armorDamageHigh(_armorSortText),
  speedHigh(_speedSortText);

  const _AmmoSortOrder(this.label);

  final String label;
}

class AmmoPage extends StatefulWidget {
  const AmmoPage({required this.api, this.onFavoritesChanged, super.key});

  final TarkovApi api;
  final ValueChanged<Set<String>>? onFavoritesChanged;

  @override
  State<AmmoPage> createState() => _AmmoPageState();
}

class _AmmoPageState extends State<AmmoPage> {
  TarkovApi get _api => widget.api;

  final TextEditingController _searchController = TextEditingController();

  List<TarkovItem> _items = const [];
  Set<String> _favoriteItemIds = <String>{};

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCaliber = _allCalibers;
  _AmmoSortOrder _sortOrder = _AmmoSortOrder.penetrationHigh;

  @override
  void initState() {
    super.initState();
    _loadAmmo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAmmo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.getAmmoItems();
      final favoriteIds = await _api.favoriteItemIds();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _favoriteItemIds = favoriteIds;
      });
    } on TarkovApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '$_loadErrorText\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _calibers {
    final values = _items
        .map((item) => item.ammo?.caliber)
        .whereType<String>()
        .where((caliber) => caliber.isNotEmpty)
        .toSet()
        .toList();

    values.sort(
      (first, second) => _displayCaliber(
        first,
      ).toLowerCase().compareTo(_displayCaliber(second).toLowerCase()),
    );

    return values;
  }

  List<TarkovItem> get _visibleItems {
    final query = _searchController.text.trim();

    final visibleItems = _items.where((item) {
      final ammo = item.ammo;

      if (ammo == null) {
        return false;
      }

      if (_selectedCaliber != _allCalibers &&
          ammo.caliber != _selectedCaliber) {
        return false;
      }

      return query.isEmpty || item.matches(query);
    }).toList();

    visibleItems.sort((first, second) {
      final firstAmmo = first.ammo!;
      final secondAmmo = second.ammo!;

      final comparison = switch (_sortOrder) {
        _AmmoSortOrder.name => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        _AmmoSortOrder.penetrationHigh => secondAmmo.penetrationPower.compareTo(
          firstAmmo.penetrationPower,
        ),
        _AmmoSortOrder.damageHigh => secondAmmo.damage.compareTo(
          firstAmmo.damage,
        ),
        _AmmoSortOrder.armorDamageHigh => secondAmmo.armorDamage.compareTo(
          firstAmmo.armorDamage,
        ),
        _AmmoSortOrder.speedHigh => (secondAmmo.initialSpeed ?? 0).compareTo(
          firstAmmo.initialSpeed ?? 0,
        ),
      };

      if (comparison != 0) {
        return comparison;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return visibleItems;
  }

  Future<void> _toggleFavorite(TarkovItem item) async {
    final shouldBeFavorite = !_favoriteItemIds.contains(item.id);

    try {
      await _api.setItemFavorite(item.id, favorite: shouldBeFavorite);

      if (!mounted) {
        return;
      }

      final updatedIds = Set<String>.of(_favoriteItemIds);

      if (shouldBeFavorite) {
        updatedIds.add(item.id);
      } else {
        updatedIds.remove(item.id);
      }

      setState(() {
        _favoriteItemIds = updatedIds;
      });

      widget.onFavoritesChanged?.call(Set.unmodifiable(updatedIds));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$_favoriteErrorText: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

    return Scaffold(
      appBar: AppBar(title: const Text(_titleText)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _searchHintText,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: _clearSearchText,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: PopupMenuButton<String>(
                      tooltip: _selectCaliberText,
                      onSelected: (caliber) {
                        setState(() {
                          _selectedCaliber = caliber;
                        });
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem<String>(
                            value: _allCalibers,
                            child: Text(_allCalibersText),
                          ),
                          ..._calibers.map(
                            (caliber) => PopupMenuItem<String>(
                              value: caliber,
                              child: Text(_displayCaliber(caliber)),
                            ),
                          ),
                        ];
                      },
                      child: _ControlButton(
                        icon: Icons.filter_alt_outlined,
                        label: _selectedCaliber == _allCalibers
                            ? _allCalibersText
                            : _displayCaliber(_selectedCaliber),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PopupMenuButton<_AmmoSortOrder>(
                      tooltip: _sortText,
                      onSelected: (sortOrder) {
                        setState(() {
                          _sortOrder = sortOrder;
                        });
                      },
                      itemBuilder: (context) {
                        return _AmmoSortOrder.values
                            .map(
                              (sortOrder) => PopupMenuItem<_AmmoSortOrder>(
                                value: sortOrder,
                                child: Text(sortOrder.label),
                              ),
                            )
                            .toList(growable: false);
                      },
                      child: _ControlButton(
                        icon: Icons.sort,
                        label: _sortOrder.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${visibleItems.length}$_countSuffix',
                  style: const TextStyle(
                    color: Color(0xFFA8A598),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(visibleItems)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<TarkovItem> visibleItems) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _errorMessage;

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFB85C57),
              ),
              const SizedBox(height: 12),
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadAmmo,
                icon: const Icon(Icons.refresh),
                label: const Text(_retryText),
              ),
            ],
          ),
        ),
      );
    }

    if (visibleItems.isEmpty) {
      return const Center(
        child: Text(_noResultsText, style: TextStyle(color: Color(0xFFA8A598))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: visibleItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = visibleItems[index];

        return _AmmoCard(
          item: item,
          isFavorite: _favoriteItemIds.contains(item.id),
          onFavoritePressed: () => _toggleFavorite(item),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF343A34)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFFC7B778)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _AmmoCard extends StatelessWidget {
  const _AmmoCard({
    required this.item,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  final TarkovItem item;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final ammo = item.ammo!;

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF151A16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmmoImage(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (item.englishName.isNotEmpty &&
                      item.englishName != item.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA8A598),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    _displayCaliber(ammo.caliber),
                    style: const TextStyle(
                      color: Color(0xFFC7B778),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _AmmoMetric(label: _damageText, value: '${ammo.damage}'),
                      _AmmoMetric(
                        label: _penetrationText,
                        value: '${ammo.penetrationPower}',
                      ),
                      _AmmoMetric(
                        label: _armorText,
                        value: '${ammo.armorDamage}%',
                      ),
                      _AmmoMetric(
                        label: _speedText,
                        value: ammo.initialSpeed == null
                            ? '-'
                            : '${ammo.initialSpeed!.round()} m/s',
                      ),
                      if (ammo.projectileCount > 1)
                        _AmmoMetric(
                          label: _projectileText,
                          value: '${ammo.projectileCount}',
                        ),
                      if (ammo.tracer)
                        const _AmmoMetric(label: _tracerText, value: _yesText),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite ? _removeFavoriteText : _addFavoriteText,
              onPressed: onFavoritePressed,
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite
                    ? const Color(0xFFC7B778)
                    : const Color(0xFFA8A598),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmmoImage extends StatefulWidget {
  const _AmmoImage({required this.item});

  final TarkovItem item;

  @override
  State<_AmmoImage> createState() => _AmmoImageState();
}

class _AmmoImageState extends State<_AmmoImage> {
  int _urlIndex = 0;

  @override
  void didUpdateWidget(covariant _AmmoImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.id != widget.item.id) {
      _urlIndex = 0;
    }
  }

  List<String> get _imageUrls {
    final urls = <String>[];

    for (final candidate in [
      widget.item.gridImageLink,
      widget.item.image512pxLink,
      widget.item.iconLink,
    ]) {
      final url = candidate?.trim();

      if (url != null && url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }

    return urls;
  }

  void _tryNextUrl(int failedIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _urlIndex != failedIndex) {
        return;
      }

      setState(() {
        _urlIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final urls = _imageUrls;

    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _urlIndex >= urls.length
          ? _fallback()
          : _buildImage(urls[_urlIndex], _urlIndex),
    );
  }

  Widget _buildImage(String url, int currentIndex) {
    if (kIsWeb) {
      return Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return const Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) {
          _tryNextUrl(currentIndex);
          return _fallback();
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, _) => const Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) {
        _tryNextUrl(currentIndex);
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return const Icon(Icons.adjust, color: Color(0xFFA8A598));
  }
}

class _AmmoMetric extends StatelessWidget {
  const _AmmoMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF222821),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _displayCaliber(String? caliber) {
  if (caliber == null || caliber.isEmpty) {
    return _unknownCaliberText;
  }

  const names = <String, String>{
    'Caliber9x18PM': '9\u00d718 mm',
    'Caliber9x19PARA': '9\u00d719 mm',
    'Caliber9x21': '9\u00d721 mm',
    'Caliber9x33R': '.357 Magnum',
    'Caliber45ACP': '.45 ACP',
    'Caliber46x30': '4.6\u00d730 mm',
    'Caliber57x28': '5.7\u00d728 mm',
    'Caliber545x39': '5.45\u00d739 mm',
    'Caliber556x45NATO': '5.56\u00d745 mm NATO',
    'Caliber762x25TT': '7.62\u00d725 mm',
    'Caliber762x35': '.300 Blackout',
    'Caliber762x39': '7.62\u00d739 mm',
    'Caliber762x51': '7.62\u00d751 mm NATO',
    'Caliber762x54R': '7.62\u00d754 mm R',
    'Caliber86x70': '.338 Lapua Magnum',
    'Caliber127x55': '12.7\u00d755 mm',
    'Caliber12g': '12\u30b2\u30fc\u30b8',
    'Caliber20g': '20\u30b2\u30fc\u30b8',
    'Caliber23x75': '23\u00d775 mm',
  };

  return names[caliber] ?? caliber.replaceFirst('Caliber', '');
}
