import 'package:flutter/material.dart';
import 'package:meow/api/service/adoption_service.dart';
import 'package:meow/model/adoption.dart';
import 'package:meow/ui/page/admin_adoption_detail_page.dart';
import 'package:meow/ui/widget/safe_network_image.dart';
import 'package:meow/util/time_tool.dart';

class AdminAdoptionsPage extends StatefulWidget {
  const AdminAdoptionsPage({super.key});

  @override
  State<AdminAdoptionsPage> createState() => _AdminAdoptionsPageState();
}

class _AdminAdoptionsPageState extends State<AdminAdoptionsPage> {
  final ScrollController _scrollController = ScrollController();

  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;

  String? _selectedStatus;
  List<AdminAdoptionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadAdoptions(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    const threshold = 140.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadAdoptions(reset: false, loadMore: true);
    }
  }

  Future<void> _loadAdoptions({required bool reset, bool loadMore = false}) async {
    if (reset) {
      setState(() {
        _isInitialLoading = true;
        _isLoadingMore = false;
        _errorMessage = null;
        _loadMoreError = null;
        _page = 1;
        _hasMore = true;
      });
    } else if (loadMore) {
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = null;
      });
    }

    try {
      final response = await AdoptionService.fetchAdminAdoptions(
        page: _page,
        size: _pageSize,
        status: _selectedStatus,
      );
      final pageData = response.data;
      final newItems = pageData?.items ?? [];
      final total = pageData?.total ?? 0;

      setState(() {
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _hasMore = _items.length < total;
        if (_hasMore && newItems.isNotEmpty) {
          _page += 1;
        }
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        if (reset) {
          _errorMessage = '加载失败，请稍后重试';
        } else {
          _loadMoreError = '加载失败，点击重试';
        }
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAdoptions(reset: true);
  }

  void _applyFilters() {
    _loadAdoptions(reset: true);
  }

  void _openDetail(AdminAdoptionItem item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminAdoptionDetailPage(item: item),
          ),
        )
        .then((value) {
      if (value is AdminAdoptionItem) {
        setState(() {
          final index = _items.indexWhere((element) => element.id == value.id);
          if (index != -1) _items[index] = value;
        });
      }
    });
  }

  int _countStatus(String status) {
    return _items.where((item) => item.status.toUpperCase() == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('领养申请审批'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _SearchBox(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _StatusTabs(
              selected: _selectedStatus,
              total: _items.length,
              pending: _countStatus('PENDING'),
              rejected: _countStatus('REJECTED'),
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    sliver: _buildContentSliver(),
                  ),
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(child: _LoadingMoreIndicator()),
                  if (_loadMoreError != null)
                    SliverToBoxAdapter(
                      child: _LoadMoreError(
                        message: _loadMoreError!,
                        onRetry: () =>
                            _loadAdoptions(reset: false, loadMore: true),
                      ),
                    ),
                  if (!_hasMore && _items.isNotEmpty)
                    const SliverToBoxAdapter(child: _NoMoreIndicator()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_isInitialLoading) {
      return const SliverToBoxAdapter(child: _LoadingList());
    }
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: _errorMessage!,
          onRetry: () => _loadAdoptions(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }
    return SliverList.separated(
      itemBuilder: (context, index) {
        final item = _items[index];
        return _AdoptionCard(
          item: item,
          onTap: () => _openDetail(item),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: _items.length,
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索申请单号、姓名或猫咪...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final String? selected;
  final int total;
  final int pending;
  final int rejected;
  final ValueChanged<String?> onChanged;

  const _StatusTabs({
    required this.selected,
    required this.total,
    required this.pending,
    required this.rejected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusChip(
          label: '全部申请',
          value: null,
          count: total,
          selected: selected == null,
          color: const Color(0xFF6CC070),
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 10),
        _StatusChip(
          label: '待初审',
          value: 'PENDING',
          count: pending,
          selected: selected == 'PENDING',
          color: const Color(0xFFF4A43A),
          onTap: () => onChanged('PENDING'),
        ),
        const SizedBox(width: 10),
        _StatusChip(
          label: '已拒绝',
          value: 'REJECTED',
          count: rejected,
          selected: selected == 'REJECTED',
          color: const Color(0xFFE77373),
          onTap: () => onChanged('REJECTED'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String? value;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white70 : const Color(0xFF7A7A7A),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdoptionCard extends StatelessWidget {
  final AdminAdoptionItem item;
  final VoidCallback onTap;

  const _AdoptionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(item.createTime);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  item.userName.isNotEmpty ? item.userName[0] : '？',
                ),
              ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.userName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusLabel(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            _CatInfoRow(item: item),
            if (timeText != null) ...[
              const SizedBox(height: 8),
              Text(
                timeText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF9CA3AF)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return TimeTool.getExpressionTimeString(parsed);
  }
}

class _CatInfoRow extends StatelessWidget {
  final AdminAdoptionItem item;

  const _CatInfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SafeNetworkImage(
            url: item.catAvatar,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(10),
            placeholder: Container(
              width: 48,
              height: 48,
              color: const Color(0xFFE5E7EB),
              alignment: Alignment.center,
              child: const Icon(Icons.pets, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.catName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.userCampus ?? '校区未知',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.contact?.phone != null)
            Text(
              item.contact!.phone,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _labelForStatus(status);
    final color = _colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _labelForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'INTERVIEW':
        return '面试中';
      case 'APPROVED':
        return '已通过';
      case 'REJECTED':
        return '已拒绝';
      case 'COMPLETED':
        return '已完成';
      default:
        return '待初审';
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'INTERVIEW':
        return const Color(0xFFF4A43A);
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return const Color(0xFFE57373);
      case 'COMPLETED':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFF4A43A);
    }
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Text('暂无领养申请'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadMoreError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton(onPressed: onRetry, child: Text(message)),
      ),
    );
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NoMoreIndicator extends StatelessWidget {
  const _NoMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text('没有更多了', style: TextStyle(color: Color(0xFF9CA3AF))),
      ),
    );
  }
}
