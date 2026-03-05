import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/service/admin_dashboard_service.dart';
import 'package:meow/model/admin_dashboard_stats.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/admin_adoptions_page.dart';
import 'package:meow/ui/page/admin_new_cat_page.dart';
import 'package:meow/ui/page/admin_sos_page.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_provider.dart';
import 'package:meow/ui/widget/image_preview.dart';

class StaticPage extends ConsumerStatefulWidget {
  const StaticPage({super.key});

  @override
  ConsumerState<StaticPage> createState() => _StaticPageState();
}

class _StaticPageState extends ConsumerState<StaticPage> {
  bool _loading = true;
  String? _errorMessage;
  AdminDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final response = await AdminDashboardService.fetchStats();
      setState(() {
        _stats = response.data;
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingText();
    final dateText = _formatDate(DateTime.now());
    final stats = _stats;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          children: [
            _HeaderCard(
              greeting: greeting,
              dateText: dateText,
              avatarUrl: ref.watch(authStateProvider).user?.avatar,
            ),
            _StatsGrid(
              isLoading: _loading,
              errorMessage: _errorMessage,
              stats: stats,
              onSosTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminSosPage()),
                );
              },
              onPendingTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminNewCatPage()),
                );
              },
              onAdoptionTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminAdoptionsPage()),
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: '官方公告管理'),
            const SizedBox(height: 12),
            const _ActionTile(
              iconBackground: Color(0xFFEFF2FF),
              icon: Icons.campaign_outlined,
              title: '发布新公告',
              subtitle: '向全校用户推送最新通知或招募信息',
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: '科普文章管理'),
            const SizedBox(height: 12),
            const _ActionTile(
              iconBackground: Color(0xFFE9FAF2),
              icon: Icons.menu_book_outlined,
              title: '发布科普文章',
              subtitle: '分享养猫知识和猫咪健康护理指南',
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: '猫咪分布概览'),
            const SizedBox(height: 12),
            _CampusDistributionCard(
              isLoading: _loading,
              stats: stats,
              errorMessage: _errorMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '凌晨好，管理员';
    if (hour < 12) return '早上好，管理员';
    if (hour < 18) return '下午好，管理员';
    return '晚上好，管理员';
  }

  String _formatDate(DateTime date) {
    const weekMap = {
      1: '周一',
      2: '周二',
      3: '周三',
      4: '周四',
      5: '周五',
      6: '周六',
      7: '周日',
    };
    return '今天是 ${date.month}月${date.day}日${weekMap[date.weekday] ?? ''}';
  }
}

class _HeaderCard extends StatelessWidget {
  final String greeting;
  final String dateText;
  final String? avatarUrl;

  const _HeaderCard({
    required this.greeting,
    required this.dateText,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2A37),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: avatarUrl == null || avatarUrl!.isEmpty
                ? null
                : () => showNetworkImagePreview(context, avatarUrl!),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                  ? null
                  : NetworkImage(avatarUrl!),
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF9CA3AF))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}


