import 'package:flutter/material.dart';
import 'package:meow/api/service/admin_sos_service.dart';
import 'package:meow/model/admin_sos.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/widget/image_preview.dart';

class AdminSosPage extends StatefulWidget {
  const AdminSosPage({super.key});

  @override
  State<AdminSosPage> createState() => _AdminSosPageState();
}

class _AdminSosPageState extends State<AdminSosPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _replyController = TextEditingController();

  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;

  String? _selectedStatus;
  Campus? _selectedCampus;
  List<AdminSosItem> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadSosList(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    const threshold = 140.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadSosList(reset: false, loadMore: true);
    }
  }

  Future<void> _loadSosList({required bool reset, bool loadMore = false}) async {
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
      final response = await AdminSosService.fetchSosList(
        page: _page,
        size: _pageSize,
        status: _selectedStatus,
        campus: _selectedCampus,
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
    await _loadSosList(reset: true);
  }

  void _applyFilters() {
    _loadSosList(reset: true);
  }

  Future<void> _openResolveSheet(AdminSosItem item) async {
    _replyController.text = item.adminReply ?? '';
    final selected = await showModalBottomSheet<_ResolveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ResolveSheet(
        item: item,
        controller: _replyController,
      ),
    );
    if (selected == null) return;
    await _submitResolve(item, selected.status, selected.reply);
  }

  Future<void> _submitResolve(
    AdminSosItem item,
    String status,
    String reply,
  ) async {
    try {
      await AdminSosService.resolveSos(
        id: item.id,
        status: status,
        reply: reply,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('处理结果已提交')),
      );
      await _loadSosList(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交失败，请稍后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('SOS处理'),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedStatus: _selectedStatus,
            selectedCampus: _selectedCampus,
            onStatusChanged: (value) {
              setState(() => _selectedStatus = value);
              _applyFilters();
            },
            onCampusChanged: (value) {
              setState(() => _selectedCampus = value);
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
                        onRetry: () => _loadSosList(reset: false, loadMore: true),
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
          onRetry: () => _loadSosList(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }
    return SliverList.separated(
      itemBuilder: (context, index) {
        final item = _items[index];
        return _SosCard(
          item: item,
          onResolve: () => _openResolveSheet(item),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: _items.length,
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selectedStatus;
  final Campus? selectedCampus;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<Campus?> onCampusChanged;

  const _FilterBar({
    required this.selectedStatus,
    required this.selectedCampus,
    required this.onStatusChanged,
    required this.onCampusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
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
                  child: Text('待处理'),
                ),
                DropdownMenuItem<String>(
                  value: 'PROCESSING',
                  child: Text('处理中'),
                ),
                DropdownMenuItem<String>(
                  value: 'RESOLVED',
                  child: Text('已完成'),
                ),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<Campus>(
              initialValue: selectedCampus,
              decoration: InputDecoration(
                hintText: '筛选校区',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<Campus>(
                  value: null,
                  child: Text('全部校区'),
                ),
                ...Campus.values.map(
                  (campus) => DropdownMenuItem<Campus>(
                    value: campus,
                    child: Text(campus.name),
                  ),
                ),
              ],
              onChanged: onCampusChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  final AdminSosItem item;
  final VoidCallback onResolve;

  const _SosCard({required this.item, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final statusChip = _StatusChip(status: item.status);
    final campusText = item.campus?.name ??
        item.campusName ??
        (item.campusCode != null ? '校区 ${item.campusCode}' : '未知校区');
    final catText = item.catName ?? (item.catId == null ? '未识别猫咪' : '猫咪ID ${item.catId}');
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
                  catText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              statusChip,
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: '上报人', value: item.reporterName ?? '未知'),
          _InfoRow(label: '校区', value: campusText),
          if (item.location != null && item.location!.isNotEmpty)
            _InfoRow(label: '位置', value: item.location!),
          if (item.createTime != null && item.createTime!.isNotEmpty)
            _InfoRow(label: '时间', value: item.createTime!),
          if (item.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.symptoms
                  .map((label) => _TagChip(label: label))
                  .toList(),
            ),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF6B7280)),
            ),
          ],
          if (item.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ImageStrip(urls: item.imageUrls),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onResolve,
                  child: const Text('处理/回复'),
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
      case 'PROCESSING':
        return '处理中';
      case 'RESOLVED':
        return '已完成';
      default:
        return '待处理';
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PROCESSING':
        return const Color(0xFFF4A43A);
      case 'RESOLVED':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFE14B4B);
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: const Color(0xFF4B5563)),
      ),
    );
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: urls.length,
      ),
    );
  }
}


class _ResolveSheet extends StatefulWidget {
  final AdminSosItem item;
  final TextEditingController controller;

  const _ResolveSheet({
    required this.item,
    required this.controller,
  });

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  String _status = 'PROCESSING';

  @override
  void initState() {
    super.initState();
    _status = widget.item.status.isEmpty ? 'PROCESSING' : widget.item.status;
  }

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
                  '处理SOS',
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
            widget.item.catName ?? '未识别猫咪',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _SheetSectionTitle(title: '处理状态'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _StatusOption(
                label: '待处理',
                value: 'PENDING',
                selected: _status == 'PENDING',
                onTap: () => setState(() => _status = 'PENDING'),
              ),
              _StatusOption(
                label: '处理中',
                value: 'PROCESSING',
                selected: _status == 'PROCESSING',
                onTap: () => setState(() => _status = 'PROCESSING'),
              ),
              _StatusOption(
                label: '已完成',
                value: 'RESOLVED',
                selected: _status == 'RESOLVED',
                onTap: () => setState(() => _status = 'RESOLVED'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SheetSectionTitle(title: '回复说明'),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '填写给用户的回复，如处理进度、跟进措施等',
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
                final reply = widget.controller.text.trim();
                if (reply.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写回复内容')),
                  );
                  return;
                }
                Navigator.of(context).pop(
                  _ResolveResult(status: _status, reply: reply),
                );
              },
              child: const Text('提交处理结果'),
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

class _StatusOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1F8F7E) : const Color(0xFFE5E7EB);
    final textColor = selected ? Colors.white : const Color(0xFF4B5563);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ResolveResult {
  final String status;
  final String reply;

  const _ResolveResult({required this.status, required this.reply});
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
      child: const Text('暂无SOS数据'),
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
