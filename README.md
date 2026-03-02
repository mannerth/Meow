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

寒假实训-猫猫图鉴 桌面图标、启动图标及项目自定义配置 1h
寒假实训-猫猫图鉴 每日签到功能开发，主页面挂载和AppLifecycleListener监听 2h
寒假实训-猫猫图鉴 通用组件猫咪列表开发，可跳转详情或返回猫咪，支持条件查询 4h
寒假实训-猫猫图鉴 猫咪详情页开发 3.5h
寒假实训-猫猫图鉴 管理端猫咪管理页，猫咪编辑页开发，可新建与修改猫咪 5h
寒假实训-猫猫图鉴 app向图床上传图片方法实现 1.5h
寒假实训-猫猫图鉴 管理端猫咪详情图片管理 2h
寒假实训-猫猫图鉴 发布猫咪动态功能实现 3h
寒假实训-猫猫图鉴 管理端用户管理、用户详情 2.5h
寒假实训-猫猫图鉴 用户首页开发，使用Sliver布局，控制整体滑动 2.5h
寒假实训-猫猫图鉴 猫咪排行榜实现 2h
寒假实训-猫猫图鉴 用户SOS上报功能 2.5h
寒假实训-猫猫图鉴 用户猫咪领养申请 2.5h
共计34h

寒假实训-猫猫图鉴 管理端首页 1.5h
寒假实训-猫猫图鉴 管理端处理SOS 3h
寒假实训-猫猫图鉴 管理端审批用户领养申请 3h