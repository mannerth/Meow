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

  User({
    required this.id,
    required this.studentId,
    this.nickname,
    this.avatar,
    this.roleType = RoleType.guest,
    this.campus,
    required this.currency,
    required this.level,
    this.levelTitle,
    required this.experience,
    required this.nextLevelExp,
    required this.createTime,
  });

  bool get isGuest => roleType == RoleType.guest;
  bool get isStudent => roleType == RoleType.student;
  bool get isAdmin => roleType == RoleType.admin;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

enum RoleType {
  guest,
  student,
  admin,
}