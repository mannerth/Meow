/// 页面地址集中定义；动态 ID 使用 URI 编码，避免破坏路径结构。
abstract final class AppRoutes {
  static const login = '/login';
  static const loginRequired = '/login-required';
  static const forbidden = '/forbidden';
  static const home = '/home';
  static const share = '/share';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const about = '/about';
  static const leaderboard = '/leaderboard';
  static const selectCat = '/cats/select';
  static const newCat = '/new-cat';
  static const sos = '/sos';
  static const adoptionApply = '/adoptions/apply';
  static const myAdoptions = '/adoptions/my';
  static const notifications = '/notifications';
  static const bindEmail = '/account/bind-email';
  static const setPassword = '/account/set-password';
  static const adminStats = '/admin/stats';
  static const adminCats = '/admin/cats';
  static const createCat = '/admin/cats/new';
  static const adminUsers = '/admin/users';
  static const adminSos = '/admin/sos';
  static const adminNewCats = '/admin/new-cats';
  static const adminAdoptions = '/admin/adoptions';
  static const announcements = '/admin/announcements';
  static const createAnnouncement = '/admin/announcements/new';
  static const types = '/admin/types';

  static String catDetail(String id) => '/cats/${Uri.encodeComponent(id)}';
  static String editCat(String id) =>
      '/admin/cats/${Uri.encodeComponent(id)}/edit';
  static String editAnnouncement(String id) =>
      '/admin/announcements/${Uri.encodeComponent(id)}/edit';
  static String adminAdoptionDetail(String id) =>
      '/admin/adoptions/${Uri.encodeComponent(id)}';

  static bool requiresLogin(String path) =>
      path == share ||
      path == editProfile ||
      path == newCat ||
      path == sos ||
      path == adoptionApply ||
      path == myAdoptions ||
      path == notifications ||
      path.startsWith('/account/') ||
      requiresAdmin(path);

  static bool requiresAdmin(String path) => path.startsWith('/admin/');

  static String loginLocation(String from, {bool expired = false}) => Uri(
    path: login,
    queryParameters: {'from': from, if (expired) 'expired': 'true'},
  ).toString();

  static String requiredLocation(String from, {bool expired = false}) => Uri(
    path: loginRequired,
    queryParameters: {'from': from, if (expired) 'expired': 'true'},
  ).toString();

  /// 只接受应用内地址，禁止外部地址及认证页循环跳转。
  static String safeReturnLocation(String? location) {
    final uri = location == null ? null : Uri.tryParse(location);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !uri.path.startsWith('/') ||
        uri.path == '/' ||
        [login, loginRequired, forbidden].contains(uri.path)) {
      return home;
    }
    return uri.toString();
  }
}

/// 邮箱与验证码仅通过内存传递，不写入 URL 或路由日志。
class SetPasswordArguments {
  const SetPasswordArguments({required this.email, required this.code});
  final String email;
  final String code;
}
