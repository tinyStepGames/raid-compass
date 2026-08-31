import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:raid_compass/models/tarkov_item_category.dart';

class ItemCategoryBrowser extends StatelessWidget {
  const ItemCategoryBrowser({
    required this.categories,
    required this.onSelected,
    super.key,
  });

  final List<TarkovItemCategory> categories;
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
