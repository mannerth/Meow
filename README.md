# Meow

猫猫图鉴

(在预览模式下看这个文件)

启动虚拟机，在调试里用第一个配置运行。

<hr/>

git的话咱俩就不用那么规范了，直接在main分支上提交就行，只需要确保提交时项目是可运行的。提交信息写清本次做了什么即可。

我在空白代码的基础上拉了一个练习分支exercise你可以随便玩。

<hr/>

添加新导航项：只需在 NavigationConfigRegistry.allConfigs 中添加配置
```Dart
static final _newConfig = NavigationItemConfig(
  itemData: CustomNavigationItemData(
    label: '新功能',
    icon: Icon(Icons.new_releases),
    activeIcon: Icon(Icons.new_releases),
  ),
  pageBuilder: (_) => const NewPage(),
  allowedRoles: {RoleType.student, RoleType.admin}, // 权限控制
);
```

角色权限控制：

allowedRoles: null → 所有角色可见
allowedRoles: {RoleType.admin} → 仅管理员可见
allowedRoles: {RoleType.student, RoleType.admin} → 学生和管理员可见

<hr/>

代码生成命令：
```bash
dart run build_runner build --delete-conflicting-outputs
```
https://docs.flutter.cn/data-and-backend/serialization/json

| description | time cost | author |
|-------------|-----------|--------|
|山大统一认证登录适配 | 2.5h | manenrth|
