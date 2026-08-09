import 'package:meow/api/http.dart';

/// 后端预设的类型列表（颜色/症状/标签/地点/角色等）
class TypeItem {
  final int id;
  final String label;

  const TypeItem({required this.id, required this.label});

  factory TypeItem.fromJson(Map<String, dynamic> json) => TypeItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    label: (json['label'] ?? json['name'] ?? json['tag'] ?? '').toString(),
  );
}

class TypeService {
  static List<TypeItem>? _colors;
  static List<TypeItem>? _symptoms;
  static List<TypeItem>? _tags;
  static List<TypeItem>? _locations;
  static List<TypeItem>? _roles;

  static Future<List<TypeItem>> fetchColors({bool force = false}) async {
    return _fetch(
      '/type/colors',
      cache: _colors,
      setCache: (v) => _colors = v,
      force: force,
    );
  }

  static Future<List<TypeItem>> fetchSymptoms({bool force = false}) async {
    return _fetch(
      '/type/symptoms',
      cache: _symptoms,
      setCache: (v) => _symptoms = v,
      force: force,
    );
  }

  static Future<List<TypeItem>> fetchTags({bool force = false}) async {
    return _fetch(
      '/type/tags',
      cache: _tags,
      setCache: (v) => _tags = v,
      force: force,
    );
  }

  static Future<List<TypeItem>> fetchLocations({bool force = false}) async {
    return _fetch(
      '/type/locations',
      cache: _locations,
      setCache: (v) => _locations = v,
      force: force,
    );
  }

  static Future<List<TypeItem>> fetchRoles({bool force = false}) async {
    return _fetch(
      '/type/roles',
      cache: _roles,
      setCache: (v) => _roles = v,
      force: force,
    );
  }

  static Future<List<TypeItem>> _fetch(
    String path, {
    required List<TypeItem>? cache,
    required void Function(List<TypeItem>?) setCache,
    bool force = false,
  }) async {
    if (!force && cache != null) return cache;
    try {
      final response = await Http().get(path, allowRetry: false);
      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      final list = <TypeItem>[];
      if (data is List) {
        list.addAll(
          data
              .whereType<Map<String, dynamic>>()
              .map(TypeItem.fromJson)
              .toList(),
        );
      }
      setCache(list);
      return list;
    } catch (_) {
      return cache ?? const [];
    }
  }

  /// 根据 id 查询名称（颜色等 `{id,label}` 类型列表）
  static String? labelById(int? id, List<TypeItem>? list) {
    if (id == null || list == null) return null;
    for (final item in list) {
      if (item.id == id) return item.label;
    }
    return null;
  }

  /// 症状 id -> 名称
  static String symptomLabel(int? id) {
    final label = labelById(id, _symptoms);
    if (label != null) return label;
    return id?.toString() ?? '';
  }

  /// 颜色 id -> 名称
  static String colorLabel(int? id) {
    final label = labelById(id, _colors);
    if (label != null) return label;
    return id?.toString() ?? '';
  }

  static bool isNumber(String value) => int.tryParse(value) != null;
}
