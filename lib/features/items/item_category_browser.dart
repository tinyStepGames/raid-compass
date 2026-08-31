import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raid_compass/models/tarkov_item_category.dart';

class ItemCategoryGroup {
  const ItemCategoryGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.categories,
  });

  final String id;
  final String name;
  final IconData icon;
  final List<TarkovItemCategory> categories;
}

const List<String> _groupOrder = [
  'weapons',
  'weapon-parts',
  'ammo',
  'gear',
  'medical',
  'provisions',
  'barter',
  'keys-info',
  'containers',
  'other',
];

const Map<String, String> _groupNames = {
  'weapons': '武器',
  'weapon-parts': '武器パーツ',
  'ammo': '弾薬',
  'gear': '装備品',
  'medical': '医薬品',
  'provisions': '食料・飲料',
  'barter': '交換用品',
  'keys-info': '鍵・情報',
  'containers': 'コンテナ',
  'other': 'その他',
};

const Map<String, IconData> _groupIcons = {
  'weapons': Icons.gps_fixed,
  'weapon-parts': Icons.build_outlined,
  'ammo': Icons.adjust,
  'gear': Icons.shield_outlined,
  'medical': Icons.medical_services_outlined,
  'provisions': Icons.restaurant_outlined,
  'barter': Icons.handyman_outlined,
  'keys-info': Icons.key_outlined,
  'containers': Icons.all_inbox_outlined,
  'other': Icons.category_outlined,
};

const Map<String, String> _categoryGroupIds = {
  // 武器
  'assault-carbines': 'weapons',
  'assault-rifles': 'weapons',
  'bolt-action-rifles': 'weapons',
  'grenade-launchers': 'weapons',
  'launchers': 'weapons',
  'machine-guns': 'weapons',
  'marksman-rifles': 'weapons',
  'melee-weapons': 'weapons',
  'pistols': 'weapons',
  'shotguns': 'weapons',
  'special-weapons': 'weapons',
  'submachine-guns': 'weapons',
  'weapons': 'weapons',

  // 武器パーツ
  'assault-scopes': 'weapon-parts',
  'auxiliary-parts': 'weapon-parts',
  'barrels': 'weapon-parts',
  'bipods': 'weapon-parts',
  'charging-handles': 'weapon-parts',
  'collimators': 'weapon-parts',
  'compact-collimators': 'weapon-parts',
  'flashhiders-brakes': 'weapon-parts',
  'flashlights': 'weapon-parts',
  'foregrips': 'weapon-parts',
  'functional-mods': 'weapon-parts',
  'gas-blocks': 'weapon-parts',
  'handguards': 'weapon-parts',
  'iron-sights': 'weapon-parts',
  'laser-aiming-modules': 'weapon-parts',
  'light-laser-devices': 'weapon-parts',
  'magazines': 'weapon-parts',
  'mounts': 'weapon-parts',
  'muzzle-adapters': 'weapon-parts',
  'muzzle-devices': 'weapon-parts',
  'optics': 'weapon-parts',
  'pistol-grips': 'weapon-parts',
  'receivers-slides': 'weapon-parts',
  'sights': 'weapon-parts',
  'special-purpose-sights': 'weapon-parts',
  'stocks-chassis': 'weapon-parts',
  'suppressors': 'weapon-parts',
  'tactical-combo-devices': 'weapon-parts',
  'vital-parts': 'weapon-parts',
  'weapon-parts-mods': 'weapon-parts',

  // 弾薬
  'ammo': 'ammo',
  'ammo-packs': 'ammo',
  'rounds': 'ammo',

  // 装備品
  'backpacks': 'gear',
  'body-armor': 'gear',
  'eyewear': 'gear',
  'facecovers': 'gear',
  'gear': 'gear',
  'gear-components': 'gear',
  'gear-mods': 'gear',
  'headgear': 'gear',
  'headsets': 'gear',
  'tactical-rigs': 'gear',
  'throwables': 'gear',
  'special-equipment': 'gear',

  // 医薬品
  'injectors': 'medical',
  'injury-treatment': 'medical',
  'medical-supplies': 'medical',
  'medication': 'medical',
  'medkits': 'medical',
  'pills': 'medical',

  // 食料・飲料
  'drinks': 'provisions',
  'food': 'provisions',
  'provisions': 'provisions',

  // 交換用品
  'barter-items': 'barter',
  'building-materials': 'barter',
  'electronics': 'barter',
  'energy-elements': 'barter',
  'flammable-materials': 'barter',
  'household-materials': 'barter',
  'money': 'barter',
  'tools': 'barter',
  'valuables': 'barter',

  // 鍵・情報
  'electronic-keys': 'keys-info',
  'info-items': 'keys-info',
  'keys': 'keys-info',
  'maps': 'keys-info',
  'mechanical-keys': 'keys-info',
  'task-items': 'keys-info',

  // コンテナ
  'secure-containers': 'containers',
  'storage-containers': 'containers',

  // その他
  'audio-tapes': 'other',
  'battle-pass-documents': 'other',
  'notes': 'other',
  'others': 'other',
};

