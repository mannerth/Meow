import 'package:meow/model/campus.dart';
import 'package:meow/model/cat.dart';

/// 性别 -> 中文（0未知 1男 2女）
String catGenderLabel(dynamic value) {
  if (value is num) {
    switch (value.toInt()) {
      case 1:
        return '公';
      case 2:
        return '母';
      default:
        return '未知';
    }
  }
  return value?.toString() ?? '';
}

/// 绝育类型 -> 中文（0剪耳 1未剪耳）
String catNeuteredTypeLabel(dynamic value) {
  if (value is num) {
    switch (value.toInt()) {
      case 0:
        return '剪耳';
      case 1:
        return '未剪耳';
    }
  }
  return value?.toString() ?? '';
}

class CatDetail {
  final String id;
  final String name;
  final List<String> aliases;
  final String avatar;
  final List<String> images;
  final CatBasicInfo basicInfo;
  final CatAttributes attributes;
  final List<String> tags;
  final List<CatRelation> relationship;
  final String description;
  final int popularity;

  CatDetail({
    required this.id,
    required this.name,
    required this.aliases,
    required this.avatar,
    required this.images,
    required this.basicInfo,
    required this.attributes,
    required this.tags,
    required this.relationship,
    required this.description,
    required this.popularity,
  });

  factory CatDetail.fromJson(Map<String, dynamic> json) => CatDetail(
    id: json['id'] as String,
    name: json['name'] as String,
    aliases:
        (json['aliases'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    avatar: (json['avatar'] ?? '').toString(),
    images:
        (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    basicInfo: CatBasicInfo.fromJson(
      json['basicInfo'] as Map<String, dynamic>? ?? const {},
    ),
    attributes: CatAttributes.fromJson(
      json['attributes'] as Map<String, dynamic>? ?? const {},
    ),
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    relationship:
        (json['relationship'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(CatRelation.fromJson)
            .toList() ??
        [],
    description: json['description'] as String? ?? '',
    popularity: (json['popularity'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'avatar': avatar,
    'images': images,
    'basicInfo': basicInfo.toJson(),
    'attributes': attributes.toJson(),
    'tags': tags,
    'relationship': relationship.map((e) => e.toJson()).toList(),
    'description': description,
    'popularity': popularity,
  };
}

class CatBasicInfo {
  final String color;
  final String gender;
  final String campus;
  final String hauntLocation;
  final String role;
  final int birthYear;
  final String admissionDate;
  final int status;
  final String healthStatus;
  final String lastSeenTime;
  final String furLength;
  final CatNeutered neutered;

  CatBasicInfo({
    required this.color,
    required this.gender,
    required this.campus,
    required this.hauntLocation,
    required this.role,
    required this.birthYear,
    required this.admissionDate,
    required this.status,
    required this.healthStatus,
    required this.lastSeenTime,
    required this.furLength,
    required this.neutered,
  });

  factory CatBasicInfo.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    return CatBasicInfo(
      color: _colorLabel(json['color']),
      gender: catGenderLabel(json['gender']),
      campus: campusLabel(json['campus']),
      hauntLocation: (json['hauntLocation'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      birthYear: (json['birthYear'] as num?)?.toInt() ?? 0,
      admissionDate: json['admissionDate'] as String? ?? '',
      status: statusValue is num
          ? statusValue.toInt()
          : (catStatusToCode((statusValue ?? '').toString()) ?? 0),
      healthStatus: (json['healthStatus'] ?? '').toString(),
      lastSeenTime: json['lastSeenTime'] as String? ?? '',
      furLength: json['furLength'] as String? ?? '',
      neutered: CatNeutered.fromJson(
        json['neutered'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'gender': gender,
    'campus': campus,
    'hauntLocation': hauntLocation,
    'role': role,
    'birthYear': birthYear,
    'admissionDate': admissionDate,
    'status': status,
    'healthStatus': healthStatus,
    'lastSeenTime': lastSeenTime,
    'furLength': furLength,
    'neutered': neutered.toJson(),
  };
}

/// 颜色：新接口可能返回数字 id，先按静态映射兜底
String _colorLabel(dynamic value) {
  if (value is num) {
    const map = {
      1: '橘猫',
      2: '狸花',
      3: '奶牛',
      4: '三花',
      5: '玳瑁',
      6: '纯白',
      7: '纯黑',
      8: '其他',
    };
    return map[value.toInt()] ?? '其他';
  }
  return value?.toString() ?? '';
}

class CatNeutered {
  final bool isNeutered;
  final String neuteredDate;
  final String type;

  const CatNeutered({
    required this.isNeutered,
    required this.neuteredDate,
    required this.type,
  });

  factory CatNeutered.fromJson(Map<String, dynamic> json) => CatNeutered(
    isNeutered: json['isNeutered'] as bool? ?? false,
    neuteredDate: json['neuteredDate'] as String? ?? '',
    type: catNeuteredTypeLabel(json['type']),
  );

  Map<String, dynamic> toJson() => {
    'isNeutered': isNeutered,
    'neuteredDate': neuteredDate,
    'type': type,
  };
}

class CatAttributes {
  final double friendliness;
  final double gluttony;
  final double fight;
  final double appearance;

  CatAttributes({
    required this.friendliness,
    required this.gluttony,
    required this.fight,
    required this.appearance,
  });

  factory CatAttributes.fromJson(Map<String, dynamic> json) => CatAttributes(
    friendliness: (json['friendliness'] as num?)?.toDouble() ?? 0,
    gluttony: (json['gluttony'] as num?)?.toDouble() ?? 0,
    fight: (json['fight'] as num?)?.toDouble() ?? 0,
    appearance: (json['appearance'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'friendliness': friendliness,
    'gluttony': gluttony,
    'fight': fight,
    'appearance': appearance,
  };
}

class CatRelation {
  final String catId;
  final String name;
  final String relation;
  final String avatar;

  CatRelation({
    required this.catId,
    required this.name,
    required this.relation,
    required this.avatar,
  });

  factory CatRelation.fromJson(Map<String, dynamic> json) => CatRelation(
    catId: json['catId'] as String,
    name: json['name'] as String,
    relation: json['relation'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'catId': catId,
    'name': name,
    'relation': relation,
    'avatar': avatar,
  };
}

class CatFeedResult {
  final int userCurrency;

  CatFeedResult({required this.userCurrency});

  factory CatFeedResult.fromJson(Map<String, dynamic> json) =>
      CatFeedResult(userCurrency: (json['userCurrency'] as num?)?.toInt() ?? 0);

  Map<String, dynamic> toJson() => {'userCurrency': userCurrency};
}
