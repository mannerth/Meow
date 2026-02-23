import 'package:flutter/material.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat_detail.dart';

class CatDetailPage extends StatefulWidget {
  final String catId;

  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  late Future<CatDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchDetail();
  }

  Future<CatDetail> _fetchDetail() async {
    final response = await CatService.fetchCatDetail(widget.catId);
    final detail = response.data;
    if (detail == null) {
      throw Exception('未获取到猫咪详情');
    }
    return detail;
  }

  Future<void> _feedCat() async {
    try {
      final response = await CatService.feedCat(widget.catId);
      final currency = response.data?.userCurrency ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投喂成功，剩余小鱼干 $currency')),
      );
      setState(() {
        _detailFuture = _fetchDetail();
      });
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
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 120),
                  ),
                ],
              ),
              Positioned(
                left: 20,
                bottom: 32,
                right: 20,
                child: _FeedButton(onPressed: _feedCat),
              ),
            ],
          );
        },
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
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
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
            return Image.network(
              items[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE6E7EB),
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, size: 48, color: Colors.grey),
                );
              },
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
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(relation.avatar),
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
