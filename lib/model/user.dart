import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

///用户类
@JsonSerializable()
class User {
  // UUID
  @JsonKey(name: 'uid')
  int id;
  // 学号
  @JsonKey(name: 'sid', defaultValue: '')
  String studentId;
  // 昵称
  String? nickname;
  //学生真实姓名
  String? realName;
  // 头像URL
  String? avatar;
  // 角色
  RoleType roleType = RoleType.student;
  // 校区
  Campus? campus;
  // 小鱼干余额
  @JsonKey(defaultValue: 0)
  int currency;
  // 等级
  @JsonKey(defaultValue: 0)
  int level;
  // 等级头衔
  @JsonKey(name: 'title')
  String? levelTitle;
  // 当前经验值
  @JsonKey(name: 'exp', defaultValue: 0)
  int experience;
  // 升级所需经验值
  @JsonKey(name: 'nextExp', defaultValue: 0)
  int nextLevelExp;
  // 注册时间
  DateTime? createTime;
  // 统计信息
  UserStats? stats;
  //微信号
  String? wechat;
  //手机号
  String? phone;
  //徽章
  bool? showBadge;
  //推送
  bool? pushNotification;

  User({
    required this.id,
    required this.studentId,
    this.nickname,
    this.realName,
    this.avatar,
    this.roleType = RoleType.student,
    this.campus,
    required this.currency,
    required this.level,
    this.levelTitle,
    required this.experience,
    required this.nextLevelExp,
    this.createTime,
    this.stats,
    this.wechat,
    this.phone,
    this.showBadge,
    this.pushNotification,
  });

  User copyWith({
    String? nickname,
    String? realName,
    String? avatar,
    RoleType? roleType,
    Campus? campus,
    int? currency,
    int? level,
    String? levelTitle,
    int? experience,
    int? nextLevelExp,
    DateTime? createTime,
    String? wechat,
    String? phone,
    bool? showBadge,
    bool? pushNotification,
    UserStats? stats,
  }) {
    return User(
      id: id,
      studentId: studentId,
      nickname: nickname ?? this.nickname,
      realName: realName ?? this.realName,
      avatar: avatar ?? this.avatar,
      roleType: roleType ?? this.roleType,
      campus: campus ?? this.campus,
      currency: currency ?? this.currency,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      experience: experience ?? this.experience,
      nextLevelExp: nextLevelExp ?? this.nextLevelExp,
      createTime: createTime ?? this.createTime,
      wechat: wechat ?? this.wechat,
      phone: phone ?? this.phone,
      showBadge: showBadge ?? this.showBadge,
      pushNotification: pushNotification ?? this.pushNotification,
      stats: stats ?? this.stats,
    );
  }

  bool get isGuest => roleType == RoleType.guest;
  bool get isStudent => roleType == RoleType.student;
  bool get isAdmin => roleType == RoleType.admin;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

enum RoleType { guest, student, admin }

@JsonEnum(valueField: 'code')
enum Campus {
  zhongxin(0, '中心校区', 'ZHONG_XIN'),
  baotuquan(1, '趵突泉校区', 'BAO_TU_QUAN'),
  hongjialou(2, '洪家楼校区', 'HONG_JIA_LOU'),
  qianfoshan(3, '千佛山校区', 'QIAN_FO_SHAN'),
  xinglongshan(4, '兴隆山校区', 'XING_LONG_SHAN'),
  ruanjianyuan(5, '软件园校区', 'RUAN_JIAN_YUAN'),
  qingdao(6, '青岛校区', 'QING_DAO'),
  weihai(7, '威海校区', 'WEI_HAI'),
  longshan(8, '龙山校区', 'LONG_SHAN');

  final int code;
  final String name;
  final String apiKey;
  const Campus(this.code, this.name, this.apiKey);

  static Campus? fromCode(int? code) {
    if (code == null) return null;
    for (final campus in Campus.values) {
      if (campus.code == code) return campus;
    }
    return null;
  }

  static Campus? fromApi(dynamic value) {
    if (value is num) return fromCode(value.toInt());
    final text = value?.toString() ?? '';
    final code = int.tryParse(text);
    if (code != null) return fromCode(code);
    for (final campus in Campus.values) {
      if (campus.name == text || campus.apiKey == text) return campus;
    }
    return null;
  }
}

@JsonSerializable()
class UserStats {
  @JsonKey(defaultValue: 0)
  int feedCount;
  @JsonKey(defaultValue: 0)
  int found;
  @JsonKey(defaultValue: 0)
  int receivedLikes;
  @JsonKey(name: 'postCount', defaultValue: 0)
  int momentCount;

  UserStats({
    required this.feedCount,
    required this.found,
    required this.receivedLikes,
    required this.momentCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}
