# Meow

猫猫图鉴

(在预览模式下看这个文件)

启动虚拟机，在调试里用第一个配置运行。

如果运行不起来，提示网络问题的话，在开启代理的情况下，把[/android/gradle.properties](/android/gradle.properties)里的注释取消掉。咱们用的一个软件，端口应该是一样的。可以从设置里看一眼：
![clash_verge_settings](/assets/images/clash_verge_settrings.png)
不行就和我说
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