String itemCategoryGroupName(String groupId) {
  return _groupNames[groupId] ?? 'その他';
}

List<ItemCategoryGroup> buildItemCategoryGroups(
  List<TarkovItemCategory> categories,
) {
  final grouped = <String, List<TarkovItemCategory>>{
    for (final id in _groupOrder) id: <TarkovItemCategory>[],
  };

  for (final category in categories) {
    final groupId = _categoryGroupIds[category.normalizedName] ?? 'other';
    grouped[groupId]!.add(category);
  }

  final result = <ItemCategoryGroup>[];

  for (final id in _groupOrder) {
    final childCategories = grouped[id]!;

    if (childCategories.isEmpty) {
      continue;
    }

    childCategories.sort(
      (first, second) => first.displayName.toLowerCase().compareTo(
        second.displayName.toLowerCase(),
      ),
    );

    result.add(
      ItemCategoryGroup(
        id: id,
        name: _groupNames[id]!,
        icon: _groupIcons[id]!,
        categories: List.unmodifiable(childCategories),
      ),
    );
  }

  return List.unmodifiable(result);
}

class ItemCategoryBrowser extends StatelessWidget {
  const ItemCategoryBrowser({
    required this.categories,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.onSelected,
    super.key,
  });

  final List<TarkovItemCategory> categories;
  final String? selectedGroupId;
  final ValueChanged<String> onGroupSelected;
  final ValueChanged<TarkovItemCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          '利用できるカテゴリがありません。',
          style: TextStyle(color: Color(0xFFA8A598)),
        ),
      );
    }

    final groups = buildItemCategoryGroups(categories);
    final groupId = selectedGroupId;

    if (groupId == null) {
      return _GroupGrid(groups: groups, onSelected: onGroupSelected);
    }

    ItemCategoryGroup? selectedGroup;

    for (final group in groups) {
      if (group.id == groupId) {
        selectedGroup = group;
        break;
      }
    }

    if (selectedGroup == null) {
      return _GroupGrid(groups: groups, onSelected: onGroupSelected);
    }

    return _CategoryGrid(
      categories: selectedGroup.categories,
      onSelected: onSelected,
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups, required this.onSelected});

  final List<ItemCategoryGroup> groups;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];

        return Material(
          color: const Color(0xFF151A16),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelected(group.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(group.icon, size: 42, color: const Color(0xFFC7B778)),
                  const SizedBox(height: 10),
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.categories.length}カテゴリ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA8A598),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.onSelected});

  final List<TarkovItemCategory> categories;
  final ValueChanged<TarkovItemCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return _CategoryCard(
          category: category,
          onTap: () => onSelected(category),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final TarkovItemCategory category;
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CategoryImage(imageUrl: category.imageLink, size: 58),
              const SizedBox(height: 8),
              Text(
                category.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.itemCount}件',
                style: const TextStyle(fontSize: 11, color: Color(0xFFA8A598)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _fallback();
    }

    if (kIsWeb) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.category_outlined, color: Color(0xFFA8A598)),
    );
  }
}
