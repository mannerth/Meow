import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/model/user.dart';
import 'login_page.dart'; // 登录页

//用户个人页面
class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    //游客模式
    if (user == null || user.roleType == RoleType.guest) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F3EF),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // 清空登录状态并跳回登录页（用pushAndRemoveUntil防止堆栈连环跳转）
              ref.read(authStateProvider.notifier).clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              "前往登录",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      );
    }
    // ===== 登录用户个人页 =====
    // 返回刚写的大布局
    return _UserCenterDetailPage(user: user!);
  }
}

// 下面把详细界面模块化方便维护
class _UserCenterDetailPage extends StatelessWidget {
  final User user;
  const _UserCenterDetailPage({required this.user});

  @override
  Widget build(BuildContext context) {
    // 后续用真实数据
    final avatarUrl =
        user.avatar ?? "https://img2.imgtp.com/2024/04/25/Lsmw41KP.png";
    final nickname = user.nickname ?? "用户";
    final campus = user.campus ?? "未设置";
    final level = user.level;
    final levelTitle = user.levelTitle ?? '';
    final currency = user.currency;
    final feedCount = 0;
    final foundCatCount = 0;
    final receivedLikes = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 顶部区域
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 44, bottom: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE066),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$campus · 2022级本科",
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Color(0xFFFFC107),
                              size: 20,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Lv.$level $levelTitle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 编辑资料按钮
                Positioned(
                  top: 32,
                  right: 22,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit, size: 18, color: Colors.black87),
                    label: Text(
                      '编辑资料',
                      style: TextStyle(color: Colors.black87),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.yellow[800],
                      backgroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      shape: StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 三项数据（大卡片风格）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 3,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 25,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(label: "累计投喂", value: '$feedCount'),
                      _StatItem(label: "发现新猫", value: '$foundCatCount'),
                      _StatItem(label: "获得认可", value: '$receivedLikes'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 我的资产
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: Colors.black,
                elevation: 5,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 28,
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "小鱼干余额（积分）",
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currency',
                            style: const TextStyle(
                              color: Color(0xFFFFE066),
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.set_meal, color: Colors.white30, size: 42),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 我的服务 标题
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "我的服务",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            // 我的服务卡片区（2栏排列，分两行显示）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.assignment,
                      label: "领养申请",
                      desc: "查看进度",
                      badge: "新办",
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.emoji_events,
                      label: "荣誉勋章",
                      desc: "已点亮4枚",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 38),
            // 退出登录按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 52),
                  shape: StadiumBorder(),
                  backgroundColor: Colors.white,
                  elevation: 3,
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  // TODO: 退出登录逻辑
                },
                icon: Icon(Icons.logout, color: Colors.black87),
                label: Text(
                  '退出登录',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// 横排三个统计数字
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }
}

// "我的服务"组件
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final String? badge;

  final VoidCallback? onTap;
  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.desc,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 86,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.black54),
                  if (badge != null) ...[
                    SizedBox(width: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(desc, style: TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
