import 'package:meow/model/campus.dart';

/// 猫咪状态 -> 中文（0在校 1毕业 2喵星 3住院）
String catStatusLabel(dynamic status) {
  if (status is num) {
    switch (status.toInt()) {
      case 0:
        return '在校';
      case 1:
        return '毕业';
      case 2:
        return '喵星';
      case 3:
        return '住院';
    }
  }
  final str = status?.toString() ?? '';
  if (str.isEmpty) return '在校';
  return str;
}

/// 猫咪状态 中文 -> 数字（与 /cats 筛选一致）
int? catStatusToCode(String label) {
  switch (label) {
    case '在校':
      return 0;
    case '毕业':
      return 1;
    case '喵星':
      return 2;
    case '住院':
      return 3;
  }
  return null;
}

class Cat {
  final String id;
  final String name;
  final String avatar;
  final String color;
  final String campus;
  final String locationName;
  final int status;
  final List<String> tags;
  final bool isNeutered;
  final int popularity;
  final String lastSeenTime;
  final String roleName;

  Cat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    required this.campus,
    required this.locationName,
    required this.status,
    required this.tags,
    required this.isNeutered,
    required this.popularity,
    required this.lastSeenTime,
    required this.roleName,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: (json['avatar'] ?? '').toString(),
    color: (json['color'] ?? '').toString(),
    campus: campusLabel(json['campus']),
    locationName: (json['locationName'] ?? json['location'] ?? '').toString(),
    status: (json['status'] is num)
        ? (json['status'] as num).toInt()
        : (catStatusToCode((json['status'] ?? '').toString()) ?? 0),
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    isNeutered: json['isNeutered'] as bool? ?? false,
    popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    lastSeenTime: (json['lastSeenTime'] ?? '') as String,
    roleName: (json['roleName'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'color': color,
    'campus': campus,
    'locationName': locationName,
    'status': status,
    'tags': tags,
    'isNeutered': isNeutered,
    'popularity': popularity,
    'lastSeenTime': lastSeenTime,
    'roleName': roleName,
  };
}

class CatPage {
  final int total;
  final int currentPage;
  final int totalPage;
  final bool hasNext;
  final List<Cat> items;

  CatPage({
    required this.total,
    required this.currentPage,
    required this.totalPage,
    required this.hasNext,
    required this.items,
  });

  factory CatPage.fromJson(Map<String, dynamic> json) => CatPage(
    total: (json['total'] as num?)?.toInt() ?? 0,
    currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
    totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
    hasNext: json['hasNext'] as bool? ?? false,
    items: (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Cat.fromJson)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'currentPage': currentPage,
    'totalPage': totalPage,
    'hasNext': hasNext,
    'items': items.map((e) => e.toJson()).toList(),
  };
}
