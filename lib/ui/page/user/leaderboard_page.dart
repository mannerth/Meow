import 'package:flutter/material.dart';
import 'package:meow/ui/widget/image_preview.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/leaderboard.dart';
import 'package:meow/ui/page/user/cat_detail_page.dart';
import 'package:meow/ui/widget/safe_network_image.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const _types = [
    _LeaderboardType('人气榜', 'popularity', '票'),
    _LeaderboardType('颜值榜', 'appearance', '分'),
    _LeaderboardType('吃货榜', 'gluttony', '分'),
    _LeaderboardType('战斗力榜', 'fight', '分'),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<LeaderboardItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final type = _types[_currentIndex];
      final response = await CatService.fetchLeaderboard(
        type: type.value,
        limit: 20,
      );
      setState(() {
        _items = response.data?.items ?? [];
      });
    } catch (error) {
      setState(() {
        _errorMessage = '排行榜加载失败';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _loadLeaderboard();
  }

  void _openDetail(LeaderboardItem item) {
    if (item.catId.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CatDetailPage(catId: item.catId)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _types[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('全校封神榜')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _LeaderboardTabs(
            types: _types,
            currentIndex: _currentIndex,
            onChanged: _onTabChanged,
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContent(theme, type)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, _LeaderboardType type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadLeaderboard,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('暂无排行榜数据'));
    }

    final topItems = _items.take(3).toList();
    final restItems = _items.length > 3
        ? _items.sublist(3)
        : <LeaderboardItem>[];

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _TopThreeSection(
            items: topItems,
            unit: type.unit,
            onTap: _openDetail,
          ),
          const SizedBox(height: 16),
          ...restItems.map(
            (item) => _LeaderboardListItem(
              item: item,
              unit: type.unit,
              onTap: () => _openDetail(item),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardType {
  final String label;
  final String value;
  final String unit;

  const _LeaderboardType(this.label, this.value, this.unit);
}

class _LeaderboardTabs extends StatelessWidget {
  final List<_LeaderboardType> types;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _LeaderboardTabs({
    required this.types,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(types.length, (index) {
          final selected = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  types[index].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TopThreeSection extends StatelessWidget {
  final List<LeaderboardItem> items;
  final String unit;
  final ValueChanged<LeaderboardItem> onTap;

  const _TopThreeSection({
    required this.items,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final middle = items[0];
    final left = items.length > 1 ? items[1] : null;
    final right = items.length > 2 ? items[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _TopThreeAvatar(
            item: left,
            size: 64,
            rank: 2,
            badgeColor: const Color(0xFFBFC4C9),
            unit: unit,
            onTap: onTap,
          ),
        ),
        Expanded(
          child: _TopThreeAvatar(
            item: middle,
            size: 94,
            rank: 1,
            badgeColor: const Color(0xFFFFC107),
            unit: unit,
            showCrown: true,
            onTap: onTap,
          ),
        ),
        Expanded(
          child: _TopThreeAvatar(
            item: right,
            size: 64,
            rank: 3,
            badgeColor: const Color(0xFFE0A15A),
            unit: unit,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _TopThreeAvatar extends StatelessWidget {
  final LeaderboardItem? item;
  final double size;
  final int rank;
  final Color badgeColor;
  final String unit;
  final bool showCrown;
  final ValueChanged<LeaderboardItem> onTap;

  const _TopThreeAvatar({
    required this.item,
    required this.size,
    required this.rank,
    required this.badgeColor,
    required this.unit,
    required this.onTap,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap(item!),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => showNetworkImagePreview(context, item!.avatar),
                  child: ClipOval(
                    child: SafeNetworkImage(
                      url: item!.avatar,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (showCrown)
                Positioned(
                  top: -16,
                  left: size / 2 - 16,
                  child: Icon(Icons.emoji_events, color: badgeColor, size: 28),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _RankBadge(rank: rank, color: badgeColor),
          const SizedBox(height: 6),
          Text(
            item!.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatValue(item!.value)} $unit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LeaderboardListItem extends StatelessWidget {
  final LeaderboardItem item;
  final String unit;
  final VoidCallback onTap;

  const _LeaderboardListItem({
    required this.item,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.rank.toString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => showNetworkImagePreview(context, item.avatar),
              child: ClipOval(
                child: SafeNetworkImage(
                  url: item.avatar,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '常驻：${item.campus}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_formatValue(item.value)} $unit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatValue(num value) {
  if (value % 1 != 0) return value.toString();

  final integerValue = value.toInt();
  final buffer = StringBuffer();
  final chars = integerValue.toString().split('').reversed.toList();
  for (var i = 0; i < chars.length; i++) {
    if (i != 0 && i % 3 == 0) buffer.write(',');
    buffer.write(chars[i]);
  }
  return buffer.toString().split('').reversed.join();
}
