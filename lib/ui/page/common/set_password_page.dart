import 'package:flutter/material.dart';
import 'package:meow/api/service/auth_repository.dart';

class SetPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const SetPasswordPage({super.key, required this.email, required this.code});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final pwd = _pwdCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pwd.isEmpty || confirm.isEmpty || pwd != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("两次密码不一致")));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthRepository().register(
        email: widget.email,
        code: widget.code,
        password: pwd,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("注册成功，请登录")));
      Navigator.of(context).popUntil((route) => route.isFirst); // 返回登录页
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("注册失败：$e")));
    } finally {
      setState(() => _loading = false);
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
                    Icons.lock_outline,
                    color: Colors.black87,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '设置登录密码',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '请输入密码',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '确认密码',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: FilledButton(
                            onPressed: _loading ? null : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  )
                                : const Text(
                                    '完成注册',
                                    style: TextStyle(fontSize: 17),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
