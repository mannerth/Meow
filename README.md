# Meow

猫猫图鉴

添加新导航项：只需在 NavigationConfigRegistry.allConfigs 中添加配置
```Dart
static final _newConfig = NavigationItemConfig(
  itemData: CustomNavigationItemData(
    label: '新功能',
    icon: Icon(Icons.new_releases),
    activeIcon: Icon(Icons.new_releases),
  ),
  routePath: '/new-feature', // 同步在 AppRoutes 中定义地址及权限
  pageBuilder: (_) => const NewPage(),
  allowedRoles: {RoleType.student, RoleType.admin}, // 权限控制
);
```

角色权限控制：

allowedRoles: null → 所有角色可见
allowedRoles: {RoleType.admin} → 仅管理员可见
allowedRoles: {RoleType.student, RoleType.admin} → 学生和管理员可见

页面路由统一在 `lib/router/route.dart` 中注册，地址与访问权限在 `lib/router/app_routes.dart` 中定义。
普通页面使用 `context.push`，导航分支使用 `goBranch` / `context.go`；弹窗和底部选择框继续使用 `Navigator.pop` 返回结果。
未登录访问受保护页面会显示“去登录”，认证成功后回到目标页面。投喂、点赞等页面内操作使用 `requireLogin` 拦截。
游客不视为已登录；管理员页面同时检查登录状态与角色。退出登录清除凭证和导航栈。

<hr/>

代码生成命令：
```bash
dart run build_runner build --delete-conflicting-outputs
```
https://docs.flutter.cn/data-and-backend/serialization/json

