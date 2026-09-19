import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'shop_dao.g.dart';

@DriftAccessor(tables: [Shops])
class ShopDao extends DatabaseAccessor<AppDatabase> with _$ShopDaoMixin {
  ShopDao(super.db);

  /// 获取所有店铺
  Future<List<Shop>> getAllShops() => select(shops).get();

  /// 监听所有店铺变化
  Stream<List<Shop>> watchAllShops() => select(shops).watch();

  /// 获取收藏店铺
  Future<List<Shop>> getFavoriteShops() =>
      (select(shops)..where((s) => s.isFavorite.equals(true))).get();

  /// 监听收藏店铺
  Stream<List<Shop>> watchFavoriteShops() =>
      (select(shops)..where((s) => s.isFavorite.equals(true))).watch();

  /// 根据 ID 获取店铺
  Future<Shop?> getShopById(int id) =>
      (select(shops)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// 根据名称搜索店铺
  Future<List<Shop>> searchShops(String keyword) =>
      (select(shops)..where((s) => s.name.like('%$keyword%'))).get();

  /// 根据名称获取店铺
  Future<Shop?> getShopByName(String name) =>
      (select(shops)..where((s) => s.name.equals(name))).getSingleOrNull();

  /// 收藏店铺（不存在则新建，已存在则置为已收藏）
  Future<void> favoriteShop(String name) async {
    final existing = await getShopByName(name);
    if (existing == null) {
      await insertShop(ShopsCompanion(
        name: Value(name),
        isFavorite: const Value(true),
      ));
    } else if (!existing.isFavorite) {
      await updateShop(ShopsCompanion(
        id: Value(existing.id),
        isFavorite: const Value(true),
      ));
    }
  }

  /// 插入店铺
  Future<int> insertShop(ShopsCompanion entry) => into(shops).insert(entry);

  /// 更新店铺
  Future<bool> updateShop(ShopsCompanion entry) =>
      update(shops).replace(entry);

  /// 切换收藏状态
  Future<void> toggleFavorite(int id) async {
    final shop = await getShopById(id);
    if (shop != null) {
      await updateShop(
        ShopsCompanion(
          id: Value(id),
          isFavorite: Value(!shop.isFavorite),
        ),
      );
    }
  }

  /// 删除店铺
  Future<int> deleteShop(int id) =>
      (delete(shops)..where((s) => s.id.equals(id))).go();

  /// 用给定数据替换全部店铺（传空列表即清空）
  Future<void> replaceAll(List<ShopsCompanion> entries) async {
    await transaction(() async {
      await delete(shops).go();
      if (entries.isNotEmpty) {
        await batch((b) => b.insertAll(shops, entries));
      }
    });
  }
}