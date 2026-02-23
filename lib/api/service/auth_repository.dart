import 'dart:convert';
import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';

// 登录返回的数据结构
class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository {
  final Http _http = Http();

  // 统一认证登录（到时候替换成认证接口）
  Future<AuthResult> login({
    required String studentId,
    required String password,
  }) async {
    //ai跑的
    final resp = await _http.post('/users/login', data: {'email': studentId, 'password': password});
    final data = resp.data['data'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    _http.setToken(token);
    final user = await getMe();
    return AuthResult(user: user, token: token);
  }

  Future<User> getMe() async {
    final res = await _http.get('/users/me');
    final data = res.data['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  // 注册（接入时替换为真实接口）
  Future<void> register({
    required String studentId,
    required String password,
  }) async {
    // ai示例：
    // final resp = await _http.post('/auth/register', body: {'studentId': studentId, 'password': password});
    // if (resp.statusCode != 200) throw Exception('注册失败：${resp.body}');
    await Future.delayed(const Duration(milliseconds: 600)); // 模拟网络
  }
}
