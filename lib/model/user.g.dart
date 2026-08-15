// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['uid'] as num).toInt(),
  studentId: json['sid'] as String? ?? '',
  nickname: json['nickname'] as String?,
  realName: json['realName'] as String?,
  avatar: json['avatar'] as String?,
  roleType:
      $enumDecodeNullable(_$RoleTypeEnumMap, json['roleType']) ??
      RoleType.student,
  campus: $enumDecodeNullable(_$CampusEnumMap, json['campus']),
  currency: (json['currency'] as num?)?.toInt() ?? 0,
  level: (json['level'] as num?)?.toInt() ?? 0,
  levelTitle: json['title'] as String?,
  experience: (json['exp'] as num?)?.toInt() ?? 0,
  nextLevelExp: (json['nextExp'] as num?)?.toInt() ?? 0,
  createTime: json['createTime'] == null
      ? null
      : DateTime.parse(json['createTime'] as String),
  stats: json['stats'] == null
      ? null
      : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
  wechat: json['wechat'] as String?,
  phone: json['phone'] as String?,
  showBadge: json['showBadge'] as bool?,
  pushNotification: json['pushNotification'] as bool?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'uid': instance.id,
  'sid': instance.studentId,
  'nickname': instance.nickname,
  'realName': instance.realName,
  'avatar': instance.avatar,
  'roleType': _$RoleTypeEnumMap[instance.roleType]!,
  'campus': _$CampusEnumMap[instance.campus],
  'currency': instance.currency,
  'level': instance.level,
  'title': instance.levelTitle,
  'exp': instance.experience,
  'nextExp': instance.nextLevelExp,
  'createTime': instance.createTime?.toIso8601String(),
  'stats': instance.stats,
  'wechat': instance.wechat,
  'phone': instance.phone,
  'showBadge': instance.showBadge,
  'pushNotification': instance.pushNotification,
};

const _$RoleTypeEnumMap = {
  RoleType.guest: -1,
  RoleType.student: 0,
  RoleType.admin: 1,
  RoleType.superAdmin: 2,
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
  Campus.longshan: 8,
};

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
  feedCount: (json['feedCount'] as num?)?.toInt() ?? 0,
  found: (json['found'] as num?)?.toInt() ?? 0,
  receivedLikes: (json['receivedLikes'] as num?)?.toInt() ?? 0,
  momentCount: (json['postCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
  'feedCount': instance.feedCount,
  'found': instance.found,
  'receivedLikes': instance.receivedLikes,
  'postCount': instance.momentCount,
};
