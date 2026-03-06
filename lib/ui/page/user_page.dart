import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

//用户个人页面
class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    if (user == null || user.roleType == RoleType.guest) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F3EF),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
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
    return _UserCenterDetailPage(user: user);
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
    final campus = user.campus?.name ?? "未设置";
    final level = user.level;
    final levelTitle = user.levelTitle ?? '';
    final currency = user.currency;

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
                        "$campus · ${user.studentId.substring(0, 4)}级本科生",
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
                            const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFFFFC107),
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Lv.$level $levelTitle',
                              style: const TextStyle(
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
                    icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
                    label: const Text(
                      '编辑资料',
                      style: TextStyle(color: Colors.black87),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.yellow,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      shape: const StadiumBorder(),
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
                      _StatItem(label: "累计投喂", value: '${user.stats?.feedCount}'),
                      _StatItem(label: "发现新猫", value: '${user.stats?.found}'),
                      _StatItem(label: "发布动态", value: '${user.stats?.momentCount}'),
                      _StatItem(label: "动态获赞", value: '${user.stats?.receivedLikes}'),
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
                      const Text(
                        "小鱼干余额（积分）",
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
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
                          const Icon(
                            Icons.set_meal,
                            color: Colors.white30,
                            size: 42,
                          ),
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
                      onTap: () {
                        // TODO 查看我的领养申请
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
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
              child: Consumer(
                builder: (context, ref, _){
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.white,
                      elevation: 3,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      ref.read(authStateProvider.notifier).clear();
                    },
                    icon: const Icon(Icons.logout, color: Colors.black87),
                    label: const Text(
                      '退出登录',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
              )
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
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
          height: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(2, 2),
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
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
