import 'package:flutter/material.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/user_provider.dart';
import 'package:meow/ui/page/home_page.dart';
import 'package:meow/ui/page/share_page.dart';
import 'package:meow/ui/page/user_page.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_navigation_item.dart';
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
    final user = ref.watch(userStateProvider);
    return _getNavigationConfigs(user.roleType);
  }

  /// 根据角色获取导航配置
  List<NavigationItemConfig> _getNavigationConfigs(RoleType role) {
    // 获取该角色可见的配置
    final configs = NavigationConfigRegistry.getConfigsForRole(role);

    return configs;
  }
}

/// 导航项数据列表 Provider（仅数据，不含页面）
@riverpod
List<CustomNavigationItemData> navigationItemsData(Ref ref) {
  final List<NavigationItemConfig> configs = ref.watch(navigationItemsProvider);
  return configs.map((c) => c.itemData).toList();
}

/// 导航页面列表 Provider
@riverpod
List<Widget> navigationPages(Ref ref) {
  final List<NavigationItemConfig> configs = ref.watch(navigationItemsProvider);
  // 使用 Builder 延迟构建页面
  return configs.map((c) => Builder(builder: c.pageBuilder)).toList();
}