import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
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
  //bool _isAdmin = true; // 是否管理员登录

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      final res = await FlutterWebAuth2.authenticate(
        url: 'https://meow.sduonline.cn/auth/login?platform=android', 
        callbackUrlScheme: 'meow',
        options: const FlutterWebAuth2Options(
          useWebview: false
        )
      );

      if ( res.isNotEmpty ){
        debugPrint(res);
      } else {
        debugPrint('返回了空信息');
      }

      Uri uri = Uri.parse(res);
      final param = uri.queryParameters;
      final String token = param['meow_token']?? '';
      final String refresh_token = param['meow_refresh_token']?? '';

      if(token.isEmpty || refresh_token.isEmpty){
        throw Exception('获取的token为空');
      }

      Http().setToken(token);

      User user = await AuthRepository.getMe();
      ref.read(authStateProvider.notifier).update(user);

      // TODO 检查这个逻辑怎么改
      //Store().setString('roleType', result.user.roleType.toString());

      //ref.read(authStateProvider.notifier).update(result.user, result.token);
      
      if(widget.popAfterLogin) {
        Navigator.of(context).pop();
      }
      // 不需要 Navigator，MyApp 会自动切到 MainPage
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('登录失败：$e')));
      }
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    if(widget.popAfterLogin) {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.showLoginExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录状态已过期，请重新登录')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Container(
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
                        SizedBox(
                          height: 20,
                        ),
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
                          onPressed: _doGuestLogin,
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
