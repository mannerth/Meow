import 'package:flutter/material.dart';

/// 自定义导航项数据模型
class CustomNavigationItemData {
  final String label;
  final Widget icon;
  final Widget? activeIcon;
  final Color? activeBackgroundColor;

  const CustomNavigationItemData({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.activeBackgroundColor,
  });
}

/// 自定义导航项组件
/// 未选中：只展示图标，无背景
/// 选中：展示图标和文字，横向排列，有背景颜色
class CustomNavigationItem extends StatelessWidget {
  final CustomNavigationItemData data;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;
  final Duration animationDuration;

  const CustomNavigationItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final activeIcon = data.activeIcon ?? data.icon;
    final backgroundColor =
        data.activeBackgroundColor ??
        Theme.of(context).primaryColor.withValues(alpha: 0.15);
    final icon = AnimatedSwitcher(
      duration: animationDuration,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: IconTheme(
        key: ValueKey(isSelected),
        data: IconThemeData(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
          size: compact ? 22 : 24,
        ),
        child: isSelected ? activeIcon : data.icon,
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: data.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          padding: compact
              ? const EdgeInsets.symmetric(vertical: 5)
              : EdgeInsets.symmetric(
                  horizontal: isSelected ? 16.0 : 12.0,
                  vertical: 10.0,
                ),
          decoration: BoxDecoration(
            color: isSelected ? backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 16.0 : 24.0),
          ),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    AnimatedSize(
                      duration: animationDuration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: isSelected ? 1.0 : 0.0,
                        child: isSelected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  data.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
