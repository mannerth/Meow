import 'package:flutter/material.dart';
import 'package:meow/api/service/admin_new_cat_service.dart';
import 'package:meow/model/admin_new_cat.dart';
import 'package:meow/ui/widget/image_preview.dart';

class AdminNewCatPage extends StatefulWidget {
  const AdminNewCatPage({super.key});

  @override
  State<AdminNewCatPage> createState() => _AdminNewCatPageState();
}

class _AdminNewCatPageState extends State<AdminNewCatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();

  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;

  String? _selectedStatus;
  List<AdminNewCatItem> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadNewCats(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    const threshold = 140.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadNewCats(reset: false, loadMore: true);
    }
  }

  Future<void> _loadNewCats({required bool reset, bool loadMore = false}) async {
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
      final response = await AdminNewCatService.fetchNewCats(
        page: _page,
        pageSize: _pageSize,
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
    await _loadNewCats(reset: true);
  }

  void _applyFilters() {
    _loadNewCats(reset: true);
  }

  Future<void> _openApproveSheet(AdminNewCatItem item) async {
    final presetName = item.tempName ?? '';
    _nameController.text = presetName;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ApproveSheet(
        item: item,
        controller: _nameController,
      ),
    );
    if (selected == null) return;
    await _submitApprove(item, selected);
  }

  Future<void> _submitApprove(AdminNewCatItem item, String officialName) async {
    try {
      await AdminNewCatService.approveNewCat(
        id: item.id,
        officialName: officialName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已转正并创建档案')),
      );
      await _loadNewCats(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('转正失败，请稍后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('待审核 - 新猫线索'),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedStatus: _selectedStatus,
            onStatusChanged: (value) {
              setState(() => _selectedStatus = value);
              _applyFilters();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: _buildContentSliver(),
                  ),
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(child: _LoadingMoreIndicator()),
                  if (_loadMoreError != null)
                    SliverToBoxAdapter(
                      child: _LoadMoreError(
                        message: _loadMoreError!,
                        onRetry: () =>
                            _loadNewCats(reset: false, loadMore: true),
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
          onRetry: () => _loadNewCats(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }
    return SliverList.separated(
      itemBuilder: (context, index) {
        final item = _items[index];
        return _NewCatCard(
          item: item,
          onApprove: () => _openApproveSheet(item),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _items.length,
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const _FilterBar({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        initialValue: selectedStatus,
        decoration: InputDecoration(
          hintText: '筛选状态',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem<String>(
            value: null,
            child: Text('全部状态'),
          ),
          DropdownMenuItem<String>(
            value: 'PENDING',
            child: Text('待审核'),
          ),
          DropdownMenuItem<String>(
            value: 'APPROVED',
            child: Text('已转正'),
          ),
          DropdownMenuItem<String>(
            value: 'REJECTED',
            child: Text('已驳回'),
          ),
        ],
        onChanged: onStatusChanged,
      ),
    );
  }
}

class _NewCatCard extends StatelessWidget {
  final AdminNewCatItem item;
  final VoidCallback onApprove;

  const _NewCatCard({required this.item, required this.onApprove});

  bool get _isPending => item.status.toUpperCase() == 'PENDING';

  @override
  Widget build(BuildContext context) {
    final campusText = item.campus?.name ??
        item.campusName ??
        (item.campusCode != null ? '校区 ${item.campusCode}' : '未知校区');
    final title = item.tempName?.isNotEmpty == true
        ? item.tempName!
        : '未命名新猫';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
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
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: '提交人', value: item.submitterName ?? '未知'),
          _InfoRow(label: '校区', value: campusText),
          if (item.color != null && item.color!.isNotEmpty)
            _InfoRow(label: '花色', value: item.color!),
          if (item.location != null && item.location!.isNotEmpty)
            _InfoRow(label: '位置', value: item.location!),
          if (item.createTime != null && item.createTime!.isNotEmpty)
            _InfoRow(label: '时间', value: item.createTime!),
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ImageStrip(urls: item.images),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _isPending ? onApprove : null,
                  child: Text(_isPending ? '转正建档' : '已处理'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _labelForStatus(status);
    final color = _colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _labelForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return '已转正';
      case 'REJECTED':
        return '已驳回';
      default:
        return '待审核';
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF43A047);
      case 'REJECTED':
        return const Color(0xFFE14B4B);
      default:
        return const Color(0xFFF4A43A);
    }
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> urls;

  const _ImageStrip({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final url = urls[index];
          return GestureDetector(
            onTap: () => showNetworkImagePreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE6E7EB),
                    alignment: Alignment.center,
                    child: const Icon(Icons.pets, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: urls.length,
      ),
    );
  }
}

class _ApproveSheet extends StatefulWidget {
  final AdminNewCatItem item;
  final TextEditingController controller;

  const _ApproveSheet({
    required this.item,
    required this.controller,
  });

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '转正建档',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.tempName?.isNotEmpty == true
                ? '临时名：${widget.item.tempName}'
                : '临时名：未命名',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _SheetSectionTitle(title: '正式名称'),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: '输入正式猫咪名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final name = widget.controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写正式名称')),
                  );
                  return;
                }
                Navigator.of(context).pop(name);
              },
              child: const Text('确认转正'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String title;

  const _SheetSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
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
          height: 140,
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
      child: const Text('暂无新猫线索'),
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
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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

class _NoMoreIndicator extends StatelessWidget {
  const _NoMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '没有更多了',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ),
    );
  }
}
