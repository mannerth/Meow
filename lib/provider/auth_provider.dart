import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_provider.dart';
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
  void update(User user, [String? token]) {
    state = Auth(user: user, token: token ?? '');
    if (token != null) {
      Http().setToken(token);
    }
  }

  void clear() {
    state = Auth();
    Http().clearToken();
    ref
        .watch(navigationProvider.notifier)
        .setCurrentIndex(0, controlJump: true);
  }

  void decrementCurrency(int amount) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        currency: state.user!.currency - amount,
      );
      update(updatedUser, state.token);
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

  bool get loggedIn => _user != null;

  Auth({User? user, this.token = ''}) {
    _user = user;
  }

  Auth copyWith({User? user, String? token}) {
    return Auth(user: user ?? this._user, token: token ?? this.token);
  }
}
