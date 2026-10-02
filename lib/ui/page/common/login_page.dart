import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:meow/api/Urls.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/widget/adaptive/adaptive_scaffold.dart';
import 'package:meow/util/android_browser_login.dart';
import 'package:meow/util/store.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool popAfterLogin;
  final bool showLoginExpired;

  const LoginPage({
    super.key,
    this.popAfterLogin = false,
    this.showLoginExpired = false,
  });
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;
  bool _waitingForBrowser = false;
  int _count = 0; //点击计数
  bool _isAdmin = false; // 是否管理员登录

  bool get _usesAndroidBrowser =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _doLogin() async {
    final isAdmin = _isAdmin;
    final url = isAdmin ? Urls.Auth_Admin : Urls.Auth;
    await _runLogin(() async {
      if (_usesAndroidBrowser) {
        return AndroidBrowserLogin.authenticate(url: url, isAdmin: isAdmin);
      }
      return BrowserLoginResult(
        url: await FlutterWebAuth2.authenticate(
          url: url,
          callbackUrlScheme: 'meow',
          options: const FlutterWebAuth2Options(useWebview: false),
        ),
        isAdmin: isAdmin,
      );
    });
  }

  Future<void> _restoreBrowserLogin() async {
    try {
      final pending = await AndroidBrowserLogin.hasPendingLogin();
      if (!mounted || _loading || !pending) return;
      await _runLogin(AndroidBrowserLogin.resumeLogin);
    } on PlatformException catch (e) {
      if (mounted) _showLoginError(e);
    }
  }

  Future<void> _runLogin(
    Future<BrowserLoginResult> Function() authenticate,
  ) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _waitingForBrowser = _usesAndroidBrowser;
    });
    try {
      final result = await authenticate();
      if (!mounted) return;
      setState(() => _waitingForBrowser = false);

      final uri = Uri.parse(result.url);
      if (uri.scheme != 'meow') {
        throw const FormatException('登录回调地址无效');
      }
      final param = uri.queryParameters;
      final String token = param['meow_token'] ?? '';
      final String refreshToken = param['meow_refresh_token'] ?? '';

      if (token.isEmpty || refreshToken.isEmpty) {
        throw Exception('获取的token为空');
      }

      Http().setTokens(token, refreshToken);

      User user = await AuthRepository.getMe();
      if (!mounted) return;
      if (result.isAdmin) {
        user.roleType = RoleType.admin;
      }
      ref.read(authStateProvider.notifier).update(user);

      Store().setString('roleType', user.roleType.toString());

      if (widget.popAfterLogin) {
        Navigator.of(context).pop();
      }
      // 不需要 Navigator，MyApp 会自动切到 MainPage
    } catch (e) {
      if (mounted) _showLoginError(e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _waitingForBrowser = false;
        });
      }
    }
  }

  void _showLoginError(Object error) {
    if (error is PlatformException && error.code == 'CANCELED') return;
    final needsSettings =
        error is PlatformException &&
        (error.code == 'NO_DEFAULT_BROWSER' ||
            error.code == 'BROWSER_UNAVAILABLE');
    final message = switch (error) {
      PlatformException(:final message) => message ?? '无法完成浏览器登录，请重试',
      FormatException() => '登录回调数据无效，请重试',
      _ => '未能完成登录，请重试',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: needsSettings
            ? SnackBarAction(label: '设置', onPressed: _openBrowserSettings)
            : null,
      ),
    );
    // Exception details may contain the callback URL or credentials.
    debugPrint('Login failed: ${error.runtimeType}');
  }

  Future<void> _openBrowserSettings() async {
    try {
      await AndroidBrowserLogin.openDefaultBrowserSettings();
    } on PlatformException catch (e) {
      if (mounted) _showLoginError(e);
    }
  }

  Future<void> _cancelBrowserLogin() async {
    try {
      await AndroidBrowserLogin.cancelLogin();
    } on PlatformException catch (e) {
      if (mounted) _showLoginError(e);
    }
  }

  //游客模式
  void _doGuestLogin() {
    final now = DateTime.now();
    final user = User(
      id: -1,
      studentId: '',
      nickname: '游客',
      avatar: null,
      roleType: RoleType.guest,
      campus: null,
      currency: 0,
      level: 0,
      levelTitle: '游客',
      experience: 0,
      nextLevelExp: 0,
      createTime: now,
    );
    ref.read(authStateProvider.notifier).update(user, '');
    Store().setString('roleType', RoleType.guest.toString());
    if (widget.popAfterLogin) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (_usesAndroidBrowser) unawaited(_restoreBrowserLogin());
    if (widget.showLoginExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登录状态已过期，请重新登录')));
      });
    }
  }

  @override
  void dispose() {
    if (_waitingForBrowser) unawaited(_cancelBrowserLogin());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      maxContentWidth: 480,
      backgroundColor: const Color(0xFFF6F3EF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    ++_count;
                  },
                  onLongPress: () {
                    if (_count >= 3 && !_loading) {
                      _isAdmin = !_isAdmin;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已切换为${_isAdmin ? '管理员' : '用户'}登录'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE066),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.black87,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hello, 校友！',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '欢迎回到山大猫猫图鉴',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _doLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('统一认证登录'),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward),
                                    ],
                                  ),
                          ),
                        ),
                        if (_waitingForBrowser) ...[
                          const SizedBox(height: 8),
                          const Text('请在默认浏览器中完成登录'),
                          TextButton(
                            onPressed: _cancelBrowserLogin,
                            child: const Text('取消登录'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'SDU Meow',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 游客访问
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _loading ? null : _doGuestLogin,
                          child: const Text('游客访问'),
                        ),
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     TextButton(
                    //       onPressed: () {
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           const SnackBar(content: Text('忘记密码：请联系统一认证平台')),
                    //         );
                    //       },
                    //       child: const Text('忘记密码'),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Checkbox(
                //       value: _isAdmin,
                //       onChanged: (val) {
                //         setState(() {
                //           _isAdmin = val ?? false;
                //         });
                //       },
                //     ),
                //     const Text('管理员登录'),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
