import 'package:flutter/material.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/ui/page/meow_edit_page.dart';
import 'package:meow/ui/widget/cat_card.dart';
import 'package:meow/ui/widget/image_preview.dart';

class MeowPage extends StatefulWidget {
  const MeowPage({super.key});

  @override
  State<MeowPage> createState() => _MeowPageState();
}

class _MeowPageState extends State<MeowPage> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _loadMoreError;
  List<Cat> _items = [];

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
      final response = await CatService.fetchCats(
        page: _page,
        pageSize: _pageSize,
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

  Future<void> _openEditor({String? catId}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MeowEditPage(catId: catId)),
    );
    if (result == true) {
      await _loadCats(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('猫咪管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCats(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              sliver: _buildContentSliver(),
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

  Widget _buildContentSliver() {
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
            onTap: () => _openEditor(catId: cat.id),
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
