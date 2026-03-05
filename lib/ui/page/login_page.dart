import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _doLogin() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    if (!email.contains("@mail.sdu.edu.cn") || pwd.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入山大邮箱和密码')));
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = AuthRepository();
      final result = await repo.login(email: email, password: pwd);

      ref.read(authStateProvider.notifier).update(result.user, result.token);

      // 不需要 Navigator，MyApp 会自动切到 MainPage
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('登录失败：$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //游客模式
  void _doGuestLogin() {
    final now = DateTime.now();
    final user = User(
      id: 'guest',
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
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: '山大邮箱',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                      Text('立即登录'),
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

                // 游客访问/忘记密码
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _doGuestLogin,
                          child: const Text('游客访问'),
                        ),
                        const Text(
                          ' | ',
                          style: TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RegisterPage()),
                            );
                          },
                          child: const Text('注册账号'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('忘记密码：请联系统一认证平台')),
                            );
                          },
                          child: const Text('忘记密码'),
                        ),
                      ],
                    ),
                  ],
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     TextButton(
                //       onPressed: _doGuestLogin,
                //       child: const Text('游客访问'),
                //     ),
                //     const Text(' | ', style: TextStyle(color: Colors.black54)),
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
          ),
        ),
      ),
    );
  }
}
