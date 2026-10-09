import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';
import 'package:meow/util/store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// 在 runApp 前注入恢复后的会话，避免在 Widget 生命周期修改 Provider。
final initialAuthProvider = Provider<Auth>((ref) => Auth());

/// 登录状态provider
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Auth build() {
    return ref.read(initialAuthProvider);
  }

  /// 更新用户状态
  void update(User user, [String? token]) {
    Store().user = user;
    if (token != null) Http().setToken(token);
    state = Auth(user: user, token: token ?? Http().token ?? state.token);
  }

  void clear() {
    Http().clearToken();
    Store().user = null;
    Store().remove('roleType');
    state = Auth();
  }

  void decrementCurrency(int amount) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        currency: state.user!.currency - amount,
      );
      update(updatedUser);
    }
  }
}

class Auth {
  User? _user;
  User? get user => _user;
  String token = '';
  RoleType get role {
    if (loggedIn) return _user!.roleType;
    // 测试时，可以改这里的身份
    return RoleType.guest;
  }

  bool get loggedIn => _user != null && _user!.roleType != RoleType.guest;

  Auth({User? user, this.token = ''}) {
    _user = user;
  }

  factory Auth.fromStore() {
    final store = Store();
    if (store.user != null) {
      return Auth(user: store.user, token: store.accessToken ?? '');
    }
    if (store.getString('roleType') == RoleType.guest.toString()) {
      return Auth(
        user: User(
          id: -1,
          studentId: '',
          nickname: '游客',
          roleType: RoleType.guest,
          currency: 0,
          level: 0,
          experience: 0,
          nextLevelExp: 0,
        ),
      );
    }
    return Auth();
  }

  Auth copyWith({User? user, String? token}) {
    return Auth(user: user ?? this._user, token: token ?? this.token);
  }
}
