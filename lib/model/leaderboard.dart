class LeaderboardItem {
  final int rank;
  final String catId;
  final String name;
  final String avatar;
  final String campus;
  final int value;
  final List<String> tags;

  LeaderboardItem({
    required this.rank,
    required this.catId,
    required this.name,
    required this.avatar,
    required this.campus,
    required this.value,
    required this.tags,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      catId: json['catId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      campus: json['campus'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class LeaderboardResponse {
  final List<LeaderboardItem> items;

  LeaderboardResponse({required this.items});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
