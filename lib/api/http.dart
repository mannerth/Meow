import 'package:dio/dio.dart';
import 'package:meow/util/store.dart';

// 网络请求封装，单例模式
class Http {
  static const String baseUrl = 'http://10.2.9.114:20202';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Dio实例
  late final Dio _dio;

  // 单例实例
  static final Http _instance = Http._internal();

  // token
  String? _token;
  String? get token => _token;
  void setToken(String token) {
    _token = token;
    Store().setString('token', token);
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
        responseHeader: true,
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
      if (!allowRetry) {
        return response;
      }
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse && allowRetry) {
        if (e.response?.statusCode == 401) {
          // TODO: refresh token，失败跳转登录
        }
        if (e.response?.statusCode != null &&
            (e.response!.statusCode! >= 500 ||
                e.response!.statusCode! == 401)) {
          // 重试请求
          return await _dio.request<T>(
            path,
            queryParameters: queryParameters,
            data: data,
            options:
                options?.copyWith(method: method) ?? Options(method: method),
            cancelToken: cancelToken,
          );
        }
        if (e.response != null) {
          return e.response as Response<T>;
        }
      }
    }
    throw Exception('Request failed');
  }
}