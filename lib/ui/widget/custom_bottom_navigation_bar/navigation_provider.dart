import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class Navigation extends _$Navigation {
  @override
  NavigationState build() {
    return NavigationState();
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
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
