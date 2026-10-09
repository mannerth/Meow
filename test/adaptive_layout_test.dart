import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meow/router/app_routes.dart';
import 'package:meow/ui/page/main_page.dart';
import 'package:meow/ui/widget/adaptive/adaptive_scaffold.dart';
import 'package:meow/ui/widget/adaptive/cat_grid_sliver.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_config.dart';
import 'package:meow/ui/widget/custom_bottom_navigation_bar/navigation_items_provider.dart';

void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
  }

  testWidgets('窗口切换导航方式后保留页面输入和当前选中项', (tester) async {
    addTearDown(tester.view.reset);
    setWindow(tester, const Size(390, 844));
    final configs = NavigationConfigRegistry.allConfigs;
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainPage(navigationShell: shell),
          branches: [
            for (final config in configs)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: config.routePath,
                    builder: (_, _) => config.routePath == AppRoutes.profile
                        ? const AdaptiveScaffold(
                            body: TextField(key: ValueKey('draft')),
                          )
                        : const AdaptiveScaffold(
                            body: Center(child: Text('首页内容')),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navigationItemsProvider.overrideWith(_TestNavigationItems.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    final bar = tester.widget<CustomBottomNavigationBar>(
      find.byType(CustomBottomNavigationBar),
    );
    bar.onIndexChanged!(1);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('draft')), '保留的草稿');
    FocusManager.instance.primaryFocus?.unfocus();

    for (final size in [const Size(800, 1280), const Size(1280, 800)]) {
      setWindow(tester, size);
      await tester.pumpAndSettle();
      expect(find.byType(CustomBottomNavigationBar), findsNothing);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
      expect(find.text('保留的草稿'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('首页内容').hitTestable(), findsOneWidget);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    setWindow(tester, const Size(390, 844));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('保留的草稿'), findsOneWidget);
    expect(
      tester
          .widget<CustomBottomNavigationBar>(
            find.byType(CustomBottomNavigationBar),
          )
          .currentIndex,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('表单保持居中限宽，键盘出现后仍可滚动到底部', (tester) async {
    addTearDown(tester.view.reset);
    setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          maxContentWidth: 480,
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const TextField(key: ValueKey('input')),
              const SizedBox(height: 800),
              FilledButton(onPressed: () {}, child: const Text('提交')),
            ],
          ),
        ),
      ),
    );
    final input = find.byKey(const ValueKey('input'));
    expect(tester.getSize(input).width, 432);
    expect(tester.getCenter(input).dx, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('提交'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('提交').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('猫咪列表按实际内容宽度排列，手机两列平板三至四列', (tester) async {
    addTearDown(tester.view.reset);
    for (final (width, columns) in [(390.0, 2), (760.0, 3), (1200.0, 4)]) {
      setWindow(tester, Size(width, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            maxContentWidth: 1200,
            body: CustomScrollView(
              slivers: [
                CatGridSliver(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ColoredBox(
                      key: ValueKey('cat_$index'),
                      color: Colors.orange,
                      child: Text('猫咪 $index'),
                    ),
                    childCount: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester.getRect(find.byKey(const ValueKey('cat_0')));
      final lastInRow = tester.getRect(
        find.byKey(ValueKey('cat_${columns - 1}')),
      );
      final nextRow = tester.getRect(find.byKey(ValueKey('cat_$columns')));
      expect(lastInRow.top, first.top);
      expect(nextRow.top, greaterThan(first.bottom));
      expect(lastInRow.right, lessThanOrEqualTo(width + 0.001));
      expect(tester.takeException(), isNull);
    }
  });
}

class _TestNavigationItems extends NavigationItems {
  @override
  List<NavigationItemConfig> build() => NavigationConfigRegistry.allConfigs
      .where(
        (config) =>
            [AppRoutes.home, AppRoutes.profile].contains(config.routePath),
      )
      .toList();
}
