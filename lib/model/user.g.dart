// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
  roleType:
      $enumDecodeNullable(_$RoleTypeEnumMap, json['roleType']) ??
      RoleType.guest,
  campus: json['campus'] as String?,
  currency: (json['currency'] as num).toInt(),
  level: (json['level'] as num).toInt(),
  levelTitle: json['levelTitle'] as String?,
  experience: (json['experience'] as num).toInt(),
  nextLevelExp: (json['nextLevelExp'] as num).toInt(),
  createTime: DateTime.parse(json['createTime'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'roleType': _$RoleTypeEnumMap[instance.roleType]!,
  'campus': instance.campus,
  'currency': instance.currency,
  'level': instance.level,
  'levelTitle': instance.levelTitle,
  'experience': instance.experience,
  'nextLevelExp': instance.nextLevelExp,
  'createTime': instance.createTime.toIso8601String(),
};

const _$RoleTypeEnumMap = {
  RoleType.guest: 'guest',
  RoleType.student: 'student',
  RoleType.admin: 'admin',
};
