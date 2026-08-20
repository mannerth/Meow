import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meow/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 本地存储，app启动时初始化，全局可用
class Store {
  static const _accessTokenKey = 'token';
  static const _refreshTokenKey = 'refreshToken';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  late final SharedPreferences _prefs;
  String? _accessToken;
  String? _refreshToken;
  User? user;

  static final Store _instance = Store._internal();
  Store._internal();
  factory Store() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }

  // 存储字符串
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  // 获取字符串
  String? getString(String key) {
    return _prefs.getString(key);
  }

  // 存储布尔值
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  // 获取布尔值
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // 存储整数
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  // 获取整数
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // 存储双精度浮点数
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  // 获取双精度浮点数
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // 删除键值对
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // 清空所有存储
  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
