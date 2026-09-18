import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

class TagManageScreen extends ConsumerWidget {
  const TagManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
      ),
      body: StreamBuilder<List<Tag>>(
        stream: db.tagDao.watchAllTags(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tags = snapshot.data!;
          final tasteTags = tags.where((t) => t.dimension == 0).toList();
          final typeTags = tags.where((t) => t.dimension == 1).toList();
          final cuisineTags = tags.where((t) => t.dimension == 2).toList();

          return ListView(
            children: [
              _TagGroup(
                title: '口味',
                tags: tasteTags,
                onAdd: () => _showAddDialog(context, ref, 0),
                onEdit: (tag) => _showEditDialog(context, ref, tag),
                onDelete: (tag) => _deleteTag(context, ref, tag),
              ),
              _TagGroup(
                title: '类型',
                tags: typeTags,
                onAdd: () => _showAddDialog(context, ref, 1),
                onEdit: (tag) => _showEditDialog(context, ref, tag),
                onDelete: (tag) => _deleteTag(context, ref, tag),
              ),
              _TagGroup(
                title: '菜系',
                tags: cuisineTags,
                onAdd: () => _showAddDialog(context, ref, 2),
                onEdit: (tag) => _showEditDialog(context, ref, tag),
                onDelete: (tag) => _deleteTag(context, ref, tag),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, int dimension) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '标签名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final db = ref.read(appDatabaseProvider);
                db.tagDao.insertTag(TagsCompanion(
                  name: drift.Value(controller.text),
                  dimension: drift.Value(dimension),
                  isSystem: const drift.Value(false),
                ));
              }
              ctx.pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Tag tag) {
    final controller = TextEditingController(text: tag.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '标签名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final db = ref.read(appDatabaseProvider);
                db.tagDao.updateTag(TagsCompanion(
                  id: drift.Value(tag.id),
                  name: drift.Value(controller.text),
                ));
              }
              ctx.pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteTag(BuildContext context, WidgetRef ref, Tag tag) {
    if (tag.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统预设标签不能删除')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除标签"${tag.name}"吗？'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final db = ref.read(appDatabaseProvider);
              db.tagDao.deleteTag(tag.id);
              ctx.pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _TagGroup extends StatelessWidget {
  final String title;
  final List<Tag> tags;
  final VoidCallback onAdd;
  final ValueChanged<Tag> onEdit;
  final ValueChanged<Tag> onDelete;

  const _TagGroup({
    required this.title,
    required this.tags,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tag in tags)
              InputChip(
                label: Text(tag.name),
                deleteIcon: tag.isSystem ? null : const Icon(Icons.close, size: 18),
                onDeleted: tag.isSystem ? null : () => onDelete(tag),
                onPressed: () => onEdit(tag),
              ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}