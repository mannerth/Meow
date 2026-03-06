import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository {
  final Http _http = Http();

  // 统一认证登录（到时候替换成认证接口）
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
      final accessToken = dataMap['accessToken']?.toString() ??
          dataMap['token']?.toString() ??
          '';
      if (accessToken.isNotEmpty) {
        _http.setToken(accessToken);
      }

      User user;
      if (dataMap.containsKey('id') ||
          dataMap.containsKey('uid') ||
          dataMap.containsKey('sid')) {
        final userJson = {
          'uid': dataMap['uid'] ?? dataMap['id'] ?? 0,
          'sid': dataMap['sid'] ?? dataMap['studentId'] ?? '',
          'nickname': dataMap['nickname'],
          'realName': dataMap['realName'],
          'avatar': dataMap['avatar'],
          'roleType': dataMap['roleType'] ?? 'student',
          'campus': dataMap['campus'],
          'currency': dataMap['currency'] ?? 0,
          'level': dataMap['level'] ?? 0,
          'levelTitle': dataMap['levelTitle'],
          'exp': dataMap['experience'] ?? dataMap['exp'] ?? 0,
          'nextExp': dataMap['nextLevelExp'] ?? dataMap['nextExp'] ?? 0,
          'createTime': dataMap['createTime'],
          'wechat': dataMap['wechat'],
          'phone': dataMap['phone'],
          'showBadge': dataMap['showBadge'],
          'pushNotification': dataMap['pushNotification'],
        };
        user = User.fromJson(userJson);
      } else {
        user = await getMe();
      }

      if (isAdmin) {
        user.roleType = RoleType.admin;
      }
      return AuthResult(user: user, token: accessToken);
    }

    throw Exception(data is Map ? (data['msg'] ?? '未知错误') : '服务器异常');
  }

  static Future<User> getMe() async {
    final res = await Http().get('/users/me');
    final data = res.data['data'] as Map<String, dynamic>;
    return User.fromJson(data);
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
    final res = await Http().post('/users/me/checkin');
    return !(res.data['data']['todayChecked'] as bool);
  }

  static Future<bool> updateUserInfo({
    String? nickname,
    String? campus,
    String? phone,
    String? wechat,
    XFile? avatar,
  }) async {
    final formData = FormData();
    if (nickname != null) formData.fields.add(MapEntry('nickname', nickname));
    if (campus != null) formData.fields.add(MapEntry('campus', campus));
    if (phone != null) formData.fields.add(MapEntry('phone', phone));
    if (wechat != null) formData.fields.add(MapEntry('wechat', wechat));
    if (avatar != null) {
      formData.files.add(MapEntry(
        'avatar',
        MultipartFile.fromFileSync(avatar.path, filename: avatar.name),
      ));
    }

    final res = await Http().put('/users/me', data: formData);
    final code = res.data['code'];
    if (!(code == 0 || code == 200)) {
      return false;
    }

    return true;
  }

  /**
   * 
nickname string  必需 示例: y
campus string 可选
phone string 可选
wechat string 可选
avatar file 可选 示例:
file://D:\灵感库\PixPin_2025-12-07_22-21-04.png
   */
}
