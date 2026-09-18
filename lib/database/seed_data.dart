import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'app_database.dart';

/// 导入预设标签数据
Future<void> seedPresetTags(AppDatabase db) async {
  // 检查是否已有系统标签
  final existingTags = await db.tagDao.getAllTags();
  if (existingTags.isNotEmpty) return;

  // 读取预设标签 JSON
  final jsonStr = await rootBundle.loadString('assets/data/preset_tags.json');
  final data = json.decode(jsonStr) as Map<String, dynamic>;

  final List<TagsCompanion> entries = [];

  // 口味标签 (dimension = 0)
  final tastes = data['taste'] as List<dynamic>;
  for (final name in tastes) {
    entries.add(TagsCompanion(
      name: Value(name as String),
      dimension: const Value(0),
      isSystem: const Value(true),
    ));
  }

  // 类型标签 (dimension = 1)
  final types = data['type'] as List<dynamic>;
  for (final name in types) {
    entries.add(TagsCompanion(
      name: Value(name as String),
      dimension: const Value(1),
      isSystem: const Value(true),
    ));
  }

  // 菜系标签 (dimension = 2)
  final cuisines = data['cuisine'] as List<dynamic>;
  for (final name in cuisines) {
    entries.add(TagsCompanion(
      name: Value(name as String),
      dimension: const Value(2),
      isSystem: const Value(true),
    ));
  }

  // 批量插入
  await db.tagDao.insertTagsBatch(entries);
}