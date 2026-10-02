import 'package:flutter/material.dart';

/// 大屏上居中显示内容；使用窗口可用宽度，兼容横竖屏和分屏。
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.backgroundColor,
    this.body,
    this.floatingActionButton,
    this.maxContentWidth = 760,
  });

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? body;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: body == null
          ? null
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SizedBox.expand(child: body),
              ),
            ),
    );
  }
}
