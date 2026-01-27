import 'package:flutter/material.dart';

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
      child: Text('Share Page'),
    );
  }
}