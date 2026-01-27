// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserState)
final userStateProvider = UserStateProvider._();

final class UserStateProvider extends $NotifierProvider<UserState, User> {
  UserStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStateHash();

  @$internal
  @override
  UserState create() => UserState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User>(value),
    );
  }
}

String _$userStateHash() => r'ff297ec8c8f6bceec0c3463bae08b3db4eccafd5';

abstract class _$UserState extends $Notifier<User> {
  User build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<User, User>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<User, User>,
              User,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
