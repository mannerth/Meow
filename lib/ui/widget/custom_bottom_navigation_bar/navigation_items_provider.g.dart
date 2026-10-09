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

String _$navigationItemsHash() => r'82820dc1663bd486dd70b2730f17943e802e88fc';

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
