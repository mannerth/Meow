import 'package:flutter/material.dart';
import 'package:meow/router/auth_guard.dart';
import 'package:meow/ui/widget/adaptive/adaptive_scaffold.dart';
import 'package:meow/ui/widget/community_qrcode_dialog.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _background = Color(0xFFF8F6F3);
  static const _textColor = Color(0xFF17202B);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '开发团队',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
          child: IconButton.filled(
            tooltip: '返回',
            onPressed: () => popOrHome(context),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF586474)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          const _AppIntroduction(),
          const SizedBox(height: 24),
          _AboutCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const CommunityQrCodeDialog(),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '联系我们',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Color(0xFF999999)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _AboutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '开发团队',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '学生在线（软件园校区）',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),
                // Text(
                //   '开发部门（学生在线）。',
                //   style: TextStyle(
                //     color: Color(0xFF727272),
                //     fontSize: 14,
                //     height: 1.7,
                //   ),
                // ),
                // SizedBox(height: 10),
                Text(
                  '来学生在线，和有意思的人，发现更精彩的自己。',
                  style: TextStyle(
                    color: Color(0xFF727272),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _AboutCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Color(0xFFFF6B72), size: 18),
                    SizedBox(width: 5),
                    Text(
                      '特别感谢',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  '感谢每一位为校园猫咪救助与领养事业付出努力的同学、志愿者与铲屎官们。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '猫猫图鉴 · 守护每一只喵',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFC2C2C2), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIntroduction extends StatelessWidget {
  const _AppIntroduction();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD94C), Color(0xFFFFBA00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC222).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Container(
              width: constraints.maxWidth < 320 ? 96 : 116,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE796),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/猫猫图鉴 黄底 无字.png'),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '猫猫图鉴',
                    style: TextStyle(
                      color: Color(0xFF543600),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '校园猫咪管理平台',
                    style: TextStyle(color: Color(0xFF6E4B00), fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '建立校园流浪猫电子档案，普及科学喂养，提升救助效率，让每一份善意都有迹可循。',
                    style: TextStyle(
                      color: Color(0xFF896300),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}
