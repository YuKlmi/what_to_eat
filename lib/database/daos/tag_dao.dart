import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// 获取所有标签
  Future<List<Tag>> getAllTags() => select(tags).get();

  /// 监听所有标签变化
  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  /// 按维度获取标签
  Future<List<Tag>> getTagsByDimension(int dimension) =>
      (select(tags)..where((t) => t.dimension.equals(dimension))).get();

  /// 根据 ID 获取标签
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 根据 ID 列表获取标签
  Future<List<Tag>> getTagsByIds(List<int> ids) =>
      (select(tags)..where((t) => t.id.isIn(ids))).get();

  /// 插入标签
  Future<int> insertTag(TagsCompanion entry) => into(tags).insert(entry);

  /// 批量插入标签
  Future<void> insertTagsBatch(List<TagsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(tags, entries);
    });
  }

  /// 更新标签
  Future<bool> updateTag(TagsCompanion entry) => update(tags).replace(entry);

  /// 删除标签
  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  /// 用给定数据替换全部标签（传空列表即清空）
  Future<void> replaceAll(List<TagsCompanion> entries) async {
    await transaction(() async {
      await delete(tags).go();
      if (entries.isNotEmpty) {
        await batch((b) => b.insertAll(tags, entries));
      }
    });
  }
}