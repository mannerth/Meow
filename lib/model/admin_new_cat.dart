import 'package:meow/model/user.dart';

class AdminNewCatListPage {
  final int total;
  final int? size;
  final int? current;
  final int? pages;
  final List<AdminNewCatItem> items;

  AdminNewCatListPage({
    required this.total,
    required this.items,
    this.size,
    this.current,
    this.pages,
  });

  factory AdminNewCatListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return AdminNewCatListPage(
      total: _intValue(json['total']) ?? 0,
      size: _intValue(json['size']),
      current: _intValue(json['current']),
      pages: _intValue(json['pages']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AdminNewCatItem.fromJson)
          .toList(),
    );
  }
}

class AdminNewCatItem {
  final String id;
  final String? tempName;
  final String? color;
  final List<String> images;
  final int? campusCode;
  final String? campusName;
  final String? location;
  final String? submitterId;
  final String? submitterName;
  final String status;
  final String? createTime;

  AdminNewCatItem({
    required this.id,
    required this.status,
    this.tempName,
    this.color,
    this.images = const [],
    this.campusCode,
    this.campusName,
    this.location,
    this.submitterId,
    this.submitterName,
    this.createTime,
  });

  factory AdminNewCatItem.fromJson(Map<String, dynamic> json) {
    final campusValue = json['campus'];
    final imagesValue = json['images'] ?? json['imageUrls'] ?? json['media'];
    return AdminNewCatItem(
      id: _stringValue(json['id']),
      tempName: _nullableString(json['tempName']),
      color: _nullableString(json['color']),
      images: _imageList(imagesValue),
      campusCode: _campusCodeFromDynamic(campusValue),
      campusName: _campusNameFromDynamic(campusValue),
      location: _nullableString(json['location']),
      submitterId: _nullableString(json['submitterId']),
      submitterName: _nullableString(json['submitterName']),
      status: _stringValue(json['status']).toUpperCase(),
      createTime: _nullableString(json['createTime'] ?? json['create_time']),
    );
  }

  Campus? get campus {
    final code = campusCode;
    if (code == null) return null;
    for (final item in Campus.values) {
      if (item.code == code) return item;
    }
    return null;
  }
}

int? _campusCodeFromDynamic(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _campusNameFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
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

List<String> _imageList(dynamic value) {
  if (value is List) {
    return value.map((item) {
      if (item is Map<String, dynamic> && item['url'] != null) {
        return item['url'].toString();
      }
      return item.toString();
    }).toList();
  }
  return const [];
}
