import 'package:flutter/material.dart';

/// 页面保活容器
///
/// 用于 `PageView` 中，使页面在切出屏幕后仍保留 State，
/// 避免每次切换回来都重新 initState / 重新加载数据。
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
