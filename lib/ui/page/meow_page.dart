import 'package:flutter/material.dart';

class MeowPage extends StatefulWidget {
  const MeowPage({super.key});

  @override
  State<MeowPage> createState() => _MeowPageState();
}

class _MeowPageState extends State<MeowPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('猫咪管理页'),
    );
  }
}
