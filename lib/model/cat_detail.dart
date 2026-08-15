import 'package:meow/model/static_type.dart';
import 'package:meow/model/user.dart';

/// 性别 -> 中文（0未知 1男 2女）
String catGenderLabel(dynamic value) => CatGender.fromApi(value).label;

/// 绝育类型 -> 中文（0剪耳 1未剪耳）
String catNeuteredTypeLabel(dynamic value) =>
    CatNeuteredType.fromApi(value).label;

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
    tags: (json['tags'] as List<dynamic>?)?.map(_tagIdString).toList() ?? [],
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

String _tagIdString(dynamic value) {
  if (value is Map) {
    return (value['id'] ?? value['tagId'] ?? value['key'] ?? '').toString();
  }
  return value?.toString() ?? '';
}

class CatBasicInfo {
  final String color;
  final CatGender gender;
  final Campus? campus;
  final String hauntLocation;
  final String role;
  final int birthYear;
  final String admissionDate;
  final CatStatus status;
  final CatHealthStatus healthStatus;
  final String lastSeenTime;
  final String furLength;
  final CatNeutered neutered;

  CatBasicInfo({
    required this.color,
    required this.gender,
    this.campus,
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
    return CatBasicInfo(
      color: _dynamicTypeId(json['color']),
      gender: CatGender.fromApi(json['gender']),
      campus: Campus.fromApi(json['campus']),
      hauntLocation: _dynamicTypeId(json['hauntLocation']),
      role: _dynamicTypeId(json['role']),
      birthYear: (json['birthYear'] as num?)?.toInt() ?? 0,
      admissionDate: json['admissionDate'] as String? ?? '',
      status: CatStatus.fromApi(json['status']),
      healthStatus: CatHealthStatus.fromApi(json['healthStatus']),
      lastSeenTime: json['lastSeenTime'] as String? ?? '',
      furLength: json['furLength'] as String? ?? '',
      neutered: CatNeutered.fromJson(
        json['neutered'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'gender': gender.code,
    'campus': campus?.code,
    'hauntLocation': hauntLocation,
    'role': role,
    'birthYear': birthYear,
    'admissionDate': admissionDate,
    'status': status.code,
    'healthStatus': healthStatus.code,
    'lastSeenTime': lastSeenTime,
    'furLength': furLength,
    'neutered': neutered.toJson(),
  };
}

String _dynamicTypeId(dynamic value) {
  if (value is Map) {
    return (value['id'] ?? value['typeId'] ?? value['code'] ?? '').toString();
  }
  return value?.toString() ?? '';
}

class CatNeutered {
  final bool isNeutered;
  final String neuteredDate;
  final CatNeuteredType type;

  const CatNeutered({
    required this.isNeutered,
    required this.neuteredDate,
    required this.type,
  });

  factory CatNeutered.fromJson(Map<String, dynamic> json) => CatNeutered(
    isNeutered: json['isNeutered'] as bool? ?? false,
    neuteredDate: (json['neuteredDate'] ?? json['date'] ?? '').toString(),
    type: CatNeuteredType.fromApi(json['type']),
  );

  Map<String, dynamic> toJson() => {
    'isNeutered': isNeutered,
    'neuteredDate': neuteredDate,
    'type': type.code,
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
