import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/cat_detail_page.dart';
import 'package:meow/ui/page/adoption_apply_page.dart';
import 'package:meow/ui/page/leaderboard_page.dart';
import 'package:meow/ui/page/sos_page.dart';
import 'package:meow/ui/widget/cat_card.dart';
import 'package:meow/ui/widget/image_preview.dart';
import 'package:meow/ui/widget/navigate_card.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  int? _totalCount;
  int? _schoolCount;
  int? _graduatedCount;
  int? _meowStarCount;
  int? _hospitalCount;
  bool _isStatsLoading = true;
  String? _statsError;
  static const _statusOptions = [
    'SCHOOL',
    'GRADUATED',
    'MEOW_STAR',
    'HOSPITAL'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCats(reset: true);
    _loadStats();
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

  Future<void> _loadStats() async {
    setState(() {
      _isStatsLoading = true;
      _statsError = null;
    });

    try {
      final futures = await Future.wait([
        CatService.fetchCats(page: 1, pageSize: 1),
        CatService.fetchCats(
          page: 1,
          pageSize: 1,
          status: _statusOptions[0],
        ),
        CatService.fetchCats(page: 1, pageSize: 1, status: _statusOptions[1]),
        CatService.fetchCats(page: 1, pageSize: 1, status: _statusOptions[2]),
        CatService.fetchCats(page: 1, pageSize: 1, status: _statusOptions[3]),
      ]);
      final total = futures[0].data?.total ?? 0;
      final graduated = futures[2].data?.total ?? 0;
      final meowStar = futures[3].data?.total ?? 0;
      final hospital = futures[4].data?.total ?? 0;

      setState(() {
        _totalCount = total;
        _schoolCount = futures[1].data?.total ?? 0;
        _graduatedCount = graduated;
        _meowStarCount = meowStar;
        _hospitalCount = hospital;
        _statsError = null;
      });
    } catch (error) {
      setState(() {
        _statsError = '数据加载失败';
      });
    } finally {
      setState(() {
        _isStatsLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadCats(reset: true),
      _loadStats(),
    ]);
  }

  void _applyFilters() {
    _loadCats(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            return Text(ref.watch(authStateProvider).user?.campus?.name ?? '喵');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsCard(
                      isLoading: _isStatsLoading,
                      errorMessage: _statsError,
                      total: _totalCount,
                      graduate: _graduatedCount,
                      meowStar: _meowStarCount,
                      school: _schoolCount,
                      hospital: _hospitalCount,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NavigateCard(
                          title: '封神榜',
                          subtitle: '谁是校宠No.1？',
                          height: 180,
                          width: 177,
                          backgroundColor:
                              Colors.orangeAccent.withAlpha(150),
                          icon: SvgPicture.asset('assets/icons/ranking.svg'),
                          destination: const LeaderboardPage(),
                        ),
                        SizedBox(
                          width: 177,
                          child: Column(
                            children: [
                              NavigateCard(
                                title: '紧急SOS',
                                subtitle: '伤病快速上报',
                                height: 84,
                                width: 177,
                                backgroundColor:
                                    Colors.redAccent.withAlpha(178),
                                icon: const Icon(
                                  Icons.warning,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                destination: const SosPage(),
                              ),
                              const SizedBox(height: 12),
                              NavigateCard(
                                title: '申请领养',
                                subtitle: '给咪一个家',
                                height: 84,
                                width: 177,
                                backgroundColor:
                                    const Color.fromARGB(198, 255, 162, 216),
                                icon: const Icon(
                                  Icons.favorite_border,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                destination: const AdoptionApplyPage(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
            onImageLongPress: () => showNetworkImagePreview(context, cat.avatar),
            onTap: () {
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
    ..add(_FilterOption('全部校区', null));

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

class _StatsCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final int? total;
  final int? school;
  final int? graduate;
  final int? meowStar;
  final int? hospital;

  const _StatsCard({
    required this.isLoading,
    required this.errorMessage,
    required this.total,
    required this.school,
    required this.graduate,
    required this.meowStar,
    required this.hospital,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/猫猫图鉴-logo.png'), 
          fit: BoxFit.fitHeight,
          alignment: Alignment.centerRight
        ),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFBFF6E1),
            Color(0xFF7BE8F1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本校猫咪数据',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B2B),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A2B2B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (errorMessage != null)
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.redAccent,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatsItem(
                  label: '总数',
                  value: _formatCount(total, isLoading),
                ),
                _StatsItem(
                  label: '在校',
                  value: _formatCount(school, isLoading),
                ),
                _StatsItem(
                  label: '毕业',
                  value: _formatCount(graduate, isLoading),
                ),
                _StatsItem(
                  label: '猫星',
                  value: _formatCount(meowStar, isLoading),
                ),
                _StatsItem(
                  label: '住院',
                  value: _formatCount(hospital, isLoading),
                ),
              ],
            ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(140),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite,
                  size: 16,
                  color: Color(0xFF2F6F6F),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '喵喵喵～',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2F6F6F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int? value, bool isLoading) {
    if (isLoading) return '--';
    if (value == null) return '0';
    return value.toString();
  }
}

class _StatsItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatsItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D2A2A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF2F6F6F),
          ),
        ),
      ],
    );
  }
}
