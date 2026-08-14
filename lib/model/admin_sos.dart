import 'package:meow/model/user.dart';
import 'package:meow/model/static_type.dart';

/// SOS 状态采用整数传输：0 待处理、1 处理中、2 已完成。
String sosStatusName(dynamic value) =>
    SosStatus.tryFromApi(value)?.apiName ??
    value?.toString().toUpperCase() ??
    '';

int? sosStatusCode(String? value) => SosStatus.tryFromApi(value)?.code;

class AdminSosListPage {
  final int total;
  final int? size;
  final int? current;
  final int? pages;
  final List<AdminSosItem> items;

  AdminSosListPage({
    required this.total,
    required this.items,
    this.size,
    this.current,
    this.pages,
  });

  factory AdminSosListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return AdminSosListPage(
      total: _intValue(json['total']) ?? 0,
      size: _intValue(json['size']),
      current: _intValue(json['current']),
      pages: _intValue(json['pages']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AdminSosItem.fromJson)
          .toList(),
    );
  }
}

class AdminSosItem {
  final String id;
  final String? catId;
  final String? catName;
  final int? campusCode;
  final String? campusName;
  final String? location;
  final List<String> symptoms;
  final String? description;
  final List<String> imageUrls;
  final String? createTime;
  final String status;
  final String? adminReply;
  final String? reporterId;
  final String? reporterName;

  AdminSosItem({
    required this.id,
    required this.status,
    this.catId,
    this.catName,
    this.campusCode,
    this.campusName,
    this.location,
    this.symptoms = const [],
    this.description,
    this.imageUrls = const [],
    this.createTime,
    this.adminReply,
    this.reporterId,
    this.reporterName,
  });

  factory AdminSosItem.fromJson(Map<String, dynamic> json) {
    final campusValue = json['campus'];
    final symptomsValue = json['symptoms'];
    final imageValue = json['imageURLs'] ?? json['imageUrls'] ?? json['media'];
    return AdminSosItem(
      id: _stringValue(json['id']),
      catId: _nullableString(json['catId']),
      catName: _nullableString(json['catName']),
      campusCode: _campusCodeFromDynamic(campusValue),
      campusName: _campusNameFromDynamic(campusValue),
      location: _nullableString(json['location']),
      symptoms: _stringList(symptomsValue),
      description: _nullableString(json['description']),
      imageUrls: _imageList(imageValue),
      createTime: _nullableString(json['create_time'] ?? json['createTime']),
      status: sosStatusName(json['status']),
      adminReply: _nullableString(json['adminReply']),
      reporterId: _nullableString(json['reporterId']),
      reporterName: _nullableString(json['reporterName']),
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
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    for (final item in Campus.values) {
      if (item.apiKey == value || item.name == value) return item.code;
    }
  }
  return null;
}

String? _campusNameFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return null;
    for (final item in Campus.values) {
      if (item.apiKey == value) return item.name;
    }
    return value;
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

List<String> _imageList(dynamic value) {
  if (value is List) {
    return value
        .map(_imageUrl)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

String _imageUrl(dynamic value) {
  if (value is Map) {
    final url = value['url'] ?? value['imageUrl'] ?? value['imageURL'];
    return url?.toString() ?? '';
  }
  return value?.toString() ?? '';
}
