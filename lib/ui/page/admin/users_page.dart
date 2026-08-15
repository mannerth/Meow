import 'package:flutter/material.dart';
import 'package:meow/api/service/admin_user_service.dart';
import 'package:meow/model/admin_user.dart';
import 'package:meow/model/static_type.dart';
import 'package:meow/model/user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;
  List<AdminUserListItem> _items = [];
  Campus? _selectedCampus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadUsers(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    const threshold = 120.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadUsers(reset: false, loadMore: true);
    }
  }

  Future<void> _loadUsers({required bool reset, bool loadMore = false}) async {
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
      final response = await AdminUserService.fetchUsers(
        page: _page,
        size: _pageSize,
        campus: _selectedCampus,
        search: _searchController.text.trim(),
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
      if (mounted)
        setState(() {
          if (reset) {
            _errorMessage = '加载失败，请稍后重试';
          } else {
            _loadMoreError = '加载失败，点击重试';
          }
        });
    } finally {
      if (mounted)
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
    }
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    _loadUsers(reset: true);
  }

  Future<void> _openUserDetail(AdminUserListItem item) async {
    final detail = await _loadUserDetail(item.id);
    if (!mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _UserDetailSheet(detail: detail, onToggleBan: () => _toggleBan(item)),
    );
  }

  Future<AdminUserDetail?> _loadUserDetail(String id) async {
    try {
      final response = await AdminUserService.fetchUserDetail(id);
      return response.data;
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('获取用户详情失败')));
      return null;
    }
  }

  Future<void> _toggleBan(AdminUserListItem item) async {
    try {
      await AdminUserService.toggleBan(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name.isEmpty ? '用户' : item.name} 状态已更新'),
        ),
      );
      await _loadUsers(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户管理')),
      body: Column(
        children: [
          _FilterBar(
            controller: _searchController,
            selectedCampus: _selectedCampus,
            onCampusChanged: (value) {
              setState(() => _selectedCampus = value);
              _loadUsers(reset: true);
            },
            onSearch: _onSearch,
            onClear: () {
              _searchController.clear();
              _loadUsers(reset: true);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadUsers(reset: true),
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
                        onRetry: () => _loadUsers(reset: false, loadMore: true),
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
          onRetry: () => _loadUsers(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }

    return SliverList.separated(
      itemBuilder: (context, index) {
        final user = _items[index];
        return _UserCard(
          user: user,
          onTap: () => _openUserDetail(user),
          onToggleBan: () => _toggleBan(user),
        );
      },
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemCount: _items.length,
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final Campus? selectedCampus;
  final ValueChanged<Campus?> onCampusChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _FilterBar({
    required this.controller,
    required this.selectedCampus,
    required this.onCampusChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索邮箱/昵称/UID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Campus>(
                  initialValue: selectedCampus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: '筛选校区',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.tune),
                label: const Text('筛选'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserListItem user;
  final VoidCallback onTap;
  final VoidCallback onToggleBan;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onToggleBan,
  });

  bool get _isBanned => user.status == UserBanStatus.banned;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? '未知用户' : user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('UID: ${user.id}'),
                    ],
                  ),
                ),
                _StatusChip(isBanned: _isBanned),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('查看详情'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onToggleBan,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isBanned
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                    child: Text(_isBanned ? '解除封禁' : '封禁用户'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isBanned;

  const _StatusChip({required this.isBanned});

  @override
  Widget build(BuildContext context) {
    final background = isBanned
        ? const Color(0xFFFFE5E5)
        : const Color(0xFFE8F5E9);
    final color = isBanned ? Colors.redAccent : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isBanned ? '已封禁' : '正常',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final AdminUserDetail detail;
  final VoidCallback onToggleBan;

  const _UserDetailSheet({required this.detail, required this.onToggleBan});

  @override
  Widget build(BuildContext context) {
    final campusText =
        detail.campus?.name ??
        (detail.campusCode != null ? '校区编号 ${detail.campusCode}' : '未设置');
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.nickname ?? detail.name ?? '用户详情',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: '用户ID', value: detail.id),
          _DetailRow(label: '学号/工号', value: detail.studentId ?? '未设置'),
          _DetailRow(label: '角色', value: detail.role ?? '未知'),
          _DetailRow(label: '校区', value: campusText),
          _DetailRow(label: '等级', value: detail.level?.toString() ?? '未知'),
          _DetailRow(label: '动态数', value: detail.stats.momentCount.toString()),
          _DetailRow(label: '投喂数', value: detail.stats.feedCount.toString()),
          _DetailRow(label: '发现新猫', value: detail.stats.foundCount.toString()),
          _DetailRow(label: '获赞', value: detail.stats.receivedLikes.toString()),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onToggleBan,
              icon: const Icon(Icons.block),
              label: const Text('切换封禁状态'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
          height: 96,
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
      child: const Text('暂无用户数据'),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
