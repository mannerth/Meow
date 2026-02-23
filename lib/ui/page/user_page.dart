import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/provider/auth_provider.dart';

/// 用户个人页面
class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(ref.watch(authStateProvider).user?.toJson().toString()?? '未登录'),
    );
  }
}