import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/cos_service.dart';
import 'package:meow/model/user.dart';

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository {
  final Http _http = Http();

  // 统一认证登录（返回 token，用户信息通过 getMe 获取）
  Future<AuthResult> login({
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    final path = isAdmin ? '/admin/login' : '/users/login';
    final resp = await _http.post(
      path,
      data: {'email': email, 'password': password},
    );

    final data = resp.data;
    final code = data is Map ? data['code'] : null;
    if (data is Map && (code == null || code == 0 || code == 200)) {
      final dataMap = (data['data'] as Map?) ?? {};
      final accessToken =
          dataMap['accessToken']?.toString() ??
          dataMap['token']?.toString() ??
          '';
      final refreshToken = dataMap['refreshToken']?.toString();
      if (accessToken.isNotEmpty) {
        _http.setToken(accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        _http.setRefreshToken(refreshToken);
      }

      User user = await getMe();
      if (isAdmin) {
        user.roleType = RoleType.admin;
      }
      return AuthResult(user: user, token: accessToken);
    }

    throw Exception(data is Map ? (data['msg'] ?? '未知错误') : '服务器异常');
  }

  static Future<User> getMe() async {
    try {
      final res = await Http().get('/users/me');
      final data = res.data['data'] as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      throw Exception("获取用户信息失败");
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

  // 签到成功返回 true，已经签到过了返回 false
  static Future<bool> dailyCheckIn() async {
    try {
      final res = await Http().post('/users/me/checkin');
      return !(res.data['data']['todayChecked'] as bool);
    } catch (e) {
      return false;
    }
  }

  // 更新用户信息；头像使用专用接口，避免把 COS key 混入资料更新请求。
  static Future<bool> updateUserInfo({
    String? nickname,
    Campus? campus,
    String? phone,
    String? wechat,
    XFile? avatar,
  }) async {
    try {
      if (avatar != null) {
        final keys = await CosUploadService.uploadImages([File(avatar.path)]);
        if (keys.isEmpty) return false;
        final avatarResponse = await Http().put(
          '/users/me/avatar',
          queryParameters: {'key': keys.first},
        );
        final avatarCode = avatarResponse.data['code'];
        if (avatarCode != 0 && avatarCode != 200) return false;
      }

      final payload = <String, dynamic>{
        'nickname': nickname ?? '',
        'campus': campus?.code ?? 0,
        'contact': {'wechat': wechat ?? '', 'phone': phone ?? ''},
      };

      final res = await Http().put('/users/me', data: payload);
      final code = res.data['code'];
      return code == 0 || code == 200;
    } catch (e) {
      return false;
    }
  }
}
