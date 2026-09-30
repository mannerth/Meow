import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/Urls.dart';
import 'package:meow/ui/page/common/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('meow/browser_login');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> showLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
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
}
