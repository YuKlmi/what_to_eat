import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

/// 记录卡片上的操作项
enum _TileAction { edit, delete }

class RecordListScreen extends ConsumerWidget {
  const RecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外卖记录'),
      ),
      body: StreamBuilder<List<Record>>(
        stream: db.recordDao.watchAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('还没有记录', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/records/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('记录第一餐'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _RecordTile(record: records[index], db: db);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/records/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final Record record;
  final AppDatabase db;

  const _RecordTile({required this.record, required this.db});

  Future<void> _onAction(BuildContext context, _TileAction action) async {
    switch (action) {
      case _TileAction.edit:
        context.push('/records/edit/${record.id}');
        break;
      case _TileAction.delete:
        await _confirmAndDelete(context);
        break;
    }
  }

  /// 二次确认后删除记录，统计页会随数据变更自动刷新
  Future<void> _confirmAndDelete(BuildContext context) async {
    // 提前获取，避免异步间隙后再使用 context
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '删除后该记录及其在统计中的计入都会被移除，且无法撤销。\n\n'
          '${record.shopName} · ${record.dishName ?? '未填菜品'} · '
          '￥${record.price.toStringAsFixed(1)}',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await db.recordDao.deleteRecord(record.id);
    messenger.showSnackBar(
      SnackBar(content: Text('已删除「${record.shopName}」的记录')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(record.shopName.isNotEmpty ? record.shopName[0] : '?'),
        ),
        title: Text(record.shopName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record.dishName ?? '未填菜品'} · '
              '￥${record.price.toStringAsFixed(1)}',
            ),
            Text(
              DateFormat('MM/dd HH:mm').format(record.mealTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_TileAction>(
          tooltip: '更多操作',
          onSelected: (action) => _onAction(context, action),
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: _TileAction.edit,
              child: Text('编辑'),
            ),
            PopupMenuItem(
              value: _TileAction.delete,
              child: Text('删除'),
            ),
          ],
        ),
        onTap: () => context.push('/records/edit/${record.id}'),
      ),
    );
  }
}
