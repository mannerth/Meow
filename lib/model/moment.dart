class MomentPage {
  final int total;
  final int currentPage;
  final int totalPage;
  final bool hasNext;
  final List<Moment> items;

  MomentPage({
    required this.total,
    required this.currentPage,
    required this.totalPage,
    required this.hasNext,
    required this.items,
  });

  factory MomentPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => Moment.fromJson(item as Map<String, dynamic>))
        .toList();
    return MomentPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      items: items,
    );
  }
}

class Moment {
  final String id;
  final String content;
  final List<String> media;
  final MomentUser user;
  final List<MomentRelatedCat> relatedCats;
  final int likeCount;
  final bool isLiked;
  final String createTime;

  Moment({
    required this.id,
    required this.content,
    required this.media,
    required this.user,
    required this.relatedCats,
    required this.likeCount,
    required this.isLiked,
    required this.createTime,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final related = _parseRelatedCats(json['relatedCats']);
    return Moment(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      media: media,
      user: MomentUser.fromJson(
        (json['user'] as Map<String, dynamic>? ?? const {}),
      ),
      relatedCats: related,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createTime: (json['createTime'] ?? '').toString(),
    );
  }
}

class MomentUser {
  final String id;
  final String name;
  final String avatar;

  MomentUser({required this.id, required this.name, required this.avatar});

  factory MomentUser.fromJson(Map<String, dynamic> json) => MomentUser(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        avatar: (json['avatar'] ?? '').toString(),
      );
}

class MomentRelatedCat {
  final String id;
  final String name;
  final String avatar;

  MomentRelatedCat(
      {required this.id, required this.name, required this.avatar});

  factory MomentRelatedCat.fromJson(Map<String, dynamic> json) =>
      MomentRelatedCat(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        avatar: (json['avatar'] ?? '').toString(),
      );
}

class MomentLikeResult {
  final bool isLiked;
  final int likeCount;

  MomentLikeResult({required this.isLiked, required this.likeCount});

  factory MomentLikeResult.fromJson(Map<String, dynamic> json) =>
      MomentLikeResult(
        isLiked: json['isLiked'] as bool? ?? false,
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      );
}

List<MomentRelatedCat> _parseRelatedCats(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(MomentRelatedCat.fromJson)
        .toList();
  }
  if (value is Map<String, dynamic>) {
    return [MomentRelatedCat.fromJson(value)];
  }
  return [];
}
