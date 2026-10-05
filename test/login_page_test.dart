import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/Urls.dart';
import 'package:meow/api/http.dart';
import 'package:meow/main.dart' show navigatorKey;
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/common/login_page.dart';
import 'package:meow/util/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('meow/browser_login');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final backend = FakeHttpOverrides();
  final originalHttpOverrides = HttpOverrides.current;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Store().init();
    HttpOverrides.global = backend;
  });

  setUp(() {
    backend.requests.clear();
    backend.respond = (request) => throw StateError('未配置测试响应');
    Http.hasInit = true;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    Http().clearToken();
  });

  tearDownAll(() {
    HttpOverrides.global = originalHttpOverrides;
  });

  Future<void> showLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(navigatorKey: navigatorKey, home: const LoginPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Android 等待浏览器回调期间禁用重复登录，取消后可以重试',
    (tester) async {
      final reply = Completer<Map<String, Object>>();
      var launches = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'hasPendingLogin':
            return false;
          case 'authenticate':
            launches++;
            expect(call.arguments['url'], Urls.Auth);
            return reply.future;
          case 'cancelLogin':
            reply.completeError(PlatformException(code: 'CANCELED'));
            return null;
        }
        return null;
      });
      await showLogin(tester);
      await tester.tap(find.text('统一认证登录'));
      await tester.pump();
      expect(find.text('请在默认浏览器中完成登录'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('取消登录'));
      await tester.pumpAndSettle();
      expect(find.text('统一认证登录'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(launches, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    '未设置默认浏览器时提供系统设置入口',
    (tester) async {
      var openedSettings = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'hasPendingLogin':
            return false;
          case 'authenticate':
            throw PlatformException(
              code: 'NO_DEFAULT_BROWSER',
              message: '请先在系统设置中选择默认浏览器',
            );
          case 'openDefaultBrowserSettings':
            openedSettings = true;
            return null;
        }
        return null;
      });
      await showLogin(tester);
      await tester.tap(find.text('统一认证登录'));
      await tester.pumpAndSettle();
      expect(find.text('请先在系统设置中选择默认浏览器'), findsOneWidget);
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(openedSettings, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    '页面重建后恢复等待中的登录，并拒绝错误 scheme 回调',
    (tester) async {
      final reply = Completer<Map<String, Object>>();
      var resumed = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'hasPendingLogin':
            return true;
          case 'resumeLogin':
            resumed = true;
            return reply.future;
          case 'authenticate':
            fail('恢复登录时不应再次打开浏览器');
        }
        return null;
      });
      await showLogin(tester);
      await tester.pump();
      expect(resumed, isTrue);
      expect(find.text('取消登录'), findsOneWidget);
      reply.complete({
        'url': 'https://example.invalid/callback',
        'isAdmin': false,
      });
      await tester.pumpAndSettle();
      expect(find.text('登录回调数据无效，请重试'), findsOneWidget);
      expect(find.text('统一认证登录'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final isAdmin in [false, true]) {
    testWidgets(
      '${isAdmin ? '管理员恢复登录' : '普通用户登录'}通过 login_code 交换双 Token 并加载用户资料',
      (tester) async {
        const loginCode = 'test+code/=';
        backend.respond = (request) {
          if (request.uri.path == '/api/auth/exchange') {
            expect(request.method, 'POST');
            expect(request.jsonBody, {'loginCode': loginCode});
            expect(request.uri.query, isEmpty);
            expect(request.authorization, isNull);
            return FakeHttpResponse(200, {
              'code': 200,
              'data': {
                'accessToken': 'test-access',
                'refreshToken': 'test-refresh',
              },
            });
          }
          expect(request.uri.path, '/api/users/me');
          expect(request.method, 'GET');
          expect(request.authorization, 'Bearer test-access');
          return FakeHttpResponse(200, {
            'code': 200,
            'data': {'uid': 7, 'nickname': '测试账户', 'roleType': 0},
          });
        };
        Http().setTokens('test-old-access', 'test-old-refresh');
        final callback = Uri(
          scheme: 'meow',
          host: 'callback',
          queryParameters: {'login_code': loginCode},
        ).toString();
        messenger.setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'hasPendingLogin':
              return isAdmin;
            case 'authenticate':
              expect(call.arguments['url'], Urls.Auth);
              return {'url': callback, 'isAdmin': false};
            case 'resumeLogin':
              return {'url': callback, 'isAdmin': true};
          }
          return null;
        });
        await showLogin(tester);
        if (!isAdmin) await tester.tap(find.text('统一认证登录'));
        await tester.pumpAndSettle();

        final auth = ProviderScope.containerOf(
          tester.element(find.byType(LoginPage)),
        ).read(authStateProvider);
        expect(auth.user?.id, 7);
        expect(auth.role, isAdmin ? RoleType.admin : RoleType.student);
        expect(auth.token, 'test-access');
        expect(Http().token, 'test-access');
        expect(Store().accessToken, 'test-access');
        expect(Store().refreshToken, 'test-refresh');
        expect(Store().getString('roleType'), auth.role.toString());
        expect(backend.requests, hasLength(2));
        expect(find.byType(SnackBar), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  final invalidCallbacks = [
    'meow://callback',
    'meow://callback?login_code=',
    'meow://callback?login_code=%20%20',
    'meow://callback?login_code=one&login_code=two',
    'meow://callback?login_code=${'x' * 129}',
    'meow://callback?meow_token=test-access&meow_refresh_token=test-refresh',
  ];
  for (var i = 0; i < invalidCallbacks.length; i++) {
    testWidgets(
      '无效登录回调 ${i + 1} 不发送交换请求、不写入 Token',
      (tester) async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'hasPendingLogin') return false;
          return {'url': invalidCallbacks[i], 'isAdmin': false};
        });
        await showLogin(tester);
        await tester.tap(find.text('统一认证登录'));
        await tester.pumpAndSettle();
        expect(find.text('登录回调数据无效，请重试'), findsOneWidget);
        expect(backend.requests, isEmpty);
        expect(Http().token, isNull);
        expect(Store().accessToken, isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  final failedExchanges = [
    FakeHttpResponse(401, {'code': 401, 'msg': '登录凭证已过期'}),
    FakeHttpResponse(500, {'code': 500, 'msg': '服务错误'}),
    FakeHttpResponse(200, {'code': 400, 'msg': 'login_code 已使用'}),
    FakeHttpResponse(200, {
      'code': 200,
      'data': {'accessToken': 'test-incomplete'},
    }),
    FakeHttpResponse(200, {
      'code': 200,
      'data': {'accessToken': '', 'refreshToken': 'test-refresh'},
    }),
  ];
  for (var i = 0; i < failedExchanges.length; i++) {
    testWidgets(
      '交换失败 ${i + 1} 不重试或重复跳转登录、不覆盖已有 Token',
      (tester) async {
        Http().setTokens('test-old-access', 'test-old-refresh');
        backend.respond = (request) => failedExchanges[i];
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'hasPendingLogin') return false;
          return {
            'url': 'meow://callback?login_code=test-code',
            'isAdmin': false,
          };
        });
        await showLogin(tester);
        await tester.tap(find.text('统一认证登录'));
        await tester.pumpAndSettle();
        expect(find.text('登录凭证交换失败，请重新登录'), findsOneWidget);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(backend.requests, hasLength(1));
        expect(backend.requests.single.uri.path, '/api/auth/exchange');
        expect(backend.requests.single.authorization, isNull);
        expect(Http().token, 'test-old-access');
        expect(Store().accessToken, 'test-old-access');
        expect(Store().refreshToken, 'test-old-refresh');
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
