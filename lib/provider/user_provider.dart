import 'package:meow/model/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
class UserState extends _$UserState {
  @override
  User build() {
    // 初始用户状态，可以是空字符串或默认用户ID
    return User(
      id: '',
      studentId: '',
      currency: 0,
      level: 0,
      experience: 0,
      nextLevelExp: 0,
      createTime: DateTime.now(),

      // 测试时可以改这里的角色类型
      roleType: RoleType.student
    );
  }

  void setUser(User user) {
    state = user;
  }
}