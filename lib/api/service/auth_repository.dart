import 'dart:convert';
import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository {
  final Http _http = Http();

  // 登录
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final resp = await _http.post(
      "/users/login",
      data: {"email": email, "password": password},
    );
    final data = resp.data;
    final code = data["code"];
    if (data is Map && (code == 0 || code == 200)) {
      final dataMap = (data["data"] as Map?) ?? {};
      final accessToken = dataMap["accessToken"]?.toString() ?? "";

      final userJson = {
        "id": dataMap["id"] ?? "",
        "studentId": dataMap["studentId"] ?? "",
        "nickname": dataMap["nickname"],
        "realName": dataMap["realName"],
        "avatar": dataMap["avatar"],
        "roleType": "student",
        "campus": dataMap["campus"],
        "currency": dataMap["currency"] ?? 0,
        "level": dataMap["level"] ?? 0,
        "levelTitle": dataMap["levelTitle"],
        "experience": dataMap["experience"] ?? 0,
        "nextLevelExp": dataMap["nextLevelExp"] ?? 0,
        "createTime": dataMap["createTime"] ?? DateTime.now().toIso8601String(),
        "wechat": dataMap["wechat"],
        "phone": dataMap["phone"],
        "showBadge": dataMap["showBadge"],
        "pushNotification": dataMap["pushNotification"],
      };
      final user = User.fromJson(userJson);
      return AuthResult(user: user, token: accessToken);
    } else {
      throw Exception(data is Map ? (data["msg"] ?? "未知错误") : "服务器异常");
    }
  }

  // 发送邮箱验证码
  Future<void> sendVerificationCode(String email) async {
    final resp = await _http.post(
      "/users/send-verification-code",
      data: {"email": email},
    );
    final code = resp.data["code"];
    if (!(code == 0 || code == 200)) {
      throw Exception(resp.data["msg"] ?? "发送验证码失败");
    }
  }

  // 注册
  Future<void> register({
    required String email,
    required String password,
    required String code,
  }) async {
    final resp = await _http.post(
      "/users/register",
      data: {"email": email, "password": password, "code": code},
    );
    final resultCode = resp.data["code"];
    if (!(resultCode == 0 || resultCode == 200)) {
      throw Exception(resp.data["msg"] ?? "注册失败");
    }
  }
}
