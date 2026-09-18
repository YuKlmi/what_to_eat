import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_provider.dart';
import '../widgets/fortune_wheel.dart';

// 转盘颜色列表
const _wheelColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFFFFE66D),
  Color(0xFF95E1D3),
  Color(0xFFF38181),
  Color(0xFFAA96DA),
  Color(0xFFFCBAD3),
  Color(0xFFA8D8EA),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _recommendationText;
  final Set<String> _excludedDishes = {};
  // 转盘菜品列表（状态变量）
  List<String> _wheelDishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  /// 加载菜品列表
  Future<void> _loadDishes() async {
    setState(() => _isLoading = true);
    
    // 先从 shared_preferences 加载自定义列表
    final prefs = await SharedPreferences.getInstance();
    final savedDishes = prefs.getStringList('wheel_dishes');
    
    if (savedDishes != null && savedDishes.isNotEmpty) {
      setState(() {
        _wheelDishes = savedDishes;
        _isLoading = false;
      });
      return;
    }
    
    // 如果没有保存的列表，则从历史记录中提取
    final db = ref.read(appDatabaseProvider);
    final records = await db.recordDao.getAllRecords();
    final dishNames = <String>{};
    for (final record in records) {
      if (record.dishName != null && record.dishName!.isNotEmpty) {
        dishNames.add(record.dishName!);
      }
    }
    setState(() {
      _wheelDishes = dishNames.toList();
      _isLoading = false;
    });
  }

  /// 保存菜品列表到 shared_preferences
  Future<void> _saveDishes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wheel_dishes', _wheelDishes);
  }

  Future<void> _onSpinEnd(WheelItem item) async {
    setState(() {
      _recommendationText = '推荐：${item.label}';
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('推荐结果'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '今天吃 ${item.label}！',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('再想想'),
            ),
            FilledButton(
              onPressed: () {
                ctx.pop();
                context.push('/records/new');
              },
              child: const Text('去记录'),
            ),
          ],
        ),
      );
    }
  }

  void _showExcludeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final tempExcluded = Set<String>.from(_excludedDishes);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('今天不想吃'),
              content: SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _wheelDishes.map((dish) {
                    final isExcluded = tempExcluded.contains(dish);
                    return FilterChip(
                      label: Text(dish),
                      selected: isExcluded,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            tempExcluded.add(dish);
                          } else {
                            tempExcluded.remove(dish);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => ctx.pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _excludedDishes.clear();
                      _excludedDishes.addAll(tempExcluded);
                    });
                    ctx.pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示编辑转盘内容对话框
  void _showEditWheelDialog() {
    final TextEditingController controller = TextEditingController();
    // 临时列表，用于编辑
    final List<String> tempList = List.from(_wheelDishes);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('编辑转盘内容'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 添加菜品输入框
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: '输入菜品名称',
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                setDialogState(() {
                                  tempList.add(value.trim());
                                });
                                controller.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setDialogState(() {
                                tempList.add(controller.text.trim());
                              });
                              controller.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 菜品列表
                    if (tempList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('还没有添加菜品',
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tempList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    _wheelColors[index % _wheelColors.length],
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(tempList[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    tempList.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => ctx.pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    // 保存到状态变量
                    setState(() {
                      _wheelDishes = tempList;
                    });
                    // 持久化保存
                    _saveDishes();
                    ctx.pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今天吃什么'),
      ),
      body: ref.watch(databaseReadyProvider).when(
            data: (_) => _buildBody(context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('初始化失败: $e')),
          ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // 过滤掉被排除的菜品
    final filteredDishes = _wheelDishes
        .where((d) => !_excludedDishes.contains(d))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 转盘区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 编辑按钮
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton.icon(
                      onPressed: _showEditWheelDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('编辑转盘'),
                    ),
                  ),
                  // 转盘内容
                  if (_isLoading)
                    const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_wheelDishes.isEmpty)
                    SizedBox(
                      height: 280,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              '还没有菜品',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击"编辑转盘"添加菜品',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredDishes.isEmpty)
                    const SizedBox(
                      height: 280,
                      child: Center(child: Text('请减少排除菜品')),
                    )
                  else
                    FortuneWheel(
                      items: filteredDishes.asMap().entries.map((entry) {
                        return WheelItem(
                          id: entry.key,
                          label: entry.value,
                          color:
                              _wheelColors[entry.key % _wheelColors.length],
                        );
                      }).toList(),
                      onSpinEnd: _onSpinEnd,
                    ),
                  const SizedBox(height: 16),
                  // 排除按钮
                  TextButton.icon(
                    onPressed: _wheelDishes.isNotEmpty
                        ? _showExcludeDialog
                        : null,
                    icon: const Icon(Icons.block),
                    label: Text(
                      _excludedDishes.isEmpty
                          ? '今天不想吃...'
                          : '已排除 ${_excludedDishes.length} 个菜品',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_recommendationText != null)
                    Text(
                      _recommendationText!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 快捷操作
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_circle,
                  label: '记录外卖',
                  onTap: () => context.push('/records/new'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.history,
                  label: '历史记录',
                  onTap: () => context.go('/records'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.label,
                  label: '标签管理',
                  onTap: () => context.push('/tags'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}