import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'campus.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nicknameCtrl;
  late TextEditingController _wechatCtrl;
  late TextEditingController _phoneCtrl;
  late User user;
  String? campus;

  bool showBadge = true;
  bool pushNotification = true;

  @override
  void initState() {
    super.initState();
    user = ref.read(authStateProvider).user!;
    campus = user.campus;
    _nicknameCtrl = TextEditingController(text: user.nickname ?? "");
    _wechatCtrl = TextEditingController(text: user.wechat ?? "");
    _phoneCtrl = TextEditingController(text: user.phone ?? "");
    //user字段调整
    showBadge = user.showBadge ?? true;
    pushNotification = user.pushNotification ?? true;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _wechatCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _pickCampus() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView(
          children: campusList.map((campusName) {
            return ListTile(
              title: Text(campusName),
              trailing: campus == campusName
                  ? Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(context, campusName),
            );
          }).toList(),
        );
      },
    );
    if (selected != null && selected != campus) {
      setState(() {
        campus = selected;
      });
    }
  }

  void _save() {
    final newUser = user.copyWith(
      nickname: _nicknameCtrl.text,
      wechat: _wechatCtrl.text,
      phone: _phoneCtrl.text,
      campus: campus,
      showBadge: showBadge,
      pushNotification: pushNotification,
    );
    ref.read(authStateProvider.notifier).update(newUser);
    Navigator.pop(context);
  }

  // 顶部导航栏
  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        "取消",
        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      ),
    ),
    title: const Text("编辑资料", style: TextStyle(color: Colors.black87)),
    actions: [
      TextButton(
        onPressed: _save,
        child: const Text(
          "保存",
          style: TextStyle(
            color: Color.fromARGB(255, 43, 184, 223),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
    centerTitle: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EF),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // 头像和上传按钮（未实现上传）
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: user.avatar != null
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user.avatar == null
                          ? const Icon(
                              Icons.person,
                              size: 54,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: Colors.grey[400],
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          /* TODO: 换头像 */
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text("点击更换头像", style: TextStyle(color: Colors.black45)),

              const SizedBox(height: 16),
              // 基本信息卡片
              _FieldCard(
                title: "基本信息",
                children: [
                  _TextEditField(label: "昵称", controller: _nicknameCtrl),
                  _ArrowField(
                    label: "所属校区",
                    value: user.campus ?? "未设置",
                    onTap: _pickCampus,
                  ),
                ],
              ),
              // 身份认证卡片
              _FieldCard(
                title: "身份认证",
                children: [
                  _StaticField(label: "学号/工号", value: user.studentId ?? ""),
                  _StaticField(label: "真实姓名", value: user.realName ?? ""),
                ],
              ),
              // 联系方式卡片
              _FieldCard(
                title: "联系方式（仅管理员可见）",
                children: [
                  _TextEditField(label: "微信号", controller: _wechatCtrl),
                  _TextEditField(
                    label: "手机号",
                    controller: _phoneCtrl,
                    hint: "选填",
                  ),
                ],
              ),
              // 偏好设置卡片
              _FieldCard(
                noTitle: true,
                children: [
                  _SwitchField(
                    label: "主页展示勋章",
                    value: showBadge,
                    onChanged: (v) => setState(() => showBadge = v),
                  ),
                  _SwitchField(
                    label: "接收投喂通知",
                    value: pushNotification,
                    onChanged: (v) => setState(() => pushNotification = v),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// 卡片包装
class _FieldCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final bool noTitle;
  const _FieldCard({this.title, required this.children, this.noTitle = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!noTitle && title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 12),
              child: Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          Container(
            width: double.infinity,
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// 可编辑文本输入字段
class _TextEditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  const _TextEditField({
    required this.label,
    required this.controller,
    this.hint,
  });
  @override
  Widget build(BuildContext context) {
    return _RowDecorator(
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          SizedBox(
            width: 180,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 右侧箭头字段
class _ArrowField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ArrowField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _RowDecorator(
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

// 静态显示字段（不可编辑）
class _StaticField extends StatelessWidget {
  final String label;
  final String value;
  const _StaticField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return _RowDecorator(
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
        ],
      ),
    );
  }
}

// 开关
class _SwitchField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return _RowDecorator(
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Switch(
            value: value,
            activeColor: Color.fromARGB(255, 213, 174, 18),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// 行装饰（分隔线   padding）
class _RowDecorator extends StatelessWidget {
  final Widget child;
  const _RowDecorator({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1), width: 1)),
      ),
      child: child,
    );
  }
}
