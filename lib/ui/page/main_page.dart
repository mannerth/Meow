import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_config.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_items_provider.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late final AppLifecycleListener _lifecycleListener;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _dailyCheckIn);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dailyCheckIn();
    });
  }

  Future<void> _dailyCheckIn() async {
    final auth = ref.read(authStateProvider);
    if (!auth.loggedIn || _checkingIn) return;
    _checkingIn = true;
    try {
      final checkedIn = await AuthRepository.dailyCheckIn();
      if (checkedIn &&
          mounted &&
          ref.read(authStateProvider).user?.id == auth.user?.id) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('今日签到成功！')));
      }
    } catch (_) {
      // 签到失败不阻断页面导航，下次恢复前台时可重试。
    } finally {
      _checkingIn = false;
    }
  }

  void _changePage(int index, List<NavigationItemConfig> configs) {
    FocusManager.instance.primaryFocus?.unfocus();
    final path = configs[index].routePath;
    final branch = NavigationConfigRegistry.allConfigs.indexWhere(
      (config) => config.routePath == path,
    );
    widget.navigationShell.goBranch(branch);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(navigationItemsProvider);
    final allConfigs = NavigationConfigRegistry.allConfigs;
    final path = allConfigs[widget.navigationShell.currentIndex].routePath;
    final currentIndex = configs.indexWhere(
      (config) => config.routePath == path,
    );
    final selectedIndex = currentIndex < 0 ? 0 : currentIndex;
    final items = configs.map((config) => config.itemData).toList();
    ref.listen(authStateProvider, (previous, next) {
      if (next.loggedIn && previous?.user?.id != next.user?.id) _dailyCheckIn();
    });

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useRail =
              constraints.maxWidth >= 600 && constraints.maxHeight >= 480;
          return Row(
            children: [
              if (useRail)
                SafeArea(
                  key: const ValueKey('navigation_rail'),
                  child: NavigationRail(
                    scrollable: true,
                    selectedIndex: selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -1,
                    onDestinationSelected: (index) =>
                        _changePage(index, configs),
                    destinations: [
                      for (final item in items)
                        NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.activeIcon,
                          label: Text(item.label),
                        ),
                    ],
                  ),
                ),
              if (useRail) const VerticalDivider(width: 1),
              Expanded(
                key: const ValueKey('main_content'),
                child: Stack(
                  children: [
                    widget.navigationShell,
                    if (!useRail)
                      Positioned(
                        right: 24,
                        left: 24,
                        bottom: 48,
                        child: Center(
                          child: CustomBottomNavigationBar(
                            currentIndex: selectedIndex,
                            items: items,
                            onIndexChanged: (index) =>
                                _changePage(index, configs),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
