import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/adoption.dart';
import 'package:meow/model/notification.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/router/app_routes.dart';
import 'package:meow/router/auth_guard.dart';
import 'package:meow/ui/page/admin/admin_adoption_detail_page.dart';
import 'package:meow/ui/page/admin/admin_adoptions_page.dart';
import 'package:meow/ui/page/admin/admin_new_cat_page.dart';
import 'package:meow/ui/page/admin/admin_sos_page.dart';
import 'package:meow/ui/page/admin/announcement_edit_page.dart';
import 'package:meow/ui/page/admin/announcements_page.dart';
import 'package:meow/ui/page/admin/meow_edit_page.dart';
import 'package:meow/ui/page/admin/type_management_page.dart';
import 'package:meow/ui/page/common/about_page.dart';
import 'package:meow/ui/page/common/edit_profile_page.dart';
import 'package:meow/ui/page/common/login_page.dart';
import 'package:meow/ui/page/common/register_page.dart';
import 'package:meow/ui/page/common/set_password_page.dart';
import 'package:meow/ui/page/main_page.dart';
import 'package:meow/ui/page/user/adoption_apply_page.dart';
import 'package:meow/ui/page/user/cat_detail_page.dart';
import 'package:meow/ui/page/user/cat_select_page.dart';
import 'package:meow/ui/page/user/leaderboard_page.dart';
import 'package:meow/ui/page/user/new_cat_page.dart';
import 'package:meow/ui/page/user/notifications_page.dart';
import 'package:meow/ui/page/user/sos_page.dart';
import 'package:meow/ui/page/user/user_adoptions_page.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_config.dart';

/// Provider 生命周期内只创建一次，登录态变化刷新守卫而不重建导航栈。
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (_, _) => refresh.refresh());
  final router = GoRouter(
    initialLocation: ref.read(authStateProvider).user == null
        ? AppRoutes.login
        : AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authStateProvider), state.uri),
    errorBuilder: (_, _) => const RouteMessagePage(message: '页面不存在或参数无效'),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginPage(
          showLoginExpired: state.uri.queryParameters['expired'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.loginRequired,
        builder: (_, state) => LoginRequiredPage(
          from: AppRoutes.safeReturnLocation(state.uri.queryParameters['from']),
          expired: state.uri.queryParameters['expired'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (_, _) => const RouteMessagePage(message: '权限不足，此页面仅限管理员访问'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainPage(navigationShell: shell),
        branches: [
          for (final config in NavigationConfigRegistry.allConfigs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: config.routePath,
                  builder: (_, _) => ProtectedRoute(
                    location: config.routePath,
                    builder: config.pageBuilder,
                  ),
                ),
              ],
            ),
        ],
      ),
      _page(AppRoutes.about, (_, _) => const AboutPage()),
      _page(AppRoutes.leaderboard, (_, _) => const LeaderboardPage()),
      _page(
        AppRoutes.selectCat,
        (_, state) => CatSelectPage(
          selectable: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      _page(
        '/cats/:id',
        (_, state) => CatDetailPage(
          key: ValueKey(state.pathParameters['id']),
          catId: state.pathParameters['id']!,
        ),
      ),
      _page(AppRoutes.newCat, (_, _) => const NewCatPage()),
      _page(AppRoutes.sos, (_, _) => const SosPage()),
      _page(AppRoutes.adoptionApply, (_, _) => const AdoptionApplyPage()),
      _page(AppRoutes.myAdoptions, (_, _) => const UserAdoptionsPage()),
      _page(AppRoutes.notifications, (_, _) => const NotificationsPage()),
      _page(AppRoutes.editProfile, (_, _) => const EditProfilePage()),
      _page(AppRoutes.bindEmail, (_, _) => const RegisterPage()),
      _page(AppRoutes.setPassword, (_, state) {
        final args = state.extra;
        if (args is! SetPasswordArguments) {
          return const RouteMessagePage(message: '请先填写邮箱和验证码');
        }
        return SetPasswordPage(email: args.email, code: args.code);
      }),
      _page(AppRoutes.adminSos, (_, _) => const AdminSosPage()),
      _page(AppRoutes.adminNewCats, (_, _) => const AdminNewCatPage()),
      _page(AppRoutes.adminAdoptions, (_, _) => const AdminAdoptionsPage()),
      _page('/admin/adoptions/:id', (_, state) {
        final item = state.extra;
        if (item is! AdminAdoptionItem ||
            item.id != state.pathParameters['id']) {
          return const RouteMessagePage(message: '请从领养申请列表打开详情');
        }
        return AdminAdoptionDetailPage(item: item);
      }),
      _page(AppRoutes.createCat, (_, _) => const MeowEditPage()),
      _page(
        '/admin/cats/:id/edit',
        (_, state) => MeowEditPage(
          key: ValueKey(state.pathParameters['id']),
          catId: state.pathParameters['id']!,
        ),
      ),
      _page(AppRoutes.announcements, (_, _) => const AnnouncementsPage()),
      _page(
        AppRoutes.createAnnouncement,
        (_, _) => const AnnouncementEditPage(),
      ),
      _page('/admin/announcements/:id/edit', (_, state) {
        final id = state.pathParameters['id']!;
        final item = state.extra;
        return AnnouncementEditPage(
          key: ValueKey(id),
          announcementId: id,
          announcement: item is Announcement && item.id == id ? item : null,
        );
      }),
      _page(AppRoutes.types, (_, _) => const TypeManagementPage()),
    ],
  );

  void onExpired() {
    if (!ref.read(authStateProvider).loggedIn) return;
    final uri = router.routeInformationProvider.value.uri;
    final from = [AppRoutes.login, AppRoutes.loginRequired].contains(uri.path)
        ? AppRoutes.safeReturnLocation(uri.queryParameters['from'])
        : uri.toString();
    ref.read(authStateProvider.notifier).clear();
    router.go(AppRoutes.requiredLocation(from, expired: true));
  }

  Http().onAuthenticationExpired = onExpired;
  ref.onDispose(() {
    if (Http().onAuthenticationExpired == onExpired) {
      Http().onAuthenticationExpired = null;
    }
    router.dispose();
    refresh.dispose();
  });
  return router;
});

GoRoute _page(String path, GoRouterWidgetBuilder builder) => GoRoute(
  path: path,
  builder: (context, state) => ProtectedRoute(
    location: state.uri.path,
    builder: (context) => builder(context, state),
  ),
);

String? authRedirect(Auth auth, Uri uri) {
  final path = uri.path;
  if ([AppRoutes.login, AppRoutes.loginRequired].contains(path) &&
      auth.loggedIn) {
    return AppRoutes.safeReturnLocation(uri.queryParameters['from']);
  }
  if (AppRoutes.requiresLogin(path) && !auth.loggedIn) {
    return AppRoutes.requiredLocation(uri.toString());
  }
  if (AppRoutes.requiresAdmin(path) && !auth.role.isAdmin) {
    return AppRoutes.forbidden;
  }
  return null;
}

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
