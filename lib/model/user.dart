import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

///用户类
@JsonSerializable()
class User {
  // UUID
  String id;
  // 学号
  String studentId;
  // 昵称
  String? nickname;
  //学生真实姓名
  String? realName;
  // 头像URL
  String? avatar;
  // 角色
  RoleType roleType = RoleType.guest;
  // 校区
  String? campus;
  // 小鱼干余额
  int currency;
  // 等级
  int level;
  // 等级头衔
  String? levelTitle;
  // 当前经验值
  int experience;
  // 升级所需经验值
  int nextLevelExp;
  // 注册时间
  DateTime createTime;
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
    this.roleType = RoleType.guest,
    this.campus,
    required this.currency,
    required this.level,
    this.levelTitle,
    required this.experience,
    required this.nextLevelExp,
    required this.createTime,
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
    String? campus,
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
    );
  }

  bool get isGuest => roleType == RoleType.guest;
  bool get isStudent => roleType == RoleType.student;
  bool get isAdmin => roleType == RoleType.admin;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

enum RoleType { guest, student, admin }
