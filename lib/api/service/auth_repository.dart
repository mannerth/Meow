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
    // final resp = await _http.post('/auth/login', body: {'studentId': studentId, 'password': password});
    // final data = json.decode(resp.body) as Map<String, dynamic>;
    // final token = data['token'] as String;
    // final user = User.fromJson(data['user'] as Map<String, dynamic>);
    // return AuthResult(user: user, token: token);

    // 模拟成功
    final now = DateTime.now();
    final user = User(
      id: 'u-$studentId',
      studentId: studentId,
      nickname: '同学',
      avatar: null,
      roleType: RoleType.student,
      campus: '中心校区',
      currency: 0,
      level: 1,
      levelTitle: '新生',
      experience: 0,
      nextLevelExp: 10,
      createTime: now,
    );
    return AuthResult(user: user, token: 'mock-token-$studentId');
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
