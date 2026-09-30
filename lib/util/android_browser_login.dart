import 'package:flutter/services.dart';

class BrowserLoginResult {
  final String url;
  final bool isAdmin;

  const BrowserLoginResult({required this.url, required this.isAdmin});
}

/// Android uses the ordinary default browser with the existing meow:// callback.
class AndroidBrowserLogin {
  static const _channel = MethodChannel('meow/browser_login');

  static Future<BrowserLoginResult> authenticate({
    required String url,
    required bool isAdmin,
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'authenticate',
      {'url': url, 'isAdmin': isAdmin},
    );
    return _parseResult(result);
  }

  static Future<bool> hasPendingLogin() async =>
      await _channel.invokeMethod<bool>('hasPendingLogin') ?? false;

  static Future<BrowserLoginResult> resumeLogin() async => _parseResult(
    await _channel.invokeMapMethod<String, Object?>('resumeLogin'),
  );

  static Future<void> cancelLogin() => _channel.invokeMethod('cancelLogin');

  static Future<void> openDefaultBrowserSettings() =>
      _channel.invokeMethod('openDefaultBrowserSettings');

  static BrowserLoginResult _parseResult(Map<String, Object?>? result) {
    final url = result?['url'];
    final isAdmin = result?['isAdmin'];
    if (url is! String || isAdmin is! bool) {
      throw const FormatException('登录回调数据无效');
    }
    return BrowserLoginResult(url: url, isAdmin: isAdmin);
  }
}
