import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/router/app_routes.dart';

/// 页面内的受保护操作使用同一提示，确认登录后由路由恢复原页面。
bool requireLogin(BuildContext context, {String? message}) {
  final auth = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(authStateProvider);
  if (auth.loggedIn) return true;
  final router = GoRouter.of(context);
  final from = router.routeInformationProvider.value.uri.toString();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message ?? '未登录，请登录后再进行此操作'),
      action: SnackBarAction(
        label: '去登录',
        onPressed: () => router.push(AppRoutes.loginLocation(from)),
      ),
    ),
  );
  return false;
}

void popOrHome(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(AppRoutes.home);
  }
}

class LoginRequiredPage extends StatelessWidget {
  const LoginRequiredPage({
    super.key,
    required this.from,
    this.expired = false,
  });
  final String from;
  final bool expired;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('需要登录'),
      leading: BackButton(onPressed: () => popOrHome(context)),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 16),
          Text(expired ? '登录状态已过期，请重新登录' : '未登录，请登录后使用此功能'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                context.go(AppRoutes.loginLocation(from, expired: expired)),
            child: const Text('去登录'),
          ),
          TextButton(
            onPressed: () => popOrHome(context),
            child: const Text('返回浏览'),
          ),
        ],
      ),
    ),
  );
}

class RouteMessagePage extends StatelessWidget {
  const RouteMessagePage({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('提示')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('返回首页'),
          ),
        ],
      ),
    ),
  );
}

/// 缓存的导航分支也监听权限，退出登录后立即销毁受保护页面和草稿。
class ProtectedRoute extends ConsumerWidget {
  const ProtectedRoute({
    super.key,
    required this.location,
    required this.builder,
  });
  final String location;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (AppRoutes.requiresLogin(location) && !auth.loggedIn) {
      return LoginRequiredPage(from: location);
    }
    if (AppRoutes.requiresAdmin(location) && !auth.role.isAdmin) {
      return const RouteMessagePage(message: '权限不足，此页面仅限管理员访问');
    }
    return builder(context);
  }
}
