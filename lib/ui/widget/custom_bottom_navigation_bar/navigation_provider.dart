import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class Navigation extends _$Navigation {
  /// 主页面初始化传递此变量，以后可以在任意位置用 [setCurrentIndex(idx, controlJump: true)] 来切换页面
  PageController? pageController;

  @override
  NavigationState build() {
    return NavigationState();
  }

  void setController(PageController controller) {
    pageController = controller;
  }

  void setCurrentIndex(int index, {bool controlJump = false}) {
    state = state.copyWith(currentIndex: index);
    if( controlJump && pageController != null ){
      pageController!.jumpToPage(index);
    }
  }

  void setVisibility(bool isVisible) {
    state = state.copyWith(isVisible: isVisible);
  }
}

class NavigationState {
  final int currentIndex;
  final bool isVisible;

  NavigationState({
    this.currentIndex = 0,
    this.isVisible = true,
  });

  NavigationState copyWith({
    int? currentIndex,
    bool? isVisible,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
