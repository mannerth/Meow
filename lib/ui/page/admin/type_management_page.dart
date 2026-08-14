import 'package:flutter/material.dart';
import 'package:meow/api/service/type_service.dart';

class TypeManagementPage extends StatefulWidget {
  const TypeManagementPage({super.key});

  @override
  State<TypeManagementPage> createState() => _TypeManagementPageState();
}

class _TypeManagementPageState extends State<TypeManagementPage> {
  static const _configs = [
    (kind: 'tags', title: '猫咪标签'),
    (kind: 'symptoms', title: '生病症状'),
    (kind: 'colors', title: '猫咪花色'),
    (kind: 'locations', title: '常驻地点'),
    (kind: 'roles', title: '猫咪角色'),
  ];

  final Map<String, List<TypeItem>> _items = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final values = await Future.wait(
      _configs.map((config) => _fetch(config.kind)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _configs.length; i++) {
        _items[_configs[i].kind] = values[i];
      }
      _loading = false;
    });
  }

  Future<List<TypeItem>> _fetch(String kind) {
    return switch (kind) {
      'tags' => TypeService.fetchTags(force: true),
      'symptoms' => TypeService.fetchSymptoms(force: true),
      'colors' => TypeService.fetchColors(force: true),
      'locations' => TypeService.fetchLocations(force: true),
      'roles' => TypeService.fetchRoles(force: true),
      _ => Future.value(const []),
    };
  }

  Future<void> _add(String kind, String title) async {
    var input = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增$title'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(hintText: '请输入名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.trim()),
            child: const Text('新增'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    try {
      await TypeService.batchCreate(kind, [value]);
      await _reloadOne(kind);
    } catch (error) {
      _showError('新增失败，请稍后重试');
    }
  }

  Future<void> _delete(String kind, TypeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除${_titleFor(kind)}'),
        content: Text('确认删除“${item.label}”？已有数据引用此类型时，删除可能会导致原记录无法显示名称。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TypeService.deleteType(kind, item.id);
      await _reloadOne(kind);
    } catch (error) {
      _showError('删除失败，请稍后重试');
    }
  }

  Future<void> _reloadOne(String kind) async {
    final values = await _fetch(kind);
    if (mounted) setState(() => _items[kind] = values);
  }

  String _titleFor(String kind) =>
      _configs.firstWhere((config) => config.kind == kind).title;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('类型数据管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  const Text(
                    '类型接口当前支持批量新增和按 ID 删除。名称修改没有独立接口，因此保留 ID，避免破坏已有引用。',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ..._configs.map(
                    (config) => _TypeSection(
                      title: config.title,
                      items: _items[config.kind] ?? const [],
                      onAdd: () => _add(config.kind, config.title),
                      onDelete: (item) => _delete(config.kind, item),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  final String title;
  final List<TypeItem> items;
  final VoidCallback onAdd;
  final ValueChanged<TypeItem> onDelete;

  const _TypeSection({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '新增$title',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('暂无数据', style: TextStyle(color: Colors.black45))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => GestureDetector(
                        onLongPress: () => onDelete(item),
                        child: InputChip(
                          label: Text('${item.label}  #${item.id}'),
                          onDeleted: () => onDelete(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
