import 'package:meow/model/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// 登录状态provider
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Auth build() {
    // 初始用户状态
    return Auth();
  }

  /// 更新用户状态
  void update(User user, [String? token]){
    state = Auth(user: user, token: token??'');
  }

  void clear(){
    state = Auth();
  }
}

class Auth{
  User? _user;
  User? get user => _user;
  String token = '';
  RoleType get role{
    if(loggedIn) return _user!.roleType;
    // 测试时，可以改这里的身份
    return RoleType.admin;
  }

  bool get loggedIn => _user!=null && _user!.createTime != DateTime.fromMillisecondsSinceEpoch(0);

  Auth({User? user, this.token = ''}){
    _user = user;
  }

  Auth copyWith({User? user, String? token}){
    return Auth(user: user?? this._user, token: token?? this.token);
  }
}