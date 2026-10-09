import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_items_provider.g.dart';

/// 导航项配置 Provider
/// 根据用户角色自动计算可见的导航项
@riverpod
class NavigationItems extends _$NavigationItems {
  @override
  List<NavigationItemConfig> build() {
    // 监听用户状态变化，自动重新计算导航项
    final auth = ref.watch(authStateProvider);
    return _getNavigationConfigs(auth.role);
  }

  /// 根据角色获取导航配置
  List<NavigationItemConfig> _getNavigationConfigs(RoleType role) {
    // 获取该角色可见的配置
    final configs = NavigationConfigRegistry.getConfigsForRole(role);

    return configs;
  }
}
