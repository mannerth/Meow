import 'package:flutter/material.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'set_password_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _countDown = 0;

  void _startCountDown() {
    setState(() => _countDown = 60);
    Future.doWhile(() async {
      if (_countDown > 0) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() => _countDown--);
        return _countDown > 0;
      }
      return false;
    });
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!email.endsWith("@mail.sdu.edu.cn")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请输入有效的山大邮箱")));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthRepository().sendVerificationCode(email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("验证码已发送，请查收邮箱")));
      }
      _startCountDown();
    } catch (e) {
      debugPrint('验证码发送失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("验证码发送失败：${e.toString()}")));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _nextPage() {
    // 检查邮箱和验证码
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (!email.endsWith("@mail.sdu.edu.cn") || code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请填写完整邮箱和验证码")));
      return;
    }
    // 跳转到设置密码页，邮箱/验证码传参
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordPage(email: email, code: code),
      ),
    );
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
                  '注册账号',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '用山大邮箱注册，获取验证码',
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
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeCtrl,
                                decoration: const InputDecoration(
                                  labelText: '验证码',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _countDown > 0 ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE066),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _countDown > 0 ? "重新发送($_countDown)" : "获取验证码",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: FilledButton(
                            onPressed: _loading ? null : _nextPage,
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
                                    '下一步',
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
