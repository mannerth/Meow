// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 导航项配置 Provider
/// 根据用户角色自动计算可见的导航项

@ProviderFor(NavigationItems)
final navigationItemsProvider = NavigationItemsProvider._();

/// 导航项配置 Provider
/// 根据用户角色自动计算可见的导航项
final class NavigationItemsProvider
    extends $NotifierProvider<NavigationItems, List<NavigationItemConfig>> {
  /// 导航项配置 Provider
  /// 根据用户角色自动计算可见的导航项
  NavigationItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationItemsHash();

  @$internal
  @override
  NavigationItems create() => NavigationItems();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<NavigationItemConfig> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<NavigationItemConfig>>(value),
    );
  }
}

String _$navigationItemsHash() => r'03874934974b5c100614799f291fa6697722d725';

/// 导航项配置 Provider
/// 根据用户角色自动计算可见的导航项

abstract class _$NavigationItems extends $Notifier<List<NavigationItemConfig>> {
  List<NavigationItemConfig> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<List<NavigationItemConfig>, List<NavigationItemConfig>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<NavigationItemConfig>,
                List<NavigationItemConfig>
              >,
              List<NavigationItemConfig>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 导航项数据列表 Provider（仅数据，不含页面）

@ProviderFor(navigationItemsData)
final navigationItemsDataProvider = NavigationItemsDataProvider._();

/// 导航项数据列表 Provider（仅数据，不含页面）

final class NavigationItemsDataProvider
    extends
        $FunctionalProvider<
          List<CustomNavigationItemData>,
          List<CustomNavigationItemData>,
          List<CustomNavigationItemData>
        >
    with $Provider<List<CustomNavigationItemData>> {
  /// 导航项数据列表 Provider（仅数据，不含页面）
  NavigationItemsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationItemsDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationItemsDataHash();

  @$internal
  @override
  $ProviderElement<List<CustomNavigationItemData>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CustomNavigationItemData> create(Ref ref) {
    return navigationItemsData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CustomNavigationItemData> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CustomNavigationItemData>>(
        value,
      ),
    );
  }
}

String _$navigationItemsDataHash() =>
    r'72b5ac38ce7e0a8179e1263591635ab548758d1c';

/// 导航页面列表 Provider

@ProviderFor(navigationPages)
final navigationPagesProvider = NavigationPagesProvider._();

/// 导航页面列表 Provider

final class NavigationPagesProvider
    extends $FunctionalProvider<List<Widget>, List<Widget>, List<Widget>>
    with $Provider<List<Widget>> {
  /// 导航页面列表 Provider
  NavigationPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationPagesHash();

  @$internal
  @override
  $ProviderElement<List<Widget>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Widget> create(Ref ref) {
    return navigationPages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Widget> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Widget>>(value),
    );
  }
}

String _$navigationPagesHash() => r'e1b2fa3b507367c7e8760c4b234e82db281062ed';
