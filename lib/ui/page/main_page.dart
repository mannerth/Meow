import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_items_provider.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_provider.dart';

// 使用RiverPod的ConsumerStatefulWidget，可以使用ref来监听和读取Provider
// 同时也有StatefulWidget的setState功能
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  /// PageView 控制器
  /// 用于切换当前显示页面
  late PageController _pageController;

  // App生命周期监听
  late AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initLifecycleListener();
    debugPrint('MainPage initialized');
    daliyCheckIn();
  }

  void _initLifecycleListener() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // 应用恢复，处理应用在后台到达新的一天时执行签到
        daliyCheckIn();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleListener);
  }

  void daliyCheckIn() async{
    bool checkedIn = await AuthRepository.dailyCheckIn();
    if(checkedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签到成功！')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('今日已签到过了哦~')));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationProvider);
    // 监听导航项配置变化（用户角色变化时自动更新）
    final navigationItemsData = ref.watch(navigationItemsDataProvider);
    final pages = ref.watch(navigationPagesProvider);

    // 当导航项数量变化时，确保 currentIndex 有效
    final itemCount = navigationItemsData.length;
    final currentIndex = navigationState.currentIndex.clamp(0, itemCount - 1);

    // 如果索引被修正，同步更新 provider
    if (currentIndex != navigationState.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setCurrentIndex(currentIndex);
      });
    }

    return Scaffold(
      // 延申页面主体，为了适应自定义悬浮导航栏
      extendBody: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              // 同步 PageView 滑动与导航栏状态
              ref.read(navigationProvider.notifier).setCurrentIndex(index);
            },
            itemBuilder: (context, index) {
              return pages[index];
            },
          ),
          // 自定义悬浮导航栏
          Positioned(
            right: 24,
            left: 24,
            bottom: 48,
            child: Center(
              child: CustomBottomNavigationBar(
                currentIndex: currentIndex,
                items: navigationItemsData,
                onIndexChanged: (index) {
                  ref.read(navigationProvider.notifier).setCurrentIndex(index);
                  final pageIndex = _pageController.page?.round() ?? 0;
                  // 相邻页使用动画切换，非相邻页直接跳转避免卡顿
                  if ((index - pageIndex).abs() <= 1) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    _pageController.jumpToPage(index);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
