import 'package:meow/model/campus.dart';

class LeaderboardItem {
  final int rank;
  final String catId;
  final String name;
  final String avatar;
  final String campus;
  final num value;
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
      catId: (json['catId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      campus: campusLabel(json['campus']),
      value: json['value'] as num? ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map(
            (e) => e is Map
                ? (e['id'] ?? e['tagId'] ?? '').toString()
                : e.toString(),
          )
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
