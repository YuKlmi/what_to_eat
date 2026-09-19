import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('预算管理'),
            subtitle: const Text('设置月度外卖预算'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/budget'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('数据备份'),
            subtitle: const Text('导出、恢复或清空本地数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/backup'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('What to Eat v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'What to Eat',
                applicationVersion: '1.0.0',
                children: [
                  const Text('解决外卖选择困难症的APP'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}