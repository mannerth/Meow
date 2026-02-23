// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['uid'] as num).toInt(),
      studentId: json['sid'] as String,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      roleType: $enumDecodeNullable(_$RoleTypeEnumMap, json['roleType']) ??
          RoleType.student,
      campus: $enumDecodeNullable(_$CampusEnumMap, json['campus']),
      currency: (json['currency'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      levelTitle: json['levelTitle'] as String?,
      experience: (json['exp'] as num).toInt(),
      nextLevelExp: (json['nextExp'] as num).toInt(),
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'uid': instance.id,
      'sid': instance.studentId,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'roleType': _$RoleTypeEnumMap[instance.roleType]!,
      'campus': _$CampusEnumMap[instance.campus],
      'currency': instance.currency,
      'level': instance.level,
      'levelTitle': instance.levelTitle,
      'exp': instance.experience,
      'nextExp': instance.nextLevelExp,
      'createTime': instance.createTime?.toIso8601String(),
    };

const _$RoleTypeEnumMap = {
  RoleType.guest: 'guest',
  RoleType.student: 'student',
  RoleType.admin: 'admin',
};

const _$CampusEnumMap = {
  Campus.zhongxin: 0,
  Campus.baotuquan: 1,
  Campus.hongjialou: 2,
  Campus.qianfoshan: 3,
  Campus.xinglongshan: 4,
  Campus.ruanjianyuan: 5,
  Campus.qingdao: 6,
  Campus.weihai: 7,
};
