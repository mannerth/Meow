import 'package:flutter/material.dart';
import 'package:meow/api/service/notification_service.dart';
import 'package:meow/model/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<AppNotification> _items = const [];

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
      final response = await NotificationService.fetchNotifications();
      if (mounted) setState(() => _items = response.data?.items ?? const []);
    } catch (_) {
      if (mounted) setState(() => _error = '通知加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int index) async {
    final item = _items[index];
    if (item.isRead || item.id.isEmpty) return;
    setState(() => _items[index] = item.copyWith(isRead: true));
    try {
      await NotificationService.markAsRead(item.id);
    } catch (_) {
      if (mounted) setState(() => _items[index] = item);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await NotificationService.markAllAsRead();
      if (mounted) {
        setState(() {
          _items = _items.map((item) => item.copyWith(isRead: true)).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          TextButton(
            onPressed: _markingAll || _items.every((item) => item.isRead)
                ? null
                : _markAllRead,
            child: Text(_markingAll ? '处理中' : '全部已读'),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          Center(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('重试')),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('暂无通知')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) =>
          _NotificationTile(item: _items[index], onTap: () => _markRead(index)),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(item.type);
    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFFFF8E9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(28),
                child: Icon(_notificationIcon(item.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (item.content != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.content!,
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                    if (item.createTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(item.createTime!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF04438),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _notificationIcon(String type) => switch (type) {
  'ADOPT' => Icons.volunteer_activism_outlined,
  'BADGE' => Icons.workspace_premium_outlined,
  'LIKE' || 'COMMENT' => Icons.favorite_border,
  'ANNOUNCEMENT' => Icons.campaign_outlined,
  _ => Icons.notifications_outlined,
};

Color _notificationColor(String type) => switch (type) {
  'ADOPT' => const Color(0xFFEC4899),
  'BADGE' => const Color(0xFFF59E0B),
  'ANNOUNCEMENT' => const Color(0xFF2563EB),
  _ => const Color(0xFF14B8A6),
};

String _formatTime(String value) {
  final time = DateTime.tryParse(value)?.toLocal();
  if (time == null) return value;
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}
