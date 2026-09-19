import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:go_router/go_router.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

class RecordFormScreen extends ConsumerStatefulWidget {
  final int? recordId;
  final String? initialShopName;
  final String? initialDishName;

  const RecordFormScreen({
    super.key,
    this.recordId,
    this.initialShopName,
    this.initialDishName,
  });

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopController = TextEditingController();
  final _dishController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _mealTime = DateTime.now();
  List<int> _selectedTagIds = [];
  bool _isLoading = false;
  bool _isFavorite = false;

  bool get isEditing => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadRecord();
    } else {
      _shopController.text = widget.initialShopName ?? '';
      _dishController.text = widget.initialDishName ?? '';
      _syncFavoriteState();
    }
  }

  /// 同步"收藏此店铺"开关状态
  Future<void> _syncFavoriteState() async {
    final name = _shopController.text.trim();
    if (name.isEmpty) {
      // 避免在 initState 阶段同步触发 setState
      if (mounted && _isFavorite) {
        setState(() => _isFavorite = false);
      }
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final shop = await db.shopDao.getShopByName(name);
    if (mounted) {
      setState(() => _isFavorite = shop?.isFavorite ?? false);
    }
  }

  Future<void> _loadRecord() async {
    final db = ref.read(appDatabaseProvider);
    final record = await db.recordDao.getRecordById(widget.recordId!);
    if (record != null && mounted) {
      setState(() {
        _shopController.text = record.shopName;
        _dishController.text = record.dishName ?? '';
        _priceController.text = record.price.toString();
        _noteController.text = record.note ?? '';
        _mealTime = record.mealTime;
        _selectedTagIds = List<int>.from(
          record.tagIds
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => int.parse(s.trim())),
        );
      });
      await _syncFavoriteState();
    }
  }

  /// 从收藏列表快速带出店铺名
  Future<void> _pickFavoriteShop() async {
    final db = ref.read(appDatabaseProvider);
    final shops = await db.shopDao.getFavoriteShops();
    if (!mounted) return;

    if (shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还没有收藏的店铺，勾选下方"收藏此店铺"即可添加')),
      );
      return;
    }

    final picked = await showModalBottomSheet<Shop>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: shops
            .map((s) => ListTile(
                  leading: CircleAvatar(
                    child: Text(s.name.isNotEmpty ? s.name[0] : '?'),
                  ),
                  title: Text(s.name),
                  onTap: () => ctx.pop(s),
                ))
            .toList(),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _shopController.text = picked.name;
        _isFavorite = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final db = ref.read(appDatabaseProvider);
    final price = double.tryParse(_priceController.text) ?? 0;
    final tagIdsJson = _selectedTagIds.toString();

    if (isEditing) {
      await db.recordDao.updateRecord(
        RecordsCompanion(
          id: drift.Value(widget.recordId!),
          shopName: drift.Value(_shopController.text),
          price: drift.Value(price),
          tagIds: drift.Value(tagIdsJson),
          dishName: drift.Value(
            _dishController.text.isNotEmpty ? _dishController.text : null,
          ),
          note: drift.Value(
            _noteController.text.isNotEmpty ? _noteController.text : null,
          ),
          mealTime: drift.Value(_mealTime),
        ),
      );
    } else {
      await db.recordDao.insertRecord(
        RecordsCompanion(
          shopName: drift.Value(_shopController.text),
          price: drift.Value(price),
          tagIds: drift.Value(tagIdsJson),
          dishName: drift.Value(
            _dishController.text.isNotEmpty ? _dishController.text : null,
          ),
          note: drift.Value(
            _noteController.text.isNotEmpty ? _noteController.text : null,
          ),
          mealTime: drift.Value(_mealTime),
        ),
      );
    }

    // 同步收藏状态
    final shopName = _shopController.text.trim();
    if (_isFavorite && shopName.isNotEmpty) {
      await db.shopDao.favoriteShop(shopName);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('删除')),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(appDatabaseProvider);
      await db.recordDao.deleteRecord(widget.recordId!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑记录' : '记录外卖'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 店铺名称
            TextFormField(
              controller: _shopController,
              decoration: InputDecoration(
                labelText: '店铺名称 *',
                hintText: '例如：麦当劳',
                prefixIcon: const Icon(Icons.store),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  tooltip: '从收藏选择',
                  onPressed: _pickFavoriteShop,
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? '请输入店铺名称' : null,
              onChanged: (_) => _syncFavoriteState(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.favorite),
              title: const Text('收藏此店铺'),
              subtitle: const Text('收藏后可在收藏页快速记录'),
              value: _isFavorite,
              onChanged: _shopController.text.trim().isEmpty
                  ? null
                  : (v) => setState(() => _isFavorite = v),
            ),
            const SizedBox(height: 8),

            // 菜品名称
            TextFormField(
              controller: _dishController,
              decoration: const InputDecoration(
                labelText: '菜品名称',
                hintText: '例如：巨无霸套餐',
                prefixIcon: Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(height: 16),

            // 价格
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '价格 *',
                hintText: '例如：35.5',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入价格';
                if (double.tryParse(v) == null) return '请输入有效数字';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 用餐时间
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('用餐时间'),
              subtitle: Text(
                '${_mealTime.year}-${_mealTime.month.toString().padLeft(2, '0')}-${_mealTime.day.toString().padLeft(2, '0')} '
                '${_mealTime.hour.toString().padLeft(2, '0')}:${_mealTime.minute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _mealTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_mealTime),
                );
                if (time != null && mounted) {
                  setState(() {
                    _mealTime = DateTime(
                      date.year, date.month, date.day,
                      time.hour, time.minute,
                    );
                  });
                }
              },
            ),
            const Divider(),

            // 标签选择
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('选择标签', style: TextStyle(fontSize: 16)),
            ),
            StreamBuilder<List<Tag>>(
              stream: db.tagDao.watchAllTags(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final tags = snapshot.data!;
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.map((tag) {
                    final selected = _selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 保存按钮
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? '保存修改' : '记录'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopController.dispose();
    _dishController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}