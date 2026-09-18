import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

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
              final record = records[index];
              return _RecordTile(record: record);
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

class _RecordTile extends ConsumerWidget {
  final Record record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(record.shopName.isNotEmpty ? record.shopName[0] : '?'),
        ),
        title: Text(record.shopName),
        subtitle: Text(
          '${record.dishName ?? ''} · ￥${record.price.toStringAsFixed(1)}',
        ),
        trailing: Text(
          dateFormat.format(record.mealTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => context.push('/records/edit/${record.id}'),
      ),
    );
  }
}