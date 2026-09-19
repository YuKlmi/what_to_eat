import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../services/service_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String _dirPath = '';
  List<BackupFileInfo> _backups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(backupServiceProvider);
    final dir = await service.backupDirectoryPath();
    final backups = await service.listBackups();
    if (!mounted) return;
    setState(() {
      _dirPath = dir;
      _backups = backups;
    });
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final path = await ref.read(backupServiceProvider).exportToFile();
      await _load();
      if (!mounted) return;
      await _showExportedDialog(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showExportedDialog(String path) async {
    final fileName = path.split(RegExp(r'[\\/]')).last;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 8),
            SelectableText(
              path,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: path));
              if (!ctx.mounted) return;
              ctx.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('路径已复制')),
              );
            },
            child: const Text('复制路径'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BackupFileInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text('恢复将覆盖当前全部数据，且无法撤销。\n\n备份文件：${info.name}'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final result =
        await ref.read(backupServiceProvider).restoreFromFile(info.path);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('将删除全部记录、标签、收藏与预算，且无法撤销。建议先导出备份。'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await ref.read(backupServiceProvider).clearAll();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('数据已清空')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 备份位置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('备份位置',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(
                    _dirPath.isEmpty ? '读取中...' : _dirPath,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '备份保存在应用私有目录，卸载应用会一并删除。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 导出
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('导出备份',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '把记录、标签、收藏、预算导出为 JSON 文件。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('立即导出'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 可用备份
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('可用备份',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_backups.isEmpty)
                    Text(
                      '还没有备份文件',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    ..._backups.map((info) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(info.name),
                        subtitle: Text(
                          '${DateFormat('yyyy/MM/dd HH:mm').format(info.modifiedAt)}'
                          ' · ${(info.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        ),
                        trailing: TextButton(
                          onPressed: _busy ? null : () => _restore(info),
                          child: const Text('恢复'),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 危险操作
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '危险操作',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '清空后将无法恢复，请先导出备份。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _clearAll,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('清空全部数据'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
