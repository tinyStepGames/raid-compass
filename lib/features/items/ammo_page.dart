import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raid_compass/data/tarkov_api.dart';
import 'package:raid_compass/models/tarkov_item.dart';

const String _allCalibers = '__all__';

const String _titleText = '\u5b9f\u5305\u6027\u80fd\u8868';
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
  const AmmoPage({
    required this.api,
    this.initialCaliber,
    this.onFavoritesChanged,
    super.key,
  });

  final TarkovApi api;
  final String? initialCaliber;
  final ValueChanged<Set<String>>? onFavoritesChanged;

  @override
  State<AmmoPage> createState() => _AmmoPageState();
}

class _AmmoPageState extends State<AmmoPage> {
  TarkovApi get _api => widget.api;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<TarkovItem> _items = const [];
  Set<String> _favoriteItemIds = <String>{};

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCaliber = _allCalibers;
  _AmmoSortOrder _sortOrder = _AmmoSortOrder.penetrationHigh;

  @override
  void initState() {
    super.initState();
    _selectedCaliber = widget.initialCaliber ?? _allCalibers;
    _loadAmmo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
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

  void _selectSortOrder(_AmmoSortOrder sortOrder) {
    if (_sortOrder != sortOrder) {
      setState(() {
        _sortOrder = sortOrder;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_verticalScrollController.hasClients) {
        return;
      }

      _verticalScrollController.jumpTo(0);
    });
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
                          if (widget.initialCaliber == null)
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
                      initialValue: _sortOrder,
                      tooltip: _sortText,
                      onSelected: _selectSortOrder,
                      itemBuilder: (context) {
                        return _AmmoSortOrder.values
                            .map(
                              (sortOrder) =>
                                  CheckedPopupMenuItem<_AmmoSortOrder>(
                                    value: sortOrder,
                                    checked: sortOrder == _sortOrder,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const minimumTableWidth = 836.0;
        final tableWidth = constraints.maxWidth > minimumTableWidth
            ? constraints.maxWidth
            : minimumTableWidth;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  _AmmoTableHeader(
                    sortOrder: _sortOrder,
                    onSortChanged: _selectSortOrder,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: _verticalScrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];

                        return _AmmoTableRow(
                          item: item,
                          isFavorite: _favoriteItemIds.contains(item.id),
                          onFavoritePressed: () => _toggleFavorite(item),
                          alternate: index.isOdd,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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

class _AmmoTableHeader extends StatelessWidget {
  const _AmmoTableHeader({
    required this.sortOrder,
    required this.onSortChanged,
  });

  final _AmmoSortOrder sortOrder;
  final ValueChanged<_AmmoSortOrder> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFF222821),
      child: Row(
        children: [
          const SizedBox(width: 64),
          _AmmoHeaderCell(
            width: 260,
            label: '\u5f3e\u85ac\u540d',
            sortOrder: _AmmoSortOrder.name,
            currentSortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          const _AmmoHeaderCell(width: 160, label: '\u53e3\u5f84'),
          _AmmoHeaderCell(
            width: 75,
            label: _damageText,
            sortOrder: _AmmoSortOrder.damageHigh,
            currentSortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          _AmmoHeaderCell(
            width: 75,
            label: _penetrationText,
            sortOrder: _AmmoSortOrder.penetrationHigh,
            currentSortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          _AmmoHeaderCell(
            width: 75,
            label: _armorText,
            sortOrder: _AmmoSortOrder.armorDamageHigh,
            currentSortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          _AmmoHeaderCell(
            width: 75,
            label: _speedText,
            sortOrder: _AmmoSortOrder.speedHigh,
            currentSortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _AmmoHeaderCell extends StatelessWidget {
  const _AmmoHeaderCell({
    required this.width,
    required this.label,
    this.sortOrder,
    this.currentSortOrder,
    this.onSortChanged,
  });

  final double width;
  final String label;
  final _AmmoSortOrder? sortOrder;
  final _AmmoSortOrder? currentSortOrder;
  final ValueChanged<_AmmoSortOrder>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    final selected =
        sortOrder != null &&
        currentSortOrder != null &&
        sortOrder == currentSortOrder;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFE8D58A)
                    : const Color(0xFFC7B778),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 2),
            Icon(
              sortOrder == _AmmoSortOrder.name
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: const Color(0xFFE8D58A),
            ),
          ],
        ],
      ),
    );

    final targetSortOrder = sortOrder;
    final callback = onSortChanged;

    if (targetSortOrder == null || callback == null) {
      return SizedBox(width: width, child: content);
    }

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () => callback(targetSortOrder),
          child: content,
        ),
      ),
    );
  }
}

class _AmmoTableRow extends StatelessWidget {
  const _AmmoTableRow({
    required this.item,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.alternate,
  });

  final TarkovItem item;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final ammo = item.ammo!;

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      color: alternate ? const Color(0xFF121713) : const Color(0xFF151A16),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Center(child: _AmmoImage(item: item)),
          ),
          SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (item.englishName.isNotEmpty &&
                      item.englishName != item.name) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA8A598),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _AmmoValueCell(
            width: 160,
            value: _displayCaliber(ammo.caliber),
            highlight: true,
          ),
          _AmmoValueCell(width: 75, value: '${ammo.damage}'),
          _AmmoValueCell(width: 75, value: '${ammo.penetrationPower}'),
          _AmmoValueCell(width: 75, value: '${ammo.armorDamage}%'),
          _AmmoValueCell(
            width: 75,
            value: ammo.initialSpeed == null
                ? '-'
                : '${ammo.initialSpeed!.round()}',
          ),
          SizedBox(
            width: 52,
            child: IconButton(
              tooltip: isFavorite ? _removeFavoriteText : _addFavoriteText,
              onPressed: onFavoritePressed,
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite
                    ? const Color(0xFFC7B778)
                    : const Color(0xFFA8A598),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmmoValueCell extends StatelessWidget {
  const _AmmoValueCell({
    required this.width,
    required this.value,
    this.highlight = false,
  });

  final double width;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlight
                ? const Color(0xFFC7B778)
                : const Color(0xFFE5E1D6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
      width: 52,
      height: 52,
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

String ammoCaliberDisplayName(String? caliber) {
  return _displayCaliber(caliber);
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