class _StatsGrid extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final AdminDashboardStats? stats;
  final VoidCallback onSosTap;
  final VoidCallback onPendingTap;
  final VoidCallback onAdoptionTap;

  const _StatsGrid({
    required this.isLoading,
    required this.errorMessage,
    required this.stats,
    required this.onSosTap,
    required this.onPendingTap,
    required this.onAdoptionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && stats == null) {
      return _ErrorCard(message: errorMessage!);
    }
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: Icons.warning_amber_rounded,
          iconBackground: const Color(0xFFFFE6E6),
          iconColor: const Color(0xFFF04F4F),
          value: _formatValue(isLoading, stats?.pendingSos),
          label: 'SOS待处理',
          footnote: '--',
          footnoteColor: const Color(0xFFF04F4F),
          onTap: onSosTap,
        ),
        _StatCard(
          icon: Icons.how_to_reg_outlined,
          iconBackground: const Color(0xFFFFF0DA),
          iconColor: const Color(0xFFF4A43A),
          value: _formatValue(isLoading, stats?.pendingNewCatClues),
          label: '新猫线索待处理',
          footnote: '--',
          footnoteColor: const Color(0xFF43A047),
          onTap: onPendingTap,
        ),
        _StatCard(
          icon: Icons.home_outlined,
          iconBackground: const Color(0xFFD6F4EF),
          iconColor: const Color(0xFF1F8F7E),
          value: _formatValue(isLoading, stats?.adoptApplications),
          label: '领养申请',
          footnote: '--',
          footnoteColor: const Color(0xFF6B7280),
          highlight: true,
          onTap: onAdoptionTap,
        ),
        Consumer(
          builder: (context, ref, child) {
            return _StatCard(
              icon: Icons.pets_outlined,
              iconBackground: const Color(0xFFE8F7EB),
              iconColor: const Color(0xFF43A047),
              value: _formatValue(isLoading, stats?.totalCats),
              label: '猫咪总数',
              footnote: '--',
              footnoteColor: const Color(0xFF43A047),
              onTap: (){ 
                ref.read(navigationProvider.notifier).setCurrentIndex(1, controlJump: true);
              },
            );
          },
        )
      ],
    );
  }

  String _formatValue(bool isLoading, int? value) {
    if (isLoading) return '--';
    return (value ?? 0).toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;
  final String footnote;
  final Color footnoteColor;
  final bool highlight;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.footnote,
    required this.footnoteColor,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? const Color(0xFFE4F7F5) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2A37),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                footnote,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: footnoteColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionTile({
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1F2A37)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _CampusDistributionCard extends StatelessWidget {
  final bool isLoading;
  final AdminDashboardStats? stats;
  final String? errorMessage;

  const _CampusDistributionCard({
    required this.isLoading,
    required this.stats,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null && stats == null) {
      return _ErrorCard(message: errorMessage!);
    }
    final items = _buildDistributionItems();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DistributionRow(item: item),
              ),
            )
            .toList(),
      ),
    );
  }

  List<_DistributionItem> _buildDistributionItems() {
    final data = stats?.campusDistribution ?? const [];
    if (data.isEmpty) {
      return const [
        _DistributionItem(
          name: '暂无数据',
          count: 0,
          percentage: 0,
          color: Color(0xFFCBD5F5),
        ),
      ];
    }
    final colors = [
      const Color(0xFF5CC0A6),
      const Color(0xFFF5C04E),
      const Color(0xFF3D4B5A),
    ];
    return List.generate(data.length, (index) {
      final item = data[index];
      final name = _campusLabel(item);
      return _DistributionItem(
        name: name,
        count: item.count,
        percentage: item.percentage,
        color: colors[index % colors.length],
      );
    });
  }

  String _campusLabel(CampusDistribution item) {
    final campus = item.campus;
    if (campus != null) return campus.name;
    if (item.campusKey != null && item.campusKey!.isNotEmpty) {
      return _campusKeyToLabel(item.campusKey!);
    }
    if (item.campusCode != null) return '校区 ${item.campusCode}';
    return '未知校区';
  }

  String _campusKeyToLabel(String key) {
    switch (key) {
      case 'SOFTWARE_PARK':
        return '软件园校区';
      case 'CENTRAL':
        return '中心校区';
      case 'BAOTUQUAN':
        return '趵突泉校区';
      case 'HONGJIALOU':
        return '洪家楼校区';
      case 'QIANFOSHAN':
        return '千佛山校区';
      case 'XINGLONGSHAN':
        return '兴隆山校区';
      case 'QINGDAO':
        return '青岛校区';
      case 'WEIHAI':
        return '威海校区';
      default:
        return key;
    }
  }
}

class _DistributionItem {
  final String name;
  final int count;
  final double percentage;
  final Color color;

  const _DistributionItem({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class _DistributionRow extends StatelessWidget {
  final _DistributionItem item;

  const _DistributionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final percentageLabel = '${(item.percentage * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
            Text(
              '${item.count}只 ($percentageLabel)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2A37),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: item.percentage.clamp(0, 1),
            minHeight: 6,
            backgroundColor: const Color(0xFFF0F2F5),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE14B4B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFFE14B4B)),
            ),
          ),
        ],
      ),
    );
  }
}
