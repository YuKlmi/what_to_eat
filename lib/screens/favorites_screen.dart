import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索店铺...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Shop>>(
        stream: db.shopDao.watchFavoriteShops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var shops = snapshot.data ?? [];

          // 搜索过滤
          if (_searchQuery.isNotEmpty) {
            shops = shops
                .where((s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty ? '没有找到匹配的店铺' : '还没有收藏',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '记录外卖时可添加收藏',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return _ShopTile(shop: shop);
            },
          );
        },
      ),
    );
  }
}

class _ShopTile extends ConsumerWidget {
  final Shop shop;

  const _ShopTile({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(shop.name.isNotEmpty ? shop.name[0] : '?'),
        ),
        title: Text(shop.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => db.shopDao.toggleFavorite(shop.id),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/records/new'),
            ),
          ],
        ),
        onTap: () => context.push('/records/new'),
      ),
    );
  }
}