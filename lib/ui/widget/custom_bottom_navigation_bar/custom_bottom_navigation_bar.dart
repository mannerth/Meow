import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_navigation_item.dart';

/// 自定义底部导航栏
/// 毛玻璃效果背景，支持动画切换
class CustomBottomNavigationBar extends StatelessWidget {
  /// 导航项数据列表
  final List<CustomNavigationItemData> items;

  /// 当前选中索引
  final int currentIndex;

  /// 索引改变回调
  final ValueChanged<int>? onIndexChanged;

  /// 动画持续时间
  final Duration animationDuration;

  const CustomBottomNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onIndexChanged,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect( // 圆角裁剪
      borderRadius: BorderRadius.circular(42.0),
      child: BackdropFilter(  // 模糊其背景
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            // 半透明白色背景，配合模糊效果形成毛玻璃
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(42.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 4),
                blurRadius: 12.0,
                spreadRadius: 2.0,
              ),
            ],
            border: Border.all(
              // 细微的白色边框增强玻璃质感
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            //mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              return CustomNavigationItem(
                data: items[index],
                isSelected: currentIndex == index,
                animationDuration: animationDuration,
                onTap: () {
                  if (onIndexChanged != null && currentIndex != index) {
                    onIndexChanged!(index);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
