import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/page/home_page.dart';
import 'package:meow/ui/page/meow_page.dart';
import 'package:meow/ui/page/share_page.dart';
import 'package:meow/ui/page/static_page.dart';
import 'package:meow/ui/page/user_page.dart';
import 'package:meow/ui/page/users_page.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_navigation_item.dart';

/// 导航项配置
/// 将导航项数据和对应页面绑定在一起
class NavigationItemConfig {
  /// 导航项数据（图标、标签、背景色等）
  final CustomNavigationItemData itemData;

  /// 对应的页面构建器
  final WidgetBuilder pageBuilder;

  /// 需要的最低权限角色（可选，用于权限过滤）
  final Set<RoleType>? allowedRoles;

  const NavigationItemConfig({
    required this.itemData,
    required this.pageBuilder,
    this.allowedRoles,
  });

  /// 检查当前角色是否有权限访问
  bool isAllowedFor(RoleType role) {
    if (allowedRoles == null) return true;
    return allowedRoles!.contains(role);
  }
}

/// 导航配置注册表
/// 集中管理所有导航项，便于维护和扩展
class NavigationConfigRegistry {
  NavigationConfigRegistry._();

  /// 所有可用的导航项配置
  /// 按显示顺序排列，新增导航项只需在此添加
  static List<NavigationItemConfig> get allConfigs => [
        _staticConfig,
        _meowConfig,
        _homeConfig,
        _shareConfig,
        _adminConfig,
        _userConfig,
      ];

  // ========== 管理员统计页 =======
  static final _staticConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '统计',
      icon: SvgPicture.asset(
        'assets/icons/table-cells.svg',
        width: 24,
        height: 24,
      ),
    ),
    pageBuilder: (_) => StaticPage(),
    allowedRoles: {RoleType.admin},
  );

  static final _meowConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '猫咪',
      icon: SvgPicture.asset('assets/icons/paw.svg', width: 24, height: 24),
    ),
    pageBuilder: (_) => MeowPage(),
    allowedRoles: {RoleType.admin},
  );

  // ============ 首页 ============
  static final _homeConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '首页',
      icon: SvgPicture.asset('assets/icons/home.svg', width: 24, height: 24),
      activeIcon: SvgPicture.asset(
        'assets/icons/home-selected.svg',
        width: 24,
        height: 24,
      ),
      activeBackgroundColor: Colors.blue.withValues(alpha: 0.15),
    ),
    pageBuilder: (_) => const HomePage(),
    // 所有角色都可见
    allowedRoles: null,
  );

  // ============ 发布 ============
  static final _shareConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '发布',
      icon: SvgPicture.asset('assets/icons/share.svg', width: 24, height: 24),
      activeIcon: SvgPicture.asset(
        'assets/icons/share-selected.svg',
        width: 24,
        height: 24,
      ),
      activeBackgroundColor: Colors.green.withValues(alpha: 0.15),
    ),
    pageBuilder: (_) => SharePage(),
    // 仅学生和管理员可见
    allowedRoles: {RoleType.student, RoleType.admin},
  );

  // ============ 用户管理 ============
  static final _adminConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '管理',
      icon: SvgPicture.asset('assets/icons/users.svg', width: 24, height: 24),
      activeIcon: SvgPicture.asset(
        'assets/icons/users.svg',
        width: 24,
        height: 24,
      ),
      activeBackgroundColor: Colors.orange.withValues(alpha: 0.15),
    ),
    pageBuilder: (_) => UsersPage(),
    // 仅管理员可见
    allowedRoles: {RoleType.admin},
  );

  // ============ 我的 ============
  static final _userConfig = NavigationItemConfig(
    itemData: CustomNavigationItemData(
      label: '我的',
      icon: SvgPicture.asset('assets/icons/user.svg', width: 24, height: 24),
      activeIcon: SvgPicture.asset(
        'assets/icons/user-selected.svg',
        width: 24,
        height: 24,
      ),
      activeBackgroundColor: Colors.purple.withValues(alpha: 0.15),
    ),
    pageBuilder: (_) => UserPage(),
    // 所有角色都可见
    allowedRoles: null,
  );

  /// 根据用户角色获取可见的导航项配置
  static List<NavigationItemConfig> getConfigsForRole(RoleType role) {
    return allConfigs.where((config) => config.isAllowedFor(role)).toList();
  }
}
