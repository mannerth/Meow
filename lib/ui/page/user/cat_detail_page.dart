import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/widget/image_preview.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/post.dart';
import 'package:meow/util/time_tool.dart';

class CatDetailPage extends StatefulWidget {
  final String catId;

  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  late Future<CatDetail> _detailFuture;
  late Future<PostPage> _postFuture;
  final List<Post> _postItems = [];
  bool _postLoading = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchDetail();
    _postFuture = _fetchPosts();
  }

  Future<CatDetail> _fetchDetail() async {
    final response = await CatService.fetchCatDetail(widget.catId);
    final detail = response.data;
    if (detail == null) {
      throw Exception('未获取到猫咪详情');
    }
    return detail;
  }

  Future<PostPage> _fetchPosts() async {
    final response = await CatService.fetchCatPosts(catId: widget.catId);
    final data = response.data;
    if (data == null) {
      throw Exception('未获取到猫咪动态');
    }
    _postItems
      ..clear()
      ..addAll(data.items);
    return data;
  }

  Future<void> _toggleLike(Post post) async {
    if (_postLoading) return;
    setState(() => _postLoading = true);
    try {
      final response = post.isLiked
          ? await CatService.unlikePost(post.id)
          : await CatService.likePost(post.id);
      final result = response.data;
      if (result == null) return;
      final index = _postItems.indexWhere((item) => item.id == post.id);
      if (index == -1) return;
      final updated = Post(
        id: post.id,
        content: post.content,
        media: post.media,
        user: post.user,
        likeCount: post.likeCount+ (post.isLiked? -1: 1), //乐观更新 
        isLiked: result.isLiked,
        createTime: post.createTime,
      );
      setState(() {
        _postItems[index] = updated;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _postLoading = false);
    }
  }

  Future<void> _deletePost(Post post) async {
    if (_postLoading) return;
    final confirmed = await _showConfirmDialog(
      context,
      title: '删除动态',
      message: '确认删除这条动态吗？删除后不可恢复。',
    );
    if (confirmed != true) return;
    setState(() => _postLoading = true);
    try {
      await CatService.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _postItems.removeWhere((item) => item.id == post.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已删除动态')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _postLoading = false);
    }
  }

  Future<void> _feedCat(WidgetRef ref) async {
    try {
      final response = await CatService.feedCat(widget.catId);
      final currency = response.data?.userCurrency ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('投喂成功，剩余小鱼干 $currency')));
      ref.read(authStateProvider.notifier).decrementCurrency(1);
      _detailFuture = _fetchDetail();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投喂失败，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: FutureBuilder<CatDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailError(
              onRetry: () {
                setState(() {
                  _detailFuture = _fetchDetail();
                });
              },
            );
          }

          final detail = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _DetailHeader(images: detail.images, avatar: detail.avatar),
                  SliverToBoxAdapter(child: _DetailInfoCard(detail: detail)),
                  SliverToBoxAdapter(
                    child: _RelationSection(
                      relations: detail.relationship,
                      onTap: (id) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CatDetailPage(catId: id),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PostSection(
                      postFuture: _postFuture,
                      posts: _postItems,
                      onRetry: () {
                        _postFuture = _fetchPosts();
                        setState(() {});
                      },
                      onLikeToggle: _toggleLike,
                      onDelete: _deletePost,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
              Positioned(
                left: 20,
                bottom: 32,
                right: 20,
                child: Consumer(
                  builder: (context, ref, _) {
                    return _FeedButton(
                      onPressed: () {
                        _feedCat(ref);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostSection extends StatelessWidget {
  final Future<PostPage> postFuture;
  final List<Post> posts;
  final VoidCallback onRetry;
  final ValueChanged<Post> onLikeToggle;
  final ValueChanged<Post> onDelete;

  const _PostSection({
    required this.postFuture,
    required this.posts,
    required this.onRetry,
    required this.onLikeToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '喵喵动态',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<PostPage>(
            future: postFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _PostSkeleton();
              }
              if (snapshot.hasError) {
                return _PostError(onRetry: onRetry);
              }
              final page = snapshot.data;
              final items = posts.isNotEmpty
                  ? posts
                  : (page?.items ?? <Post>[]);
              if (items.isEmpty) {
                return const _EmptyPostCard();
              }
              final displayItems = items.isEmpty ? [] : items;
              return Column(
                children: displayItems
                    .map(
                      (post) => _PostCard(
                        post: post,
                        onLikeToggle: () => onLikeToggle(post),
                        onDelete: () => onDelete(post),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final List<String> images;
  final String avatar;

  const _DetailHeader({required this.images, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final items = images.isNotEmpty ? images : [avatar];
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: CircleAvatar(
          backgroundColor: Colors.white.withAlpha(217),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final imageUrl = items[index];
            return GestureDetector(
              onTap: () => showNetworkImagePreview(context, imageUrl),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE6E7EB),
                    alignment: Alignment.center,
                    child: const Icon(Icons.pets, size: 48, color: Colors.grey),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  final CatDetail detail;

  const _DetailInfoCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(text: catStatusLabel(detail.basicInfo.status)),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFFF4E0),
                    child: Icon(Icons.pets, color: Color(0xFFF4B24D)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                detail.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.cut, size: 16, color: Color(0xFF7B8593)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail.basicInfo.neutered.isNeutered
                          ? '${detail.basicInfo.neutered.neuteredDate} 已绝育'
                          : '未绝育',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B8593),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.school,
                      title: '学历/编制',
                      value: detail.basicInfo.role,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.place,
                      title: '常驻据点',
                      value: detail.basicInfo.hauntLocation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('猫格属性', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _AttributeRow(
                label: '亲人指数',
                value: detail.attributes.friendliness,
                color: const Color(0xFFFF8A7A),
              ),
              _AttributeRow(
                label: '贪吃指数',
                value: detail.attributes.gluttony,
                color: const Color(0xFFF6C14D),
              ),
              _AttributeRow(
                label: '战斗力',
                value: detail.attributes.fight,
                color: const Color(0xFF6FA8FF),
              ),
              _AttributeRow(
                label: '颜值',
                value: detail.attributes.appearance,
                color: const Color(0xFFFF8888),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.description.isEmpty
                            ? '高能预警：吃饭时请勿摸头，会哈气！'
                            : detail.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationSection extends StatelessWidget {
  final List<CatRelation> relations;
  final ValueChanged<String> onTap;

  const _RelationSection({required this.relations, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (relations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '喵际关系',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: relations
                    .map(
                      (relation) => GestureDetector(
                        onTap: () => onTap(relation.catId),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => showNetworkImagePreview(
                                  context,
                                  relation.avatar,
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                    relation.avatar,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                relation.name,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                relation.relation,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLikeToggle;
  final VoidCallback? onDelete;

  const _PostCard({
    required this.post,
    required this.onLikeToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = _formatPostTime(post.createTime);
    final isAdmin = _isAdmin(context);
    final canDelete = isAdmin || _isOwner(context, post);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (post.user.avatar.isNotEmpty) {
                    showNetworkImagePreview(context, post.user.avatar);
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF4F5F7),
                  backgroundImage: post.user.avatar.isEmpty
                      ? null
                      : NetworkImage(post.user.avatar),
                  child: post.user.avatar.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFFB0B4BA))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.name.isEmpty ? '匿名用户' : post.user.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B8593),
                      ),
                    ),
                  ],
                ),
              ),
              _PostLikeButton(
                isLiked: post.isLiked,
                likeCount: post.likeCount,
                onTap: onLikeToggle,
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE14B4B),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PostMediaGrid(media: post.media),
          ],
        ],
      ),
    );
  }
}

class _PostMediaGrid extends StatelessWidget {
  final List<String> media;

  const _PostMediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    final items = media.take(3).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final imageUrl = items[index];
            return GestureDetector(
              onTap: () => showNetworkImagePreview(context, imageUrl),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE6E7EB),
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const _PostLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLiked ? const Color(0xFFF26464) : const Color(0xFF7B8593);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              likeCount.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE6E7EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 120,
                          color: const Color(0xFFE6E7EB),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 80,
                          color: const Color(0xFFE6E7EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 12, color: const Color(0xFFE6E7EB)),
              const SizedBox(height: 6),
              Container(height: 12, width: 160, color: const Color(0xFFE6E7EB)),
              const SizedBox(height: 12),
              Container(height: 140, color: const Color(0xFFE6E7EB)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PostError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('动态加载失败，请稍后重试'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _EmptyPostCard extends StatelessWidget {
  const _EmptyPostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.pets, color: Color(0xFFB0B4BA)),
          const SizedBox(height: 6),
          Text(
            '还没有动态，快来发布第一条吧',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

String _formatPostTime(String source) {
  if (source.isEmpty) return '';
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source;
  return TimeTool.getExpressionTimeString(parsed);
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text.isEmpty ? '在校' : text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF24A15B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7B8593)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF7B8593),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '--' : value,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AttributeRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value.clamp(0, 10)) / 10;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: normalized,
                minHeight: 8,
                backgroundColor: const Color(0xFFF2F2F2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7B8593)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FeedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: const Color(0xFFFFD451),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.set_meal, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                '投喂',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('加载失败，请稍后重试'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

bool _isAdmin(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final role = container.read(authStateProvider).role;
  return role == RoleType.admin;
}

bool _isOwner(BuildContext context, Post post) {
  final container = ProviderScope.containerOf(context, listen: false);
  final user = container.read(authStateProvider).user;
  final userId = user?.id.toString() ?? '';
  return userId.isNotEmpty && userId == post.user.id;
}

Future<bool?> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
