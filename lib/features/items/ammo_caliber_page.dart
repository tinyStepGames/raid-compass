import 'package:flutter/material.dart';
import 'package:raid_compass/data/tarkov_api.dart';
import 'package:raid_compass/features/items/ammo_page.dart';
import 'package:raid_compass/models/tarkov_item.dart';

const String _loadErrorText =
    '\u5f3e\u85ac\u30c7\u30fc\u30bf\u3092'
    '\u8aad\u307f\u8fbc\u3081\u307e\u305b\u3093\u3067\u3057\u305f\u3002';
const String _retryText = '\u518d\u8a66\u884c';
const String _descriptionText =
    '\u53e3\u5f84\u3092\u9078\u629e\u3059\u308b\u3068\u3001'
    '\u305d\u306e\u53e3\u5f84\u306e\u5b9f\u5305\u6027\u80fd\u8868'
    '\u3092\u8868\u793a\u3057\u307e\u3059\u3002';
const String _countSuffix = '\u767a';

class AmmoCaliberPage extends StatefulWidget {
  const AmmoCaliberPage({super.key});

  @override
  State<AmmoCaliberPage> createState() => _AmmoCaliberPageState();
}

class _AmmoCaliberPageState extends State<AmmoCaliberPage> {
  final TarkovApi _api = TarkovApi();

  List<TarkovItem> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAmmo();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadAmmo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _api.getAmmoItems();

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

  List<_CaliberEntry> get _calibers {
    final counts = <String, int>{};

    for (final item in _items) {
      final caliber = item.ammo?.caliber;

      if (caliber == null || caliber.isEmpty) {
        continue;
      }

      counts.update(caliber, (count) => count + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries
        .map(
          (entry) => _CaliberEntry(caliber: entry.key, itemCount: entry.value),
        )
        .toList();

    entries.sort((first, second) {
      return ammoCaliberDisplayName(first.caliber).toLowerCase().compareTo(
        ammoCaliberDisplayName(second.caliber).toLowerCase(),
      );
    });

    return entries;
  }

  Future<void> _openCaliber(String caliber) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AmmoPage(api: _api, initialCaliber: caliber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final calibers = _calibers;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _descriptionText,
              style: TextStyle(color: Color(0xFFA8A598), height: 1.5),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              childAspectRatio: 1.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: calibers.length,
            itemBuilder: (context, index) {
              final entry = calibers[index];

              return _CaliberCard(
                entry: entry,
                onTap: () => _openCaliber(entry.caliber),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CaliberEntry {
  const _CaliberEntry({required this.caliber, required this.itemCount});

  final String caliber;
  final int itemCount;
}

class _CaliberCard extends StatelessWidget {
  const _CaliberCard({required this.entry, required this.onTap});

  final _CaliberEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151A16),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF292E27),
                foregroundColor: Color(0xFFC7B778),
                child: Icon(Icons.adjust),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ammoCaliberDisplayName(entry.caliber),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.itemCount}$_countSuffix',
                      style: const TextStyle(
                        color: Color(0xFFA8A598),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFA8A598)),
            ],
          ),
        ),
      ),
    );
  }
}
