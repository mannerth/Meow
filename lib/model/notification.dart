class NotificationPage {
  const NotificationPage({required this.total, required this.items});

  final int total;
  final List<AppNotification> items;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['records'] ?? json['list'];
    return NotificationPage(
      total: _intValue(json['total']) ?? 0,
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(AppNotification.fromJson)
                .toList()
          : const [],
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    this.content,
    this.createTime,
  });

  final String id;
  final String type;
  final String title;
  final String? content;
  final bool isRead;
  final String? createTime;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'SYSTEM').toString().toUpperCase(),
      title: (json['title'] ?? '').toString(),
      content: _nullableString(json['content']),
      isRead: json['isRead'] == true || json['read'] == true,
      createTime: _nullableString(json['createTime'] ?? json['create_time']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      content: content,
      isRead: isRead ?? this.isRead,
      createTime: createTime,
    );
  }
}

class AnnouncementPage {
  const AnnouncementPage({required this.total, required this.items});

  final int total;
  final List<Announcement> items;

  factory AnnouncementPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['records'] ?? json['list'];
    return AnnouncementPage(
      total: _intValue(json['total']) ?? 0,
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(Announcement.fromJson)
                .toList()
          : const [],
    );
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.content,
    this.summary,
    this.createTime,
  });

  final String id;
  final String title;
  final String? content;
  final String? summary;
  final String type;
  final String status;
  final String? createTime;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: _nullableString(json['content']),
      summary: _nullableString(json['summary']),
      type: (json['type'] ?? 'NEWS').toString().toUpperCase(),
      status: (json['status'] ?? 'PUBLISHED').toString().toUpperCase(),
      createTime: _nullableString(json['createTime'] ?? json['create_time']),
    );
  }
}

int? _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
