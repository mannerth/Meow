import 'package:meow/model/user.dart';

class AdminDashboardStats {
  final int pendingSos;
  final int adoptApplications;
  final int totalCats;
  final int pendingNewCatClues;
  final List<CampusDistribution> campusDistribution;

  AdminDashboardStats({
    required this.pendingSos,
    required this.adoptApplications,
    required this.totalCats,
    required this.campusDistribution,
    required this.pendingNewCatClues,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final distribution = (json['campusDistribution'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CampusDistribution.fromJson)
        .toList();
    return AdminDashboardStats(
      pendingSos: _intValue(json['pendingSOS']) ?? 0,
      adoptApplications: _intValue(
            json['adoptApplications'] ?? json['adoptionApplications'],
          ) ??
          0,
      totalCats: _intValue(json['totalCats']) ?? 0,
      campusDistribution: distribution,
      pendingNewCatClues: _intValue(json['pendingNewCatClues']) ?? 0,
    );
  }
}

class CampusDistribution {
  final int? campusCode;
  final String? campusKey;
  final int count;
  final double percentage;

  CampusDistribution({
    required this.campusCode,
    required this.campusKey,
    required this.count,
    required this.percentage,
  });

  factory CampusDistribution.fromJson(Map<String, dynamic> json) {
    final campusValue = json['campus'];
    return CampusDistribution(
      campusCode: _campusCodeFromDynamic(campusValue),
      campusKey: _campusKeyFromDynamic(campusValue),
      count: _intValue(json['count']) ?? 0,
      percentage: _percentageValue(json['percentage']) ?? 0,
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

String? _campusKeyFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return null;
}

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _percentageValue(dynamic value) {
  if (value is num) {
    final raw = value.toDouble();
    if (raw > 1) return raw / 100;
    return raw;
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    if (parsed > 1) return parsed / 100;
    return parsed;
  }
  return null;
}
