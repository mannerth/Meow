import 'package:flutter/material.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/page/cat_detail_page.dart';
import 'package:meow/ui/widget/cat_card.dart';

class CatSelectPage extends StatefulWidget {
  final bool selectable;

  const CatSelectPage({super.key, this.selectable = false});

  @override
  State<CatSelectPage> createState() => _CatSelectPageState();
}

class _CatSelectPageState extends State<CatSelectPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;

  List<Cat> _items = [];

  String? _selectedCampus;
  String? _selectedStatus;
  String? _selectedColor;
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCats(reset: true);
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
    final threshold = 120.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadCats(reset: false, loadMore: true);
    }
  }

  Future<void> _loadCats({required bool reset, bool loadMore = false}) async {
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
      final searchText = _searchController.text.trim();
      final response = await CatService.fetchCats(
        page: _page,
        pageSize: _pageSize,
        campus: _selectedCampus,
        status: _selectedStatus,
        color: _selectedColor,
        search: searchText.isEmpty ? null : searchText,
        sort: _selectedSort,
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
    await _loadCats(reset: true);
  }

  void _applyFilters() {
    _loadCats(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              title: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterSearchBox(
                          controller: _searchController,
                          onSearch: _applyFilters,
                        ),
                        const SizedBox(width: 8),
                        _FilterDropdown(
                          hint: '校区',
                          value: _selectedCampus,
                          options: _FilterOptions.campus,
                          onChanged: (value) {
                            setState(() => _selectedCampus = value);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterDropdown(
                          hint: '状态',
                          value: _selectedStatus,
                          options: _FilterOptions.status,
                          onChanged: (value) {
                            setState(() => _selectedStatus = value);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterDropdown(
                          hint: '花色',
                          value: _selectedColor,
                          options: _FilterOptions.color,
                          onChanged: (value) {
                            setState(() => _selectedColor = value);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterDropdown(
                          hint: '排序',
                          value: _selectedSort,
                          options: _FilterOptions.sort,
                          onChanged: (value) {
                            setState(() => _selectedSort = value);
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              sliver: _buildContentSliver(theme),
            ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(child: _LoadingMoreIndicator()),
            if (_loadMoreError != null)
              SliverToBoxAdapter(
                child: _LoadMoreError(
                  message: _loadMoreError!,
                  onRetry: () => _loadCats(reset: false, loadMore: true),
                ),
              ),
            if (!_hasMore && _items.isNotEmpty)
              const SliverToBoxAdapter(child: _NoMoreIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(ThemeData theme) {
    if (_isInitialLoading) {
      return const _LoadingGridSliver();
    }
    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: _errorMessage!,
          onRetry: () => _loadCats(reset: true),
        ),
      );
    }
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cat = _items[index];
          return CatCard(
            cat: cat,
            onTap: () {
              if (widget.selectable) {
                Navigator.of(context).pop(cat.id);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CatDetailPage(catId: cat.id),
                ),
              );
            },
          );
        },
        childCount: _items.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
    );
  }
}

class _FilterSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _FilterSearchBox({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 36,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: '搜索',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<_FilterOption> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      height: 36,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
        iconSize: 18,
        style: theme.textTheme.labelMedium,
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String? value;

  const _FilterOption(this.label, this.value);
}

class _FilterOptions {
  static final campus = Campus.values
      .map((c) => _FilterOption(c.name, c.code.toString()))
      .toList()
    ..add(const _FilterOption('全部校区', null));

  static const status = [
    _FilterOption('全部状态', null),
    _FilterOption('在校', 'SCHOOL'),
    _FilterOption('毕业', 'GRADUATED'),
    _FilterOption('喵星', 'MEOW_STAR'),
    _FilterOption('住院', 'HOSPITAL'),
  ];

  static const color = [
    _FilterOption('全部花色', null),
    _FilterOption('橘猫', 'ORANGE'),
    _FilterOption('狸花', 'TABBY'),
    _FilterOption('奶牛', 'COW'),
    _FilterOption('三花', 'CALICO'),
    _FilterOption('玳瑁', 'TORTIE'),
    _FilterOption('纯白', 'WHITE'),
    _FilterOption('纯黑', 'BLACK'),
    _FilterOption('其他', 'OTHER'),
  ];

  static const sort = [
    _FilterOption('默认排序', null),
    _FilterOption('人气最高', 'popularity'),
    _FilterOption('最新发现', 'createTime'),
    _FilterOption('最近出现', 'lastSeenTime'),
  ];
}

class _LoadingGridSliver extends StatelessWidget {
  const _LoadingGridSliver();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        childCount: 6,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
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
      child: const Text('暂无猫咪数据'),
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
