import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

///用户类
@JsonSerializable()
class User {
  // UUID
  @JsonKey(name: 'uid')
  int id;
  // 学号
  @JsonKey(name: 'sid')
  String studentId;
  // 昵称
  String? nickname;
  // 头像URL
  String? avatar;
  // 角色
  RoleType roleType = RoleType.student;
  // 校区
  Campus? campus;
  // 小鱼干余额
  int currency;
  // 等级
  int level;
  // 等级头衔
  String? levelTitle;
  // 当前经验值
  @JsonKey(name: 'exp')
  int experience;
  // 升级所需经验值
  @JsonKey(name: 'nextExp')
  int nextLevelExp;
  // 注册时间
  DateTime? createTime;

  User({
    required this.id,
    required this.studentId,
    this.nickname,
    this.avatar,
    this.roleType = RoleType.student,
    this.campus,
    required this.currency,
    required this.level,
    this.levelTitle,
    required this.experience,
    required this.nextLevelExp,
    this.createTime,
  });

  bool get isGuest => roleType == RoleType.guest;
  bool get isStudent => roleType == RoleType.student;
  bool get isAdmin => roleType == RoleType.admin;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    int? id,
    String? studentId,
    String? nickname,
    String? avatar,
    RoleType? roleType,
    Campus? campus,
    int? currency,
    int? level,
    String? levelTitle,
    int? experience,
    int? nextLevelExp,
    DateTime? createTime,
  }) {
    return User(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      roleType: roleType ?? this.roleType,
      campus: campus ?? this.campus,
      currency: currency ?? this.currency,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      experience: experience ?? this.experience,
      nextLevelExp: nextLevelExp ?? this.nextLevelExp,
      createTime: createTime ?? this.createTime,
    );
  }
}

enum RoleType {
  guest,
  student,
  admin,
}

@JsonEnum(valueField: 'code')
enum Campus {
  zhongxin(0, '中心校区'),
  baotuquan(1, '趵突泉校区'),
  hongjialou(2, '洪家楼校区'),
  qianfoshan(3, '千佛山校区'),
  xinglongshan(4, '兴隆山校区'),
  ruanjianyuan(5, '软件园校区'),
  qingdao(6, '青岛校区'),
  weihai(7, '威海校区');
  
  final int code;
  final String name;
  const Campus(this.code, this.name);
}