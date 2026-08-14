import 'package:meow/model/campus.dart';
import 'package:meow/model/static_type.dart';

/// 猫咪状态 -> 中文（0在校 1毕业 2喵星 3住院）
String catStatusLabel(dynamic status) => CatStatus.fromApi(status).label;

/// 猫咪状态 中文 -> 数字（与 /cats 筛选一致）
int? catStatusToCode(String label) {
  for (final status in CatStatus.values) {
    if (status.label == label) return status.code;
  }
  return null;
}

class Cat {
  final String id;
  final String name;
  final String avatar;
  final String color;
  final int? colorId;
  final String campus;
  final String locationName;
  final int? locationId;
  final int status;
  final List<String> tags;
  final bool isNeutered;
  final int popularity;
  final String lastSeenTime;
  final String roleName;
  final int? roleId;

  Cat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    this.colorId,
    required this.campus,
    required this.locationName,
    this.locationId,
    required this.status,
    required this.tags,
    required this.isNeutered,
    required this.popularity,
    required this.lastSeenTime,
    required this.roleName,
    this.roleId,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
    id: json['id'] as String,
    name: json['name'] as String,
    avatar: (json['avatar'] ?? '').toString(),
    color: json['color'] is num ? '' : (json['color'] ?? '').toString(),
    colorId: _intValue(json['color']),
    campus: campusLabel(json['campus']),
    locationName: json['location'] is num
        ? ''
        : (json['locationName'] ?? json['location'] ?? '').toString(),
    locationId: _intValue(json['location'] ?? json['locationId']),
    status: (json['status'] is num)
        ? (json['status'] as num).toInt()
        : (catStatusToCode((json['status'] ?? '').toString()) ?? 0),
    tags: (json['tags'] as List<dynamic>?)?.map(_tagIdString).toList() ?? [],
    isNeutered: json['isNeutered'] as bool? ?? false,
    popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    lastSeenTime: (json['lastSeenTime'] ?? '') as String,
    roleName: json['role'] is num ? '' : (json['roleName'] ?? '').toString(),
    roleId: _intValue(json['role'] ?? json['roleId']),
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

String _tagIdString(dynamic value) {
  if (value is Map) {
    return (value['id'] ?? value['tagId'] ?? value['key'] ?? '').toString();
  }
  return value?.toString() ?? '';
}

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
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
