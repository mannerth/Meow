import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 在完整 Dio 请求链路中模拟后端，不给生产代码增加测试入口。
class FakeHttpOverrides extends HttpOverrides {
  final List<FakeHttpRequest> requests = [];
  late FutureOr<FakeHttpResponse> Function(FakeHttpRequest request) respond;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(this);
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.backend);

  final FakeHttpOverrides backend;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      FakeHttpRequest(backend, method, url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpRequest implements HttpClientRequest {
  FakeHttpRequest(this.backend, this.method, this.uri);

  final FakeHttpOverrides backend;
  @override
  final String method;
  @override
  final Uri uri;
  final List<int> _body = [];
  @override
  final headers = _FakeHttpHeaders();

  Object? get jsonBody => _body.isEmpty ? null : jsonDecode(utf8.decode(_body));
  String? get authorization => headers.value(HttpHeaders.authorizationHeader);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _body.addAll(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    backend.requests.add(this);
    return await backend.respond(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeHttpResponse(this.statusCode, Object? body)
    : _stream = Stream.value(utf8.encode(jsonEncode(body)));

  final Stream<List<int>> _stream;
  @override
  final int statusCode;
  @override
  String get reasonPhrase => 'Test response';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  HttpHeaders get headers =>
      _FakeHttpHeaders()
        ..set(HttpHeaders.contentTypeHeader, 'application/json');

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = [value.toString()];
  }

  @override
  String? value(String name) => _values[name.toLowerCase()]?.single;

  @override
  void forEach(void Function(String, List<String>) action) {
    _values.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
