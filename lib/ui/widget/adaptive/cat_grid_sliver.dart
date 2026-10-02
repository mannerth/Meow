import 'package:flutter/material.dart';

/// 保持手机两列，在平板上按内容区域宽度增加列数。
class CatGridSliver extends StatelessWidget {
  const CatGridSliver({super.key, required this.delegate});

  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid(
        delegate: delegate,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (constraints.crossAxisExtent / 220).floor().clamp(
            2,
            4,
          ),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
      ),
    );
  }
}
