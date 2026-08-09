// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 登录状态provider

@ProviderFor(AuthState)
final authStateProvider = AuthStateProvider._();

/// 登录状态provider
final class AuthStateProvider extends $NotifierProvider<AuthState, Auth> {
  /// 登录状态provider
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  AuthState create() => AuthState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Auth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Auth>(value),
    );
  }
}

String _$authStateHash() => r'187381c5baf02c07e528d4013ab67cf2e0011028';

/// 登录状态provider

abstract class _$AuthState extends $Notifier<Auth> {
  Auth build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Auth, Auth>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Auth, Auth>,
              Auth,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
