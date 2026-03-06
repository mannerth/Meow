import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/widget/image_preview.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/moment.dart';
import 'package:meow/util/time_tool.dart';

class CatDetailPage extends StatefulWidget {
  final String catId;

  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  late Future<CatDetail> _detailFuture;
  late Future<MomentPage> _momentFuture;
  final List<Moment> _momentItems = [];
  bool _momentLoading = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchDetail();
    _momentFuture = _fetchMoments();
  }

  Future<CatDetail> _fetchDetail() async {
    final response = await CatService.fetchCatDetail(widget.catId);
    final detail = response.data;
    if (detail == null) {
      throw Exception('未获取到猫咪详情');
    }
    return detail;
  }

  Future<MomentPage> _fetchMoments() async {
    final response = await CatService.fetchCatMoments(catId: widget.catId);
    final data = response.data;
    if (data == null) {
      throw Exception('未获取到猫咪动态');
    }
    _momentItems
      ..clear()
      ..addAll(data.items);
    return data;
  }

  Future<void> _toggleLike(Moment moment) async {
    if (_momentLoading) return;
    setState(() => _momentLoading = true);
    try {
      final response = moment.isLiked
          ? await CatService.unlikeMoment(moment.id)
          : await CatService.likeMoment(moment.id);
      final result = response.data;
      if (result == null) return;
      final index = _momentItems.indexWhere((item) => item.id == moment.id);
      if (index == -1) return;
      final updated = Moment(
        id: moment.id,
        content: moment.content,
        media: moment.media,
        user: moment.user,
        relatedCats: moment.relatedCats,
        likeCount: result.likeCount,
        isLiked: result.isLiked,
        createTime: moment.createTime,
      );
      setState(() {
        _momentItems[index] = updated;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    } finally {
      if (mounted) setState(() => _momentLoading = false);
    }
  }

  Future<void> _feedCat(WidgetRef ref) async {
    try {
      final response = await CatService.feedCat(widget.catId);
      final currency = response.data?.userCurrency ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投喂成功，剩余小鱼干 $currency')),
      );
      ref.read(authStateProvider.notifier).decrementCurrency(1);
      _detailFuture = _fetchDetail();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投喂失败，请稍后重试')),
      );
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
            return _DetailError(onRetry: () {
              setState(() {
                _detailFuture = _fetchDetail();
              });
            });
          }

          final detail = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _DetailHeader(images: detail.images, avatar: detail.avatar),
                  SliverToBoxAdapter(
                    child: _DetailInfoCard(detail: detail),
                  ),
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
                    child: _MomentSection(
                      momentFuture: _momentFuture,
                      moments: _momentItems,
                      onRetry: () {
                        _momentFuture = _fetchMoments();
                        setState(() {});
                      },
                      onLikeToggle: _toggleLike,
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 120),
                  ),
                ],
              ),
              Positioned(
                left: 20,
                bottom: 32,
                right: 20,
                child: Consumer(
                  builder:(context, ref, _){
                    return _FeedButton(onPressed: (){
                      _feedCat(ref);
                    });
                  } 
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MomentSection extends StatelessWidget {
  final Future<MomentPage> momentFuture;
  final List<Moment> moments;
  final VoidCallback onRetry;
  final ValueChanged<Moment> onLikeToggle;

  const _MomentSection({
    required this.momentFuture,
    required this.moments,
    required this.onRetry,
    required this.onLikeToggle,
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<MomentPage>(
            future: momentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _MomentSkeleton();
              }
              if (snapshot.hasError) {
                return _MomentError(onRetry: onRetry);
              }
              final page = snapshot.data;
              final items =
                  moments.isNotEmpty ? moments : (page?.items ?? <Moment>[]);
              if (items.isEmpty) {
                return const _EmptyMomentCard();
              }
              final displayItems = items.isEmpty ? [] : items;
              return Column(
                children: displayItems
                    .map(
                      (moment) => _MomentCard(
                        moment: moment,
                        onLikeToggle: () => onLikeToggle(moment),
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
                  _StatusChip(text: detail.basicInfo.status),
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
                    const Icon(Icons.warning_rounded, color: Color(0xFFE04848)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.description.isEmpty
                            ? '高能预警：吃饭时请勿摸头，会哈气！'
                            : detail.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE04848),
                        ),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
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
                                  backgroundImage: NetworkImage(relation.avatar),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                relation.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                relation.relation,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
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

class _MomentCard extends StatelessWidget {
  final Moment moment;
  final VoidCallback onLikeToggle;

  const _MomentCard({required this.moment, required this.onLikeToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = _formatMomentTime(moment.createTime);
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
                  if (moment.user.avatar.isNotEmpty) {
                    showNetworkImagePreview(context, moment.user.avatar);
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF4F5F7),
                  backgroundImage: moment.user.avatar.isEmpty
                      ? null
                      : NetworkImage(moment.user.avatar),
                  child: moment.user.avatar.isEmpty
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
                      moment.user.name.isEmpty ? '匿名用户' : moment.user.name,
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
              _MomentLikeButton(
                isLiked: moment.isLiked,
                likeCount: moment.likeCount,
                onTap: onLikeToggle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            moment.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (moment.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MomentMediaGrid(media: moment.media),
          ],
        ],
      ),
    );
  }
}

class _MomentMediaGrid extends StatelessWidget {
  final List<String> media;

  const _MomentMediaGrid({required this.media});

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

class _MomentLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const _MomentLikeButton({
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
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentSkeleton extends StatelessWidget {
  const _MomentSkeleton();

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
                      radius: 18, backgroundColor: Color(0xFFE6E7EB)),
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

class _MomentError extends StatelessWidget {
  final VoidCallback onRetry;

  const _MomentError({required this.onRetry});

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

class _EmptyMomentCard extends StatelessWidget {
  const _EmptyMomentCard();

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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

String _formatMomentTime(String source) {
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7B8593),
                  ),
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
