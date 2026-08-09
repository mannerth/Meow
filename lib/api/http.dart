import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meow/main.dart';
import 'package:meow/ui/page/common/login_page.dart';
import 'package:meow/util/store.dart';

// 网络请求封装，单例模式
class Http {
  static const String baseUrl = 'https://meow.sduonline.cn';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static bool hasInit = false;

  // Dio实例
  late final Dio _dio;

  // 单例实例
  static final Http _instance = Http._internal();

  // token
  String? _token;
  String? _refreshToken;
  String? get token => _token;

  void setToken(String token) {
    _token = token;
    Store().setString('token', token);
  }

  void setRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    Store().setString('refreshToken', refreshToken);
  }

  void setTokens(String token, String refreshToken) {
    setToken(token);
    setRefreshToken(refreshToken);
  }

  void clearToken() {
    _token = null;
    _refreshToken = null;
    Store().remove('token');
    Store().remove('refreshToken');
  }

  // 私有化构造函数
  Http._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
    _setupInterceptors();
  }

  // 工厂构造函数，获取实例
  factory Http() => _instance;

  // 设置拦截器
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 请求拦截器
          options.headers['Authorization'] = 'Bearer $_token';
          handler.next(options);
        },
        onResponse: (response, handler) {
          // 响应拦截器
          handler.next(response);
        },
        onError: (DioException e, handler) {
          // 错误拦截器
          handler.next(e);
        },
      ),
    );
    // 日志
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        //responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    return request<T>(
      path,
      method: 'POST',
      queryParameters: queryParameters,
      data: data,
      options: options,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    return request<T>(
      path,
      method: 'PUT',
      queryParameters: queryParameters,
      data: data,
      options: options,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    return request<T>(
      path,
      method: 'DELETE',
      queryParameters: queryParameters,
      data: data,
      options: options,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Response<T>> head<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    return request<T>(
      path,
      method: 'HEAD',
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    try {
      final Response<T> response = await _dio.request(
        path,
        queryParameters: queryParameters,
        data: data,
        options: options?.copyWith(method: method) ?? Options(method: method),
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      debugPrint(e.message);
      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        // 鉴权失效：尝试用 refreshToken 刷新后重试一次
        if ((statusCode == 401 || statusCode == 403) &&
            _isAuthFailure(e.response?.data) &&
            allowRetry) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              return await _dio.request<T>(
                path,
                queryParameters: queryParameters,
                data: data,
                options:
                    options?.copyWith(method: method) ??
                    Options(method: method),
                cancelToken: cancelToken,
              );
            } catch (e) {
              debugPrint('刷新后重试失败: $e');
            }
          }
        }
        if (hasInit && (statusCode == 401 || statusCode == 403)) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  LoginPage(popAfterLogin: true, showLoginExpired: true),
            ),
          );
        }
        if (statusCode != null &&
            (statusCode >= 500 || statusCode == 403) &&
            allowRetry &&
            data is! FormData) {
          try {
            // 重试请求
            return await _dio.request<T>(
              path,
              queryParameters: queryParameters,
              data: data,
              options:
                  options?.copyWith(method: method) ?? Options(method: method),
              cancelToken: cancelToken,
            );
          } catch (e) {
            throw Exception('Retry failed: $e');
          }
        }
        if (e.response != null) {
          return e.response as Response<T>;
        }
      }
    }
    throw Exception('Request failed');
  }

  /// 判断是否为 token 相关的鉴权失败（而非权限不足）
  bool _isAuthFailure(dynamic body) {
    if (body is Map) {
      final msg = body['msg']?.toString() ?? '';
      if (msg.contains('权限不足') || msg.contains('权限')) return false;
      if (msg.contains('token') ||
          msg.contains('Token') ||
          msg.contains('登录') ||
          msg.contains('过期') ||
          msg.contains('未提供') ||
          msg.contains('格式错误')) {
        return true;
      }
    }
    return false;
  }

  /// 使用 refreshToken 刷新 access token
  Future<bool> _tryRefresh() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await Dio().post(
        '$baseUrl/users/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refresh'}),
      );
      final body = res.data;
      if (body is Map) {
        final data = body['data'];
        if (data is Map) {
          final newAccess = data['accessToken']?.toString() ?? '';
          final newRefresh = data['refreshToken']?.toString() ?? '';
          if (newAccess.isNotEmpty) {
            _token = newAccess;
            if (newRefresh.isNotEmpty) _refreshToken = newRefresh;
            Store().setString('token', newAccess);
            if (newRefresh.isNotEmpty) {
              Store().setString('refreshToken', newRefresh);
            }
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('刷新 token 失败: $e');
    }
    return false;
  }
}
