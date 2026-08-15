import 'package:flutter/material.dart';
import 'package:meow/api/service/announcement_service.dart';
import 'package:meow/model/notification.dart';
import 'package:meow/model/static_type.dart';
import 'package:meow/ui/page/admin/announcement_edit_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  bool _loading = true;
  String? _error;
  AnnouncementStatus? _status;
  List<Announcement> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AnnouncementService.fetchAdminAnnouncements(
        status: _status,
      );
      if (mounted) setState(() => _items = response.data?.items ?? const []);
    } catch (_) {
      if (mounted) setState(() => _error = '公告加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Announcement? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnouncementEditPage(announcement: item),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Announcement item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除公告'),
        content: Text('确定删除“${item.title}”吗？'),
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
      await AnnouncementService.deleteAnnouncement(item.id);
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7FB),
    appBar: AppBar(title: const Text('公告管理中心')),
    floatingActionButton: FloatingActionButton(
      onPressed: _openEditor,
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SegmentedButton<AnnouncementStatus?>(
            segments: const [
              ButtonSegment(value: null, label: Text('全部内容')),
              ButtonSegment(
                value: AnnouncementStatus.published,
                label: Text('已发布'),
              ),
              ButtonSegment(value: AnnouncementStatus.draft, label: Text('草稿')),
            ],
            selected: {_status},
            emptySelectionAllowed: false,
            onSelectionChanged: (value) {
              setState(() => _status = value.first);
              _load();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: _body()),
        ),
      ],
    ),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return ListView(
        children: [
          const SizedBox(height: 180),
          Center(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      );
    if (_items.isEmpty)
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('暂无公告')),
        ],
      );
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _AnnouncementCard(
        item: _items[index],
        onEdit: () => _openEditor(_items[index]),
        onDelete: () => _delete(_items[index]),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final Announcement item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.status.label,
                style: TextStyle(
                  color: item.status == AnnouncementStatus.draft
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A),
                  fontSize: 12,
                ),
              ),
            ),
            if (item.createTime != null)
              Text(
                _date(item.createTime!),
                style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if ((item.content ?? item.summary) != null) ...[
          const SizedBox(height: 10),
          Text(
            item.content ?? item.summary!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF667085), height: 1.5),
          ),
        ],
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: onEdit,
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: '删除',
              color: const Color(0xFFF04438),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    ),
  );
}

String _date(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null
      ? value
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
