import 'package:meow/model/user.dart';

class AdminUserListItem {
  final String id;
  final String name;
  final String status;

  AdminUserListItem({
    required this.id,
    required this.name,
    required this.status,
  });

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    return AdminUserListItem(
      id: _stringValue(json['id'] ?? json['uid']),
      name: _stringValue(
        json['name'] ?? json['nickname'] ?? json['userName'] ?? json['email'],
      ),
      status: _stringValue(json['status'] ?? 'NORMAL'),
    );
  }
}

class AdminUserListPage {
  final int total;
  final List<AdminUserListItem> items;

  AdminUserListPage({required this.total, required this.items});

  factory AdminUserListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return AdminUserListPage(
      total: _intValue(json['total']) ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AdminUserListItem.fromJson)
          .toList(),
    );
  }
}

class AdminUserStats {
  final int feedCount;
  final int foundCount;
  final int receivedLikes;
  final int momentCount;

  AdminUserStats({
    required this.feedCount,
    required this.foundCount,
    required this.receivedLikes,
    required this.momentCount,
  });

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    final foundValue = json['found'] ?? json['foundNewCatCount'];
    return AdminUserStats(
      feedCount: _intValue(json['feedCount']) ?? 0,
      foundCount: _intValue(foundValue) ?? 0,
      receivedLikes: _intValue(json['receivedLikes']) ?? 0,
      momentCount: _intValue(json['momentCount']) ?? 0,
    );
  }
}

class AdminUserDetail {
  final String id;
  final String? name;
  final String? nickname;
  final String? role;
  final String? studentId;
  final int? campusCode;
  final Campus? campus;
  final int? level;
  final String? status;
  final AdminUserStats stats;

  AdminUserDetail({
    required this.id,
    required this.name,
    required this.nickname,
    required this.role,
    required this.studentId,
    required this.campusCode,
    required this.campus,
    required this.level,
    required this.status,
    required this.stats,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final campusValue = json['campus'];
    final campusCode = _intValue(campusValue);
    return AdminUserDetail(
      id: _stringValue(json['id'] ?? json['uid']),
      name: _nullableString(json['name']),
      nickname: _nullableString(json['nickname']),
      role: _nullableString(json['role']),
      studentId: _nullableString(json['sid'] ?? json['studentId']),
      campusCode: campusCode,
      campus: _campusFromDynamic(campusValue),
      level: _intValue(json['level']),
      status: _nullableString(json['status']),
      stats: AdminUserStats.fromJson(
        (json['stats'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}

Campus? _campusFromDynamic(dynamic value) {
  if (value is num) {
    final code = value.toInt();
    for (final campus in Campus.values) {
      if (campus.code == code) return campus;
    }
    return null;
  }
  if (value is String && value.isNotEmpty) {
    for (final campus in Campus.values) {
      if (campus.name == value ||
          campus.name.toLowerCase() == value.toLowerCase()) {
        return campus;
      }
    }
  }
  return null;
}

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final result = value.toString();
  return result.isEmpty ? null : result;
}
