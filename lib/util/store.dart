import 'package:meow/api/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 本地存储，app启动时初始化，全局可用
class Store {
  late final SharedPreferences _prefs;

  static final Store _instance = Store._internal();
  Store._internal();
  factory Store() => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // 顺便加载token
    String? token = _prefs.getString('token');
    if (token != null) {
      Http().setToken(token);
    }
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
