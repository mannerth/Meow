class PostPage {
  final int total;
  final int currentPage;
  final int totalPage;
  final bool hasNext;
  final List<Post> items;

  PostPage({
    required this.total,
    required this.currentPage,
    required this.totalPage,
    required this.hasNext,
    required this.items,
  });

  factory PostPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
    return PostPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      items: items,
    );
  }
}

class Post {
  final String id;
  final String content;
  final List<String> media;
  final PostUser user;
  final int likeCount;
  final bool isLiked;
  final String createTime;

  Post({
    required this.id,
    required this.content,
    required this.media,
    required this.user,
    required this.likeCount,
    required this.isLiked,
    required this.createTime,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final userJson = json['user'];
    return Post(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      media: media,
      user: PostUser.fromJson(
        userJson is Map<String, dynamic> ? userJson : const {},
      ),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createTime: (json['createTime'] ?? json['create_time'] ?? '').toString(),
    );
  }
}

class PostUser {
  final String id;
  final String name;
  final String avatar;

  PostUser({required this.id, required this.name, required this.avatar});

  factory PostUser.fromJson(Map<String, dynamic> json) => PostUser(
    id: (json['id'] ?? json['uid'] ?? '').toString(),
    name: (json['name'] ?? json['nickname'] ?? '').toString(),
    avatar: (json['avatar'] ?? '').toString(),
  );
}

class PostLikeResult {
  final bool isLiked;
  final int likeCount;

  PostLikeResult({required this.isLiked, required this.likeCount});

  factory PostLikeResult.fromJson(Map<String, dynamic> json) => PostLikeResult(
    isLiked: json['isLiked'] as bool? ?? false,
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  );
}
