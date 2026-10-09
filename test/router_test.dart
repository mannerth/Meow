import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meow/api/http.dart';
import 'package:meow/main.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/router/app_routes.dart';
import 'package:meow/router/auth_guard.dart';
import 'package:meow/router/route.dart';
import 'package:meow/ui/page/common/edit_profile_page.dart';
import 'package:meow/ui/page/common/login_page.dart';
import 'package:meow/util/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client.dart';

User user(RoleType role) => User(
  id: role == RoleType.guest ? -1 : 7,
  studentId: '',
  nickname: '测试用户',
  roleType: role,
  currency: 3,
  level: 0,
  experience: 0,
  nextLevelExp: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('meow/browser_login');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final backend = FakeHttpOverrides();
  final originalOverrides = HttpOverrides.current;
  late ProviderContainer container;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Store().init();
  });

  setUp(() async {
    await Store().clear();
    Store().user = null;
    Http().clearToken();
    Http.hasInit = true;
    backend.requests.clear();
    backend.respond = (_) =>
        FakeHttpResponse(200, {'code': 200, 'msg': 'ok', 'data': []});
    HttpOverrides.global = backend;
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    HttpOverrides.global = originalOverrides;
    Store().user = null;
    Http().clearToken();
  });

  Future<GoRouter> showRouter(WidgetTester tester, String location) async {
    final router = container.read(appRouterProvider);
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  test('游客不是已登录用户；保护页检查登录，管理页同时检查角色', () {
    final guest = Auth(user: user(RoleType.guest));
    expect(guest.loggedIn, isFalse);
    for (final path in [
      AppRoutes.share,
      AppRoutes.sos,
      AppRoutes.notifications,
      AppRoutes.adoptionApply,
      AppRoutes.myAdoptions,
      AppRoutes.editProfile,
      AppRoutes.newCat,
      AppRoutes.adminCats,
      AppRoutes.createCat,
      AppRoutes.bindEmail,
    ]) {
      final uri = Uri.parse(authRedirect(guest, Uri.parse(path))!);
      expect(uri.path, AppRoutes.loginRequired);
      expect(uri.queryParameters['from'], path);
    }
    final student = Auth(user: user(RoleType.student));
    expect(
      authRedirect(student, Uri.parse(AppRoutes.adminUsers)),
      AppRoutes.forbidden,
    );
    for (final role in [RoleType.admin, RoleType.superAdmin]) {
      expect(
        authRedirect(Auth(user: user(role)), Uri.parse(AppRoutes.adminUsers)),
        isNull,
      );
    }
    expect(authRedirect(guest, Uri.parse(AppRoutes.catDetail('a/b'))), isNull);
    expect(authRedirect(guest, Uri.parse(AppRoutes.leaderboard)), isNull);
    expect(
      authRedirect(
        student,
        Uri.parse(AppRoutes.loginLocation(AppRoutes.editProfile)),
      ),
      AppRoutes.editProfile,
    );
    for (final invalid in [
      'https://example.com',
      '//example.com',
      '/login',
      '/login-required',
      'profile',
    ]) {
      expect(AppRoutes.safeReturnLocation(invalid), AppRoutes.home);
    }
  });

  testWidgets('游客访问保护页不发请求，去登录后恢复目标页面', (tester) async {
    container.read(authStateProvider.notifier).update(user(RoleType.guest), '');
    final router = await showRouter(tester, AppRoutes.editProfile);
    expect(find.text('未登录，请登录后使用此功能'), findsOneWidget);
    expect(find.byType(EditProfilePage), findsNothing);
    expect(backend.requests, isEmpty);
    await tester.tap(find.text('去登录'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      AppRoutes.editProfile,
    );
    container
        .read(authStateProvider.notifier)
        .update(user(RoleType.student), 'test-access');
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.editProfile,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('页面内操作提示未登录，取消登录可以继续浏览', (tester) async {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  if (requireLogin(context)) fail('游客操作不应执行');
                },
                child: const Text('投喂'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('登录页面')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('投喂'));
    await tester.pumpAndSettle();
    expect(find.text('未登录，请登录后再进行此操作'), findsOneWidget);
    expect(backend.requests, isEmpty);
    await tester.tap(find.text('去登录'));
    await tester.pumpAndSettle();
    expect(find.text('登录页面'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('投喂'), findsOneWidget);
  });

  testWidgets('鉴权失效只显示一个提示并清理凭证，退出后无法返回保护页', (tester) async {
    container
        .read(authStateProvider.notifier)
        .update(user(RoleType.student), 'test-access');
    await Store().setString('roleType', RoleType.student.toString());
    final router = await showRouter(tester, AppRoutes.editProfile);
    backend.respond = (_) =>
        FakeHttpResponse(401, {'code': 401, 'msg': '登录已过期'});
    await tester.runAsync(() async {
      await Future.wait([
        Http().get('/users/me'),
        Http().get('/notifications'),
      ]);
    });
    await tester.pumpAndSettle();
    expect(find.text('登录状态已过期，请重新登录'), findsOneWidget);
    expect(container.read(authStateProvider).loggedIn, isFalse);
    expect(Store().user, isNull);
    expect(Store().accessToken, isNull);
    expect(Store().refreshToken, isNull);
    expect(Store().getString('roleType'), isNull);
    expect(router.canPop(), isFalse);
    expect(find.byType(EditProfilePage), findsNothing);
    await tester.tap(find.text('去登录'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      AppRoutes.editProfile,
    );
  });

  testWidgets('普通权限不足不注销登录；刷新成功只重试一次', (tester) async {
    container
        .read(authStateProvider.notifier)
        .update(user(RoleType.student), 'test-access');
    await showRouter(tester, AppRoutes.editProfile);
    backend.respond = (_) =>
        FakeHttpResponse(403, {'code': 403, 'msg': '权限不足'});
    await tester.runAsync(() => Http().get('/admin/users'));
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).loggedIn, isTrue);
    expect(find.byType(EditProfilePage), findsOneWidget);
    Http().setRefreshToken('test-refresh');
    backend.requests.clear();
    backend.respond = (request) {
      if (request.uri.path == '/api/users/refresh') {
        return FakeHttpResponse(200, {
          'data': {
            'accessToken': 'test-new-access',
            'refreshToken': 'test-new-refresh',
          },
        });
      }
      return request.authorization == 'Bearer test-new-access'
          ? FakeHttpResponse(200, {'code': 200, 'msg': 'ok', 'data': {}})
          : FakeHttpResponse(401, {'msg': '登录已过期'});
    };
    await tester.runAsync(() => Http().get('/users/me'));
    await tester.pumpAndSettle();
    expect(backend.requests, hasLength(3));
    expect(Http().token, 'test-new-access');
    container.read(authStateProvider.notifier).decrementCurrency(1);
    expect(Http().token, 'test-new-access');
    expect(container.read(authStateProvider).loggedIn, isTrue);
    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('刷新后的请求仍返回401时停止重试并提示重新登录', (tester) async {
    container
        .read(authStateProvider.notifier)
        .update(user(RoleType.student), 'test-access');
    Http().setRefreshToken('test-refresh');
    final router = await showRouter(tester, AppRoutes.editProfile);
    backend.respond = (request) => request.uri.path == '/api/users/refresh'
        ? FakeHttpResponse(200, {
            'data': {
              'accessToken': 'test-new-access',
              'refreshToken': 'test-new-refresh',
            },
          })
        : FakeHttpResponse(401, {'msg': 'Unauthorized'});
    await tester.runAsync(() => Http().get('/users/me'));
    await tester.pumpAndSettle();
    expect(backend.requests, hasLength(3));
    expect(container.read(authStateProvider).loggedIn, isFalse);
    expect(Http().token, isNull);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.loginRequired,
    );
    expect(find.text('登录状态已过期，请重新登录'), findsOneWidget);
  });

  testWidgets('退出选猫页面后到达的网络响应不会更新已销毁页面', (tester) async {
    final router = await showRouter(tester, AppRoutes.profile);
    final reply = Completer<FakeHttpResponse>();
    backend.respond = (request) => request.uri.path == '/api/cats'
        ? reply.future
        : FakeHttpResponse(200, {'code': 200, 'msg': 'ok', 'data': []});
    final selection = router.push<Cat>('${AppRoutes.selectCat}?select=true');
    await tester.pump();
    router.pop();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      reply.complete(
        FakeHttpResponse(200, {
          'code': 200,
          'msg': 'ok',
          'data': {'items': []},
        }),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(await selection, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('猫咪详情允许游客浏览，投喂和点赞都在请求前拦截', (tester) async {
    backend.respond = (request) {
      final data = switch (request.uri.path) {
        '/api/cats/c1' => {'id': 'c1', 'name': '测试猫咪'},
        '/api/posts' => {
          'items': [
            {'id': 'p1', 'content': '测试动态', 'likeCount': 2},
          ],
        },
        _ => [],
      };
      return FakeHttpResponse(200, {'code': 200, 'msg': 'ok', 'data': data});
    };
    await showRouter(tester, AppRoutes.catDetail('c1'));
    expect(find.text('测试猫咪'), findsOneWidget);
    await tester.tap(find.text('投喂'));
    await tester.pumpAndSettle();
    expect(find.text('未登录，请登录后投喂猫咪'), findsOneWidget);
    // 关闭提示，让底部浮层不会遮挡动态的点赞按钮。
    ScaffoldMessenger.of(tester.element(find.text('投喂'))).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byIcon(Icons.favorite_border),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('未登录，请登录后再进行此操作'), findsOneWidget);
    expect(
      backend.requests.where((request) => request.method != 'GET'),
      isEmpty,
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('选择猫咪通过路由返回 Cat，取消选择返回空值', (tester) async {
    final router = await showRouter(tester, AppRoutes.profile);
    backend.respond = (request) => FakeHttpResponse(200, {
      'code': 200,
      'msg': 'ok',
      'data': request.uri.path == '/api/cats'
          ? {
              'items': [
                {'id': 'c1', 'name': '可选猫咪'},
              ],
            }
          : [],
    });
    final selection = router.push<Cat>('${AppRoutes.selectCat}?select=true');
    await tester.pumpAndSettle();
    await tester.tap(find.text('可选猫咪'));
    await tester.pumpAndSettle();
    expect((await selection)?.id, 'c1');
    final canceled = router.push<Cat>('${AppRoutes.selectCat}?select=true');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(await canceled, isNull);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.profile);
  });

  testWidgets('普通用户直接进入后台不会加载管理页面', (tester) async {
    container
        .read(authStateProvider.notifier)
        .update(user(RoleType.student), 'test-access');
    await showRouter(tester, AppRoutes.adminUsers);
    expect(find.text('权限不足，此页面仅限管理员访问'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('恢复已有会话时直接显示个人页面，没有登录页闪烁', (tester) async {
    Store().user = user(RoleType.student);
    await Store().setAccessToken('test-access');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialAuthProvider.overrideWithValue(Auth.fromStore())],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
