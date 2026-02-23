import 'package:flutter/material.dart';
import 'package:meow/api/service/auth_repository.dart';

/// 发布动态页面
class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () {
              AuthRepository.getMe();
            },
            child: Text('测试')),
      ],
    ));
  }
}